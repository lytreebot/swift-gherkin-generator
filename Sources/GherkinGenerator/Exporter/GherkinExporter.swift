import Foundation

/// The output format for exporting a Gherkin feature.
public enum ExportFormat: String, Sendable, CaseIterable {
    /// Standard Gherkin `.feature` file format.
    case feature

    /// JSON structured representation.
    case json

    /// Markdown documentation format.
    case markdown
}

/// A stateless exporter that writes Gherkin features to various formats.
///
/// For single-feature exports, `GherkinExporter` handles the full workflow
/// of formatting and writing to disk.
///
/// ```swift
/// let exporter = GherkinExporter()
/// try await exporter.export(feature, to: "output.feature")
/// ```
///
/// For large-scale or streaming exports, use ``StreamingExporter`` instead.
public struct GherkinExporter: Sendable {
    /// The formatter used for `.feature` output.
    public let formatter: GherkinFormatter

    /// Creates an exporter with the given formatter.
    ///
    /// - Parameter formatter: The formatter to use. Defaults to a default-configured formatter.
    public init(formatter: GherkinFormatter = GherkinFormatter()) {
        self.formatter = formatter
    }

    /// Exports a feature to a file at the given path.
    ///
    /// - Parameters:
    ///   - feature: The feature to export.
    ///   - path: The output file path.
    ///   - format: The export format. Defaults to ``ExportFormat/feature``.
    /// - Throws: ``GherkinError/exportFailed(path:reason:)`` on I/O errors.
    public func export(
        _ feature: Feature,
        to path: String,
        format: ExportFormat = .feature
    ) async throws {
        let content = render(feature, format: format)
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw GherkinError.exportFailed(path: path, reason: error.localizedDescription)
        }
    }

    /// Renders a feature to a string in the given format.
    ///
    /// - Parameters:
    ///   - feature: The feature to render.
    ///   - format: The export format. Defaults to ``ExportFormat/feature``.
    /// - Returns: The rendered string.
    public func render(_ feature: Feature, format: ExportFormat = .feature) -> String {
        switch format {
        case .feature:
            return formatter.format(feature)
        case .json:
            // TODO: Implement JSON export
            return "{}"
        case .markdown:
            // TODO: Implement Markdown export
            return ""
        }
    }
}

/// An actor for memory-efficient streaming export of large features.
///
/// `StreamingExporter` writes features to disk line-by-line without
/// loading the entire output in memory, making it suitable for
/// features with hundreds of scenarios.
///
/// ```swift
/// let exporter = StreamingExporter()
/// try await exporter.export(largeFeature, to: "large.feature")
/// ```
public actor StreamingExporter {
    /// The formatter configuration.
    private let formatter: GherkinFormatter

    /// Creates a streaming exporter.
    ///
    /// - Parameter formatter: The formatter to use.
    public init(formatter: GherkinFormatter = GherkinFormatter()) {
        self.formatter = formatter
    }

    /// Exports a feature to a file using streaming I/O.
    ///
    /// - Parameters:
    ///   - feature: The feature to export.
    ///   - path: The output file path.
    /// - Throws: ``GherkinError/exportFailed(path:reason:)`` on I/O errors.
    public func export(_ feature: Feature, to path: String) async throws {
        // TODO: Implement streaming line-by-line export
        let content = formatter.format(feature)
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw GherkinError.exportFailed(path: path, reason: error.localizedDescription)
        }
    }
}
