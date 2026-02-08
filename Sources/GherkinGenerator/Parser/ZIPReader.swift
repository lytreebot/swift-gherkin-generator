import CZlib
import Foundation

/// Errors that can occur when reading a ZIP archive.
enum ZIPError: Error, Sendable {
    /// The data is not a valid ZIP archive.
    case invalidArchive(String)

    /// The requested file was not found in the archive.
    case fileNotFound(String)

    /// Decompression of a deflated entry failed.
    case decompressionFailed(String)

    /// The compression method is not supported (only stored and deflate).
    case unsupportedCompression(method: UInt16)
}

/// A minimal, read-only ZIP reader that operates entirely on in-memory `Data`.
///
/// Supports two compression methods:
/// - Stored (method 0): uncompressed entries
/// - Deflate (method 8): decompressed via the system zlib
///
/// This reader does not support ZIP64, encryption, or multi-disk archives.
struct ZIPReader: Sendable {

    /// The filenames present in the archive, sorted alphabetically.
    let filenames: [String]

    private let data: Data
    private let entries: [String: CentralDirectoryEntry]

    /// Creates a ZIP reader from raw archive data.
    ///
    /// - Parameter data: The complete ZIP archive as `Data`.
    /// - Throws: ``ZIPError/invalidArchive(_:)`` if the data is not a valid ZIP archive.
    init(_ data: Data) throws {
        self.data = data
        let eocd = try Self.findEOCD(in: data)
        let parsedEntries = try Self.readCentralDirectory(in: data, eocd: eocd)
        self.entries = parsedEntries
        self.filenames = parsedEntries.keys.sorted()
    }

    /// Extracts a file from the archive by name.
    ///
    /// - Parameter filename: The exact filename as stored in the archive.
    /// - Returns: The decompressed file contents.
    /// - Throws: ``ZIPError/fileNotFound(_:)`` if the file does not exist,
    ///   or ``ZIPError/decompressionFailed(_:)`` if decompression fails.
    func extract(filename: String) throws -> Data {
        guard let entry = entries[filename] else {
            throw ZIPError.fileNotFound(filename)
        }
        return try Self.extractEntry(entry, from: data)
    }

    // MARK: - End of Central Directory

    private struct EOCD {
        let centralDirectoryOffset: UInt32
        let centralDirectorySize: UInt32
        let totalEntries: UInt16
    }

    private static let eocdSignature: UInt32 = 0x0605_4b50
    private static let centralDirSignature: UInt32 = 0x0201_4b50
    private static let localFileSignature: UInt32 = 0x0403_4b50

    private static func findEOCD(in data: Data) throws -> EOCD {
        let minEOCDSize = 22
        guard data.count >= minEOCDSize else {
            throw ZIPError.invalidArchive("Data too small to be a ZIP archive")
        }

        let searchLimit = min(data.count, minEOCDSize + 65535)
        let lowerBound = max(data.count - searchLimit, 0)

        for offset in stride(from: data.count - minEOCDSize, through: lowerBound, by: -1)
        where data.readUInt32(at: offset) == eocdSignature {
            return EOCD(
                centralDirectoryOffset: data.readUInt32(at: offset + 16),
                centralDirectorySize: data.readUInt32(at: offset + 12),
                totalEntries: data.readUInt16(at: offset + 10)
            )
        }

        throw ZIPError.invalidArchive("End of Central Directory record not found")
    }

    // MARK: - Central Directory

    private struct CentralDirectoryEntry: Sendable {
        let compressionMethod: UInt16
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let localHeaderOffset: UInt32
    }

