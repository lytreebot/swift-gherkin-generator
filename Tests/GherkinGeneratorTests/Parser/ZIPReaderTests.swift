import CZlib
import Foundation
import Testing

@testable import GherkinGenerator

@Suite("ZIPReader")
struct ZIPReaderTests {

    @Test("Read deflated entries from a valid ZIP")
    func readDeflatedEntries() throws {
        let original = Data("Hello, World! This is a test of deflate compression in ZIP files.".utf8)
        let deflated = try TestZIPBuilder.deflateRaw(original)
        let archive = TestZIPBuilder.createDeflatedZIP(
            entries: [
                TestZIPBuilder.DeflatedEntry(
                    name: "compressed.txt",
                    compressedData: deflated,
                    uncompressedSize: UInt32(original.count)
                )
            ]
        )
        let reader = try ZIPReader(archive)

        #expect(reader.filenames == ["compressed.txt"])
        let extracted = try reader.extract(filename: "compressed.txt")
        #expect(extracted == original)
    }

    @Test("Read stored entries from a valid ZIP")
    func readStoredEntries() throws {
        let entries: [(String, Data)] = [
            ("hello.txt", Data("Hello, World!".utf8)),
            ("empty.txt", Data()),
            ("subdir/file.txt", Data("nested content".utf8))
        ]
        let archive = TestZIPBuilder.createZIP(entries: entries)
        let reader = try ZIPReader(archive)

        #expect(reader.filenames.count == 3)
        #expect(reader.filenames.contains("hello.txt"))
        #expect(reader.filenames.contains("empty.txt"))
        #expect(reader.filenames.contains("subdir/file.txt"))

        let hello = try reader.extract(filename: "hello.txt")
        #expect(String(data: hello, encoding: .utf8) == "Hello, World!")

        let empty = try reader.extract(filename: "empty.txt")
        #expect(empty.isEmpty)

        let nested = try reader.extract(filename: "subdir/file.txt")
        #expect(String(data: nested, encoding: .utf8) == "nested content")
    }

    @Test("File not found throws error")
    func fileNotFound() throws {
        let archive = TestZIPBuilder.createZIP(
            entries: [("a.txt", Data("a".utf8))]
        )
        let reader = try ZIPReader(archive)

        #expect(throws: ZIPError.self) {
            try reader.extract(filename: "missing.txt")
        }
    }

    @Test("Invalid data throws error")
    func invalidData() {
        #expect(throws: ZIPError.self) {
            _ = try ZIPReader(Data([0, 1, 2, 3]))
        }
    }

    @Test("Empty data throws error")
    func emptyData() {
        #expect(throws: ZIPError.self) {
            _ = try ZIPReader(Data())
        }
    }

    @Test("Filenames are sorted alphabetically")
    func sortedFilenames() throws {
        let entries: [(String, Data)] = [
            ("c.txt", Data("c".utf8)),
            ("a.txt", Data("a".utf8)),
            ("b.txt", Data("b".utf8))
        ]
        let archive = TestZIPBuilder.createZIP(entries: entries)
        let reader = try ZIPReader(archive)

        #expect(reader.filenames == ["a.txt", "b.txt", "c.txt"])
    }

    @Test("Unicode filenames are supported")
    func unicodeFilenames() throws {
        let entries: [(String, Data)] = [
            ("données/résumé.txt", Data("contenu".utf8))
        ]
        let archive = TestZIPBuilder.createZIP(entries: entries)
        let reader = try ZIPReader(archive)

        #expect(reader.filenames.contains("données/résumé.txt"))
        let content = try reader.extract(filename: "données/résumé.txt")
        #expect(String(data: content, encoding: .utf8) == "contenu")
    }
}

// MARK: - Test ZIP Builder

/// Builds minimal ZIP archives with stored (uncompressed) entries for testing.
enum TestZIPBuilder {

