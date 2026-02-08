import Foundation
import Testing

@testable import GherkinGenerator

@Suite("Fixture Export")
struct FixtureExportTests {

    private let parser = GherkinParser()
    private let exporter = GherkinExporter()

    // MARK: - Helpers

    private func parseFixture(_ name: String) throws -> Feature {
        guard let url = Bundle.module.url(forResource: name, withExtension: nil) else {
            throw GherkinError.importFailed(path: name, reason: "Fixture not found")
        }
        let source = try String(contentsOf: url, encoding: .utf8)
        return try parser.parse(source)
    }

    // MARK: - Feature Export

    @Test("Export simple.feature — contains all elements")
    func exportSimpleFeature() throws {
        let feature = try parseFixture("simple.feature")
        let output = exporter.formatter.format(feature)

        #expect(output.contains("User Authentication"))
        #expect(output.contains("Successful login"))
    }

    @Test("Export complex.feature — background preserved")
    func exportComplexBackground() throws {
        let feature = try parseFixture("complex.feature")
        let output = exporter.formatter.format(feature)

        #expect(output.contains("Background:"))
        #expect(output.contains("shopper@example.com"))
    }

    @Test("Export complex.feature — data table formatted")
    func exportComplexDataTable() throws {
        let feature = try parseFixture("complex.feature")
        let output = exporter.formatter.format(feature)

        #expect(output.contains("|"))
        #expect(output.contains("Wireless Headphones"))
    }

    @Test("Export complex.feature — doc string formatted")
    func exportComplexDocString() throws {
        let feature = try parseFixture("complex.feature")
        let output = exporter.formatter.format(feature)

        #expect(output.contains("\"\"\""))
        #expect(output.contains("application/json"))
    }

    // MARK: - JSON Export

    @Test("Export simple.feature to JSON — title and language")
    func exportSimpleJSON() throws {
        let feature = try parseFixture("simple.feature")
        let json = try exporter.render(feature, format: .json)

        #expect(json.contains("User Authentication"))
        #expect(json.contains("\"en\""))
    }

    @Test("Export complex.feature to JSON — contains all fields")
    func exportComplexJSON() throws {
        let feature = try parseFixture("complex.feature")
        let json = try exporter.render(feature, format: .json)

        #expect(json.contains("\"background\""))
        #expect(json.contains("\"tags\""))
        #expect(json.contains("\"children\""))
        #expect(json.contains("\"dataTable\""))
        #expect(json.contains("\"docString\""))
    }

    @Test("Export rules.feature to JSON — rules preserved")
    func exportRulesJSON() throws {
        let feature = try parseFixture("rules.feature")
        let json = try exporter.render(feature, format: .json)

        #expect(json.contains("\"rule\""))
        #expect(json.contains("Standard pricing"))
        #expect(json.contains("Volume discounts"))
        #expect(json.contains("Seasonal promotions"))
    }

    @Test("Export outline.feature to JSON — examples preserved")
    func exportOutlineJSON() throws {
        let feature = try parseFixture("outline.feature")
        let json = try exporter.render(feature, format: .json)

        #expect(json.contains("\"outline\""))
        #expect(json.contains("alice@example.com"))
        #expect(json.contains("plainaddress"))
    }

    // MARK: - Markdown Export

    @Test("Export simple.feature to Markdown")
    func exportSimpleMarkdown() throws {
        let feature = try parseFixture("simple.feature")
        let markdown = try exporter.render(feature, format: .markdown)

        #expect(markdown.contains("# Feature: User Authentication"))
        #expect(markdown.contains("## Scenario: Successful login"))
        #expect(markdown.contains("- **Given**"))
        #expect(markdown.contains("- **When**"))
        #expect(markdown.contains("- **Then**"))
    }

