import Foundation

/// The result of validating a single `.feature` file.
public struct BatchValidationResult: Sendable {
    /// The file path that was validated.
    public let path: String

    /// The parsed feature title, if parsing succeeded.
    public let featureTitle: String?

    /// The validation errors found (empty if valid).
    public let errors: [GherkinError]

    /// Whether the file parsed and validated successfully.
    public var isSuccess: Bool { errors.isEmpty && featureTitle != nil }

    /// Creates a validation result.
    ///
    /// - Parameters:
    ///   - path: The file path.
    ///   - featureTitle: The parsed feature title, or `nil` if parsing failed.
    ///   - errors: The errors found during parsing or validation.
    public init(path: String, featureTitle: String?, errors: [GherkinError]) {
        self.path = path
        self.featureTitle = featureTitle
        self.errors = errors
    }
}

/// An actor for batch-validating `.feature` files from a directory.
///
/// `BatchValidator` scans a directory for `.feature` files, parses and
/// validates each one in parallel using structured concurrency, and
/// returns detailed results per file.
///
/// ```swift
/// let validator = BatchValidator()
/// let results = try await validator.validateDirectory(at: "features/")
/// for result in results {
///     if result.isSuccess {
///         print("✓ \(result.featureTitle ?? result.path)")
///     } else {
///         print("✗ \(result.path): \(result.errors)")
///     }
/// }
/// ```
public actor BatchValidator {
    private let parser: GherkinParser
    private let validator: GherkinValidator

    /// Creates a batch validator.
    ///
    /// - Parameters:
    ///   - parser: The parser to use. Defaults to a default parser.
    ///   - validator: The validator to use. Defaults to a default validator.
    public init(
        parser: GherkinParser = GherkinParser(),
        validator: GherkinValidator = GherkinValidator()
    ) {
        self.parser = parser
        self.validator = validator
    }

    /// Validates all `.feature` files in a directory.
    ///
    /// Files are parsed and validated in parallel using `TaskGroup`.
    /// A failure in one file does not prevent other files from being processed.
    ///
    /// - Parameters:
    ///   - path: The directory path.
    ///   - recursive: Whether to scan subdirectories. Defaults to `false`.
    /// - Returns: An array of validation results, one per file found.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if the directory cannot be read.
    public func validateDirectory(
        at path: String,
        recursive: Bool = false
    ) async throws -> [BatchValidationResult] {
        let files = try listFeatureFiles(at: path, recursive: recursive)
        let parser = self.parser
        let validator = self.validator

        return await withTaskGroup(
            of: (Int, BatchValidationResult).self,
            returning: [BatchValidationResult].self
        ) { group in
            for (index, filePath) in files.enumerated() {
                group.addTask {
                    let result = Self.validateFile(
                        at: filePath, parser: parser, validator: validator
                    )
                    return (index, result)
                }
            }

            var indexed: [(Int, BatchValidationResult)] = []
            indexed.reserveCapacity(files.count)
            for await pair in group {
                indexed.append(pair)
            }

            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    /// Returns an `AsyncStream` of validation results from a directory.
    ///
    /// Results are yielded as files are parsed and validated, enabling
    /// progressive reporting for large directories.
    ///
    /// - Parameters:
    ///   - path: The directory path.
    ///   - recursive: Whether to scan subdirectories. Defaults to `false`.
    /// - Returns: An async stream of validation results.
    public func streamValidation(
        at path: String,
        recursive: Bool = false
    ) -> AsyncStream<BatchValidationResult> {
        let files: [String]
        do {
            files = try listFeatureFiles(at: path, recursive: recursive)
        } catch {
            return AsyncStream { continuation in
                let errorMessage: String
                if let gherkinError = error as? GherkinError {
                    errorMessage = gherkinError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                continuation.yield(
                    BatchValidationResult(
                        path: path,
                        featureTitle: nil,
                        errors: [.importFailed(path: path, reason: errorMessage)]
                    )
                )
                continuation.finish()
            }
        }

        let parser = self.parser
        let validator = self.validator
        return AsyncStream { continuation in
            let filesCopy = files
            Task {
                await withTaskGroup(of: BatchValidationResult.self) { group in
                    for filePath in filesCopy {
                        group.addTask {
                            Self.validateFile(
                                at: filePath, parser: parser, validator: validator
                            )
                        }
                    }

                    for await result in group {
                        continuation.yield(result)
                    }
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Private Helpers

    /// Lists `.feature` files in a directory.
    private func listFeatureFiles(
        at path: String,
        recursive: Bool
    ) throws -> [String] {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            throw GherkinError.importFailed(
                path: path, reason: "Path is not a directory"
            )
        }

        let contents: [String]
        if recursive {
            guard let enumerator = fileManager.enumerator(atPath: path) else {
                throw GherkinError.importFailed(
                    path: path, reason: "Cannot enumerate directory"
                )
            }
            contents = enumerator.compactMap { $0 as? String }
        } else {
            do {
                contents = try fileManager.contentsOfDirectory(atPath: path)
            } catch {
                throw GherkinError.importFailed(
                    path: path, reason: error.localizedDescription
                )
            }
        }

        return
            contents
            .filter { $0.hasSuffix(".feature") }
            .sorted()
            .map { (path as NSString).appendingPathComponent($0) }
    }

    /// Parses and validates a single file.
    private static func validateFile(
        at filePath: String,
        parser: GherkinParser,
        validator: GherkinValidator
    ) -> BatchValidationResult {
        let feature: Feature
        do {
            feature = try parser.parse(contentsOfFile: filePath)
        } catch let error as GherkinError {
            return BatchValidationResult(
                path: filePath, featureTitle: nil, errors: [error]
            )
        } catch {
            return BatchValidationResult(
                path: filePath,
                featureTitle: nil,
                errors: [.importFailed(path: filePath, reason: error.localizedDescription)]
            )
        }

        let validationErrors = validator.collectErrors(in: feature)
        return BatchValidationResult(
            path: filePath, featureTitle: feature.title, errors: validationErrors
        )
    }
}
