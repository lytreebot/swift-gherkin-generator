import Foundation

// MARK: - Batch Importer

/// An actor for batch-importing features from a directory.
///
/// `BatchImporter` scans a directory for `.feature` files and parses
/// them in parallel using structured concurrency.
///
/// ```swift
/// let importer = BatchImporter()
/// let results = try await importer.importDirectory(at: "features/")
/// for result in results {
///     switch result {
///     case .success(let feature):
///         print("Imported: \(feature.title)")
///     case .failure(let error):
///         print("Error: \(error)")
///     }
/// }
/// ```
public actor BatchImporter {
    private let parser: GherkinParser

    /// Creates a batch importer.
    ///
    /// - Parameter parser: The parser to use. Defaults to a default parser.
    public init(parser: GherkinParser = GherkinParser()) {
        self.parser = parser
    }

    /// Imports all `.feature` files from a directory.
    ///
    /// Files are parsed in parallel using `TaskGroup`.
    ///
    /// - Parameter path: The directory path.
    /// - Returns: An array of results, one per file.
    public func importDirectory(
        at path: String
    ) async throws -> [Result<Feature, GherkinError>] {
        // TODO: Implement batch import with TaskGroup
        []
    }

    /// Returns an `AsyncStream` of features parsed from a directory.
    ///
    /// Features are yielded as they are parsed, enabling progressive
    /// processing of large directories.
    ///
    /// - Parameter path: The directory path.
    /// - Returns: An async stream of parse results.
    public func streamDirectory(
        at path: String
    ) -> AsyncStream<Result<Feature, GherkinError>> {
        // TODO: Implement streaming import
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