    @Test("Export complex.feature to Markdown — tags as badges")
    func exportComplexMarkdownTags() throws {
        let feature = try parseFixture("complex.feature")
        let markdown = try exporter.render(feature, format: .markdown)

        #expect(markdown.contains("`@e2e`"))
        #expect(markdown.contains("`@smoke`"))
        #expect(markdown.contains("`@cart`"))
    }

    @Test("Export complex.feature to Markdown — background section")
    func exportComplexMarkdownBackground() throws {
        let feature = try parseFixture("complex.feature")
        let markdown = try exporter.render(feature, format: .markdown)

        #expect(markdown.contains("### Background"))
    }

    @Test("Export complex.feature to Markdown — data table as markdown table")
    func exportComplexMarkdownTable() throws {
        let feature = try parseFixture("complex.feature")
        let markdown = try exporter.render(feature, format: .markdown)

        // Markdown tables have | separators and --- rows
        #expect(markdown.contains("| product"))
        #expect(markdown.contains("---"))
    }

    @Test("Export complex.feature to Markdown — doc string as code block")
    func exportComplexMarkdownDocString() throws {
        let feature = try parseFixture("complex.feature")
        let markdown = try exporter.render(feature, format: .markdown)

        #expect(markdown.contains("```application/json"))
        #expect(markdown.contains("```"))
    }

    @Test("Export outline.feature to Markdown — examples section")
    func exportOutlineMarkdown() throws {
        let feature = try parseFixture("outline.feature")
        let markdown = try exporter.render(feature, format: .markdown)

        #expect(markdown.contains("## Scenario Outline:"))
        #expect(markdown.contains("### Examples"))
    }

    @Test("Export rules.feature to Markdown — rule sections")
    func exportRulesMarkdown() throws {
        let feature = try parseFixture("rules.feature")
        let markdown = try exporter.render(feature, format: .markdown)

        #expect(markdown.contains("## Rule: Standard pricing"))
        #expect(markdown.contains("## Rule: Volume discounts"))
        #expect(markdown.contains("## Rule: Seasonal promotions"))
    }

    // MARK: - Export to File

    @Test("Export feature to file and re-read")
    func exportToFile() async throws {
        let feature = try parseFixture("simple.feature")

        let tempDir = FileManager.default.temporaryDirectory
        let outputPath = tempDir.appendingPathComponent("export-test-\(UUID()).feature").path

        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        try await exporter.export(feature, to: outputPath)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("User Authentication"))
        #expect(content.contains("Successful login"))
    }

    @Test("Export feature to JSON file and re-read")
    func exportToJSONFile() async throws {
        let feature = try parseFixture("complex.feature")

        let tempDir = FileManager.default.temporaryDirectory
        let outputPath = tempDir.appendingPathComponent("export-test-\(UUID()).json").path

        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        try await exporter.export(feature, to: outputPath, format: .json)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        let jsonParser = JSONFeatureParser()
        let reimported = try jsonParser.parse(content)

        #expect(reimported == feature)
    }

    // MARK: - Streaming Export

    @Test("Streaming export matches in-memory export")
    func streamingExportMatchesInMemory() async throws {
        let feature = try parseFixture("complex.feature")

        let inMemory = exporter.formatter.format(feature)

        let tempDir = FileManager.default.temporaryDirectory
        let outputPath = tempDir.appendingPathComponent("streaming-test-\(UUID()).feature").path

        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let streamingExporter = StreamingExporter()
        try await streamingExporter.export(feature, to: outputPath)

        let streamed = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(inMemory == streamed)
    }

    @Test("Streaming export lines match formatted output")
    func streamingExportLines() async throws {
        let feature = try parseFixture("simple.feature")

        let streamingExporter = StreamingExporter()
        var collectedLines: [String] = []
        for await line in await streamingExporter.lines(for: feature) {
            collectedLines.append(line)
        }

        let inMemory = exporter.formatter.format(feature)
        let rejoined = collectedLines.joined(separator: "\n") + "\n"
        #expect(inMemory == rejoined)
    }
}