    private static func readCentralDirectory(
        in data: Data,
        eocd: EOCD
    ) throws -> [String: CentralDirectoryEntry] {
        var entries: [String: CentralDirectoryEntry] = [:]
        var offset = Int(eocd.centralDirectoryOffset)

        for _ in 0..<eocd.totalEntries {
            guard offset + 46 <= data.count else {
                throw ZIPError.invalidArchive("Central directory entry truncated")
            }
            guard data.readUInt32(at: offset) == centralDirSignature else {
                throw ZIPError.invalidArchive("Invalid central directory signature")
            }

            let compressionMethod = data.readUInt16(at: offset + 10)
            let compressedSize = data.readUInt32(at: offset + 20)
            let uncompressedSize = data.readUInt32(at: offset + 24)
            let filenameLength = Int(data.readUInt16(at: offset + 28))
            let extraLength = Int(data.readUInt16(at: offset + 30))
            let commentLength = Int(data.readUInt16(at: offset + 32))
            let localHeaderOffset = data.readUInt32(at: offset + 42)

            let nameStart = offset + 46
            guard nameStart + filenameLength <= data.count else {
                throw ZIPError.invalidArchive("Filename extends beyond data")
            }

            let nameData = data.subdata(in: nameStart..<nameStart + filenameLength)
            guard let filename = String(data: nameData, encoding: .utf8) else {
                throw ZIPError.invalidArchive("Invalid UTF-8 filename encoding")
            }

            entries[filename] = CentralDirectoryEntry(
                compressionMethod: compressionMethod,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                localHeaderOffset: localHeaderOffset
            )

            offset = nameStart + filenameLength + extraLength + commentLength
        }

        return entries
    }

    // MARK: - Extraction

    private static func extractEntry(
        _ entry: CentralDirectoryEntry,
        from data: Data
    ) throws -> Data {
        let localOffset = Int(entry.localHeaderOffset)
        guard localOffset + 30 <= data.count else {
            throw ZIPError.invalidArchive("Local file header truncated")
        }
        guard data.readUInt32(at: localOffset) == localFileSignature else {
            throw ZIPError.invalidArchive("Invalid local file header signature")
        }

        let filenameLength = Int(data.readUInt16(at: localOffset + 26))
        let extraLength = Int(data.readUInt16(at: localOffset + 28))
        let dataStart = localOffset + 30 + filenameLength + extraLength
        let compressedSize = Int(entry.compressedSize)

        guard dataStart + compressedSize <= data.count else {
            throw ZIPError.invalidArchive("Compressed data extends beyond archive")
        }

        let compressedData = data.subdata(in: dataStart..<dataStart + compressedSize)

        switch entry.compressionMethod {
        case 0:
            return compressedData
        case 8:
            return try inflateRawDeflate(compressedData, expectedSize: Int(entry.uncompressedSize))
        default:
            throw ZIPError.unsupportedCompression(method: entry.compressionMethod)
        }
    }

    /// Decompresses raw deflate data (RFC 1951) using the system zlib.
    private static func inflateRawDeflate(_ data: Data, expectedSize: Int) throws -> Data {
        guard expectedSize > 0 else { return Data() }

        var stream = z_stream()
        let initResult = inflateInit2_(
            &stream,
            -15,
            zlibVersion(),
            Int32(MemoryLayout<z_stream>.size)
        )
        guard initResult == Z_OK else {
            throw ZIPError.decompressionFailed("inflateInit2 failed with code \(initResult)")
        }
        defer { inflateEnd(&stream) }

        var output = Data(count: expectedSize)

        let result: Int32 = data.withUnsafeBytes { srcBuffer in
            output.withUnsafeMutableBytes { dstBuffer in
                guard let srcBase = srcBuffer.baseAddress,
                    let dstBase = dstBuffer.baseAddress
                else {
                    return Z_DATA_ERROR
                }
                stream.next_in = UnsafeMutablePointer(
                    mutating: srcBase.assumingMemoryBound(to: UInt8.self)
                )
                stream.avail_in = UInt32(data.count)
                stream.next_out = dstBase.assumingMemoryBound(to: UInt8.self)
                stream.avail_out = UInt32(expectedSize)
                return CZlib.inflate(&stream, Z_FINISH)
            }
        }

        guard result == Z_STREAM_END else {
            throw ZIPError.decompressionFailed("inflate failed with code \(result)")
        }

        return output
    }
}

// MARK: - Data Byte Reading

extension Data {
    /// Reads a little-endian `UInt16` at the given byte offset.
    func readUInt16(at offset: Int) -> UInt16 {
        UInt16(self[offset]) | UInt16(self[offset + 1]) << 8
    }

    /// Reads a little-endian `UInt32` at the given byte offset.
    func readUInt32(at offset: Int) -> UInt32 {
        UInt32(self[offset]) | UInt32(self[offset + 1]) << 8
            | UInt32(self[offset + 2]) << 16 | UInt32(self[offset + 3]) << 24
    }
}
