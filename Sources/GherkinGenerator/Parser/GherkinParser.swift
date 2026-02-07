import Foundation

/// A stateless parser that reads Gherkin content into model objects.
///
/// `GherkinParser` uses a recursive descent approach to parse `.feature`
/// files, strings, and other input formats into ``Feature`` values.
///
/// ```swift
/// let parser = GherkinParser()
/// let feature = try parser.parse(contentsOfFile: "login.feature")
/// ```
///
/// The parser automatically detects the language from the `# language:` header
/// or falls back to English.
public struct GherkinParser: Sendable {

    /// Creates a new parser.
    public init() {}

    /// Parses a Gherkin string into a ``Feature``.
    ///
    /// - Parameter source: The Gherkin source string.
    /// - Returns: The parsed feature.
    /// - Throws: ``GherkinError/syntaxError(message:line:)`` on parse errors.
    public func parse(_ source: String) throws -> Feature {
        // TODO: Implement recursive descent parser
        throw GherkinError.syntaxError(message: "Parser not yet implemented", line: 1)
    }

    /// Parses a `.feature` file into a ``Feature``.
    ///
    /// - Parameter path: The path to the `.feature` file.
    /// - Returns: The parsed feature.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if the file cannot be read,
    ///   or ``GherkinError/syntaxError(message:line:)`` on parse errors.
    public func parse(contentsOfFile path: String) throws -> Feature {
        let content: String
        do {
            content = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw GherkinError.importFailed(path: path, reason: error.localizedDescription)
        }
        return try parse(content)
    }

    /// Detects the language from a Gherkin source string.
    ///
    /// Looks for a `# language: xx` header in the first few lines.
    ///
    /// - Parameter source: The Gherkin source string.
    /// - Returns: The detected language, or ``GherkinLanguage/english`` if none found.
    public func detectLanguage(in source: String) -> GherkinLanguage {
        // TODO: Implement language detection
        .english
    }
}

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