    static func createZIP(entries: [(String, Data)]) -> Data {
        var archive = Data()
        var centralDirectory = Data()
        var localOffsets: [Int] = []

        for (name, content) in entries {
            localOffsets.append(archive.count)
            let nameData = Data(name.utf8)
            let crc = Self.crc32(content)

            // Local file header
            archive.appendUInt32(0x0403_4b50)
            archive.appendUInt16(20)
            archive.appendUInt16(0)
            archive.appendUInt16(0)
            archive.appendUInt16(0)
            archive.appendUInt16(0)
            archive.appendUInt32(crc)
            archive.appendUInt32(UInt32(content.count))
            archive.appendUInt32(UInt32(content.count))
            archive.appendUInt16(UInt16(nameData.count))
            archive.appendUInt16(0)
            archive.append(nameData)
            archive.append(content)

            // Central directory entry
            centralDirectory.appendUInt32(0x0201_4b50)
            centralDirectory.appendUInt16(20)
            centralDirectory.appendUInt16(20)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt32(crc)
            centralDirectory.appendUInt32(UInt32(content.count))
            centralDirectory.appendUInt32(UInt32(content.count))
            centralDirectory.appendUInt16(UInt16(nameData.count))
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt32(0)
            centralDirectory.appendUInt32(UInt32(localOffsets.last ?? 0))
            centralDirectory.append(nameData)
        }

        let cdOffset = UInt32(archive.count)
        archive.append(centralDirectory)

        // End of Central Directory
        archive.appendUInt32(0x0605_4b50)
        archive.appendUInt16(0)
        archive.appendUInt16(0)
        archive.appendUInt16(UInt16(entries.count))
        archive.appendUInt16(UInt16(entries.count))
        archive.appendUInt32(UInt32(centralDirectory.count))
        archive.appendUInt32(cdOffset)
        archive.appendUInt16(0)

        return archive
    }

    struct DeflatedEntry {
        let name: String
        let compressedData: Data
        let uncompressedSize: UInt32
    }

    /// Creates a ZIP with deflated (method 8) entries.
    static func createDeflatedZIP(entries: [DeflatedEntry]) -> Data {
        var archive = Data()
        var centralDirectory = Data()
        var localOffsets: [Int] = []

        for entry in entries {
            let name = entry.name
            let compressedContent = entry.compressedData
            let uncompressedSize = entry.uncompressedSize
            localOffsets.append(archive.count)
            let nameData = Data(name.utf8)
            let crc = Self.crc32(Data(count: Int(uncompressedSize)))

            // Local file header
            archive.appendUInt32(0x0403_4b50)
            archive.appendUInt16(20)
            archive.appendUInt16(0)
            archive.appendUInt16(8)  // deflate
            archive.appendUInt16(0)
            archive.appendUInt16(0)
            archive.appendUInt32(crc)
            archive.appendUInt32(UInt32(compressedContent.count))
            archive.appendUInt32(uncompressedSize)
            archive.appendUInt16(UInt16(nameData.count))
            archive.appendUInt16(0)
            archive.append(nameData)
            archive.append(compressedContent)

            // Central directory entry
            centralDirectory.appendUInt32(0x0201_4b50)
            centralDirectory.appendUInt16(20)
            centralDirectory.appendUInt16(20)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(8)  // deflate
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt32(crc)
            centralDirectory.appendUInt32(UInt32(compressedContent.count))
            centralDirectory.appendUInt32(uncompressedSize)
            centralDirectory.appendUInt16(UInt16(nameData.count))
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt16(0)
            centralDirectory.appendUInt32(0)
            centralDirectory.appendUInt32(UInt32(localOffsets.last ?? 0))
            centralDirectory.append(nameData)
        }

        let cdOffset = UInt32(archive.count)
        archive.append(centralDirectory)

        archive.appendUInt32(0x0605_4b50)
        archive.appendUInt16(0)
        archive.appendUInt16(0)
        archive.appendUInt16(UInt16(entries.count))
        archive.appendUInt16(UInt16(entries.count))
        archive.appendUInt32(UInt32(centralDirectory.count))
        archive.appendUInt32(cdOffset)
        archive.appendUInt16(0)

        return archive
    }

    /// Compresses data using raw deflate (no zlib header).
    static func deflateRaw(_ data: Data) throws -> Data {
        let bufferSize = data.count + 128
        var output = Data(count: bufferSize)

        var stream = z_stream()
        let initResult = deflateInit2_(
            &stream,
            Z_DEFAULT_COMPRESSION,
            Z_DEFLATED,
            -15,  // raw deflate
            8,
            Z_DEFAULT_STRATEGY,
            zlibVersion(),
            Int32(MemoryLayout<z_stream>.size)
        )
        guard initResult == Z_OK else {
            throw ZIPError.decompressionFailed("deflateInit2 failed: \(initResult)")
        }
        defer { deflateEnd(&stream) }

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
                stream.avail_out = UInt32(bufferSize)
                return CZlib.deflate(&stream, Z_FINISH)
            }
        }

        guard result == Z_STREAM_END else {
            throw ZIPError.decompressionFailed("deflate failed: \(result)")
        }

        return output.prefix(Int(stream.total_out))
    }

    /// Computes CRC-32 for the given data.
    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc >> 1) ^ (crc & 1 == 1 ? 0xEDB8_8320 : 0)
            }
        }
        return ~crc
    }
}

// MARK: - Data Write Helpers

extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
    }

    mutating func appendUInt32(_ value: UInt32) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 24) & 0xFF))
    }
}
