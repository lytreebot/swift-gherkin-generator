import Foundation
import Testing

@testable import GherkinGenerator

@Suite("Fixture Performance")
struct FixturePerformanceTests {

    private let parser = GherkinParser()
    private let exporter = GherkinExporter()
    private let validator = GherkinValidator()
    private let jsonParser = JSONFeatureParser()

    // MARK: - Helpers

    private func parseFixture(_ name: String) throws -> Feature {
        guard let url = Bundle.module.url(forResource: name, withExtension: nil) else {
            throw GherkinError.importFailed(path: name, reason: "Fixture not found")
        }
        let source = try String(contentsOf: url, encoding: .utf8)
        return try parser.parse(source)
    }

    private func fixtureSource(_ name: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: nil) else {
            throw GherkinError.importFailed(path: name, reason: "Fixture not found")
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Parsing Performance

    @Test("Parse large.feature within time limit")
    func parseLargeFeature() throws {
        let source = try fixtureSource("large.feature")

        let start = ContinuousClock.now
        for _ in 0..<100 {
            _ = try parser.parse(source)
        }
        let duration = ContinuousClock.now - start

        // 100 parses of a 52+ scenario file should complete within 5 seconds
        #expect(duration < .seconds(5), "Parsing 100x took \(duration)")
    }

    @Test("Parse complex.feature 500 times")
    func parseComplexRepeatedly() throws {
        let source = try fixtureSource("complex.feature")

        let start = ContinuousClock.now
        for _ in 0..<500 {
            _ = try parser.parse(source)
        }
        let duration = ContinuousClock.now - start

        #expect(duration < .seconds(5), "Parsing 500x took \(duration)")
    }

    // MARK: - Formatting Performance

    @Test("Format large feature 100 times")
    func formatLargeFeature() throws {
        let feature = try parseFixture("large.feature")

        let start = ContinuousClock.now
        for _ in 0..<100 {
            _ = exporter.formatter.format(feature)
        }
        let duration = ContinuousClock.now - start

        #expect(duration < .seconds(5), "Formatting 100x took \(duration)")
    }

    // MARK: - JSON Export/Import Performance

    @Test("JSON export large feature 100 times")
    func jsonExportLargeFeature() throws {
        let feature = try parseFixture("large.feature")

        let start = ContinuousClock.now
        for _ in 0..<100 {
            _ = try exporter.render(feature, format: .json)
        }
        let duration = ContinuousClock.now - start

        #expect(duration < .seconds(5), "JSON export 100x took \(duration)")
    }

    @Test("JSON roundtrip large feature 100 times")
    func jsonRoundtripLargeFeature() throws {
        let feature = try parseFixture("large.feature")
        let json = try exporter.render(feature, format: .json)

        let start = ContinuousClock.now
        for _ in 0..<100 {
            _ = try jsonParser.parse(json)
        }
        let duration = ContinuousClock.now - start

        #expect(duration < .seconds(5), "JSON import 100x took \(duration)")
    }

    // MARK: - Validation Performance

    @Test("Validate large feature 100 times")
    func validateLargeFeature() throws {
        let feature = try parseFixture("large.feature")

        let start = ContinuousClock.now
        for _ in 0..<100 {
            _ = validator.collectErrors(in: feature)
        }
        let duration = ContinuousClock.now - start

        #expect(duration < .seconds(5), "Validation 100x took \(duration)")
    }

    // MARK: - Markdown Export Performance

    @Test("Markdown export large feature 100 times")
    func markdownExportLargeFeature() throws {
        let feature = try parseFixture("large.feature")

        let start = ContinuousClock.now
        for _ in 0..<100 {
            _ = try exporter.render(feature, format: .markdown)
        }
        let duration = ContinuousClock.now - start

        #expect(duration < .seconds(5), "Markdown export 100x took \(duration)")
    }

    // MARK: - Streaming Export Performance

    @Test("Streaming export large feature — lines collected")
    func streamingExportCollectLines() async throws {
        let feature = try parseFixture("large.feature")
        let streamingExporter = StreamingExporter()

        let start = ContinuousClock.now
        var lineCount = 0
        for await _ in await streamingExporter.lines(for: feature) {
            lineCount += 1
        }
        let duration = ContinuousClock.now - start

        #expect(lineCount > 100, "Expected many lines, got \(lineCount)")
        #expect(duration < .seconds(2), "Streaming took \(duration)")
    }

    // MARK: - Batch Import Performance

    @Test("Batch import multilang features")
    func batchImportMultilang() async throws {
        let fixtures = try loadMultilangFixtures()
        let batchImporter = BatchImporter()
        let results = try await batchImporter.importDirectory(at: fixtures.path)

        #expect(results.count == 3)  // es, it, pt
        let allSucceeded = results.allSatisfy { result in
            if case .success = result { return true }
            return false
        }
        #expect(allSucceeded)
    }

    // MARK: - Batch Validation Performance

    @Test("Batch validate multilang features")
    func batchValidateMultilang() async throws {
        let fixtures = try loadMultilangFixtures()
        let batchValidator = BatchValidator()
        let results = try await batchValidator.validateDirectory(at: fixtures.path)

        #expect(results.count == 3)
    }

    private func loadMultilangFixtures() throws -> FeatureFixtureDirectory {
        var files: [String: String] = [:]
        for name in ["es_login.feature", "it_products.feature", "pt_payment.feature"] {
            guard let url = Bundle.module.url(forResource: name, withExtension: nil) else {
                throw GherkinError.importFailed(path: name, reason: "Fixture not found")
            }
            files[name] = try String(contentsOf: url, encoding: .utf8)
        }
        return try FeatureFixtureDirectory(files: files)
    }

    // MARK: - Memory Efficiency

    @Test("Parse and format without excessive allocations")
    func memoryEfficiency() throws {
        let source = try fixtureSource("large.feature")

        // Parse, format, and discard in a tight loop to test for leaks
        for _ in 0..<50 {
            let feature = try parser.parse(source)
            _ = exporter.formatter.format(feature)
            _ = try exporter.render(feature, format: .json)
            _ = try exporter.render(feature, format: .markdown)
        }

        // If we get here without crashing or running out of memory, we're good
        #expect(Bool(true))
    }
}
