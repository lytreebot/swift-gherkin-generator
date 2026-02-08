import Foundation
import Testing

@testable import GherkinGenerator

@Suite("Parser — Coverage")
struct ParserCoverageTests {

    // MARK: - JSONFeatureParser.parse(contentsOfFile:)

    @Test("JSONFeatureParser — parse from file path")
    func jsonParseFromFile() throws {
        let tempPath = NSTemporaryDirectory() + "json-parse-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        // Create a feature, export to JSON, write to file
        let feature = Feature(
            title: "File Parse Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Test",
                        steps: [
                            Step(keyword: .given, text: "something"),
                            Step(keyword: .then, text: "result")
                        ]
                    ))
            ]
        )

        let exporter = GherkinExporter()
        let json = try exporter.render(feature, format: .json)
        try json.write(toFile: tempPath, atomically: true, encoding: .utf8)

        let parser = JSONFeatureParser()
        let parsed = try parser.parse(contentsOfFile: tempPath)
        #expect(parsed.title == "File Parse Test")
        #expect(parsed == feature)
    }

    @Test("JSONFeatureParser — parse from nonexistent file throws")
    func jsonParseFromNonexistentFile() {
        let parser = JSONFeatureParser()
        #expect(throws: GherkinError.self) {
            try parser.parse(contentsOfFile: "/nonexistent/file.json")
        }
    }

    @Test("JSONFeatureParser — parse invalid JSON from file throws")
    func jsonParseInvalidJSON() throws {
        let tempPath = NSTemporaryDirectory() + "invalid-json-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        try "not valid json".write(toFile: tempPath, atomically: true, encoding: .utf8)

        let parser = JSONFeatureParser()
        #expect(throws: GherkinError.self) {
            try parser.parse(contentsOfFile: tempPath)
        }
    }

    // MARK: - CSVParser Missing Column Errors

    @Test("CSVParser — missing scenario column throws")
    func csvMissingScenarioColumn() {
        let csv = "Given,When,Then\nstep1,step2,step3\n"
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)

        #expect(throws: GherkinError.self) {
            try parser.parse(csv, featureTitle: "Test")
        }
    }

    @Test("CSVParser — missing given column throws")
    func csvMissingGivenColumn() {
        let csv = "Scenario,When,Then\ntest,step2,step3\n"
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)

        #expect(throws: GherkinError.self) {
            try parser.parse(csv, featureTitle: "Test")
        }
    }

    @Test("CSVParser — missing when column throws")
    func csvMissingWhenColumn() {
        let csv = "Scenario,Given,Then\ntest,step1,step3\n"
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)

        #expect(throws: GherkinError.self) {
            try parser.parse(csv, featureTitle: "Test")
        }
    }

    @Test("CSVParser — missing then column throws")
    func csvMissingThenColumn() {
        let csv = "Scenario,Given,When\ntest,step1,step2\n"
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)

        #expect(throws: GherkinError.self) {
            try parser.parse(csv, featureTitle: "Test")
        }
    }

    // MARK: - PlainTextParser Edge Cases

    @Test("PlainTextParser — wildcard step (* prefix)")
    func plainTextWildcardStep() throws {
        let text = """
            Inventory Check

            Check stock
            * open the inventory
            * verify the count
            Then the count is correct
            """

        let parser = PlainTextParser()
        let feature = try parser.parse(text)

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        let wildcardSteps = scenario.steps.filter { $0.keyword == .wildcard }
        #expect(wildcardSteps.count == 2)
    }

    @Test("PlainTextParser — scenario separator in middle")
    func plainTextSeparator() throws {
        let text = """
            Feature Title

            First scenario
            Given a thing
            Then a result
            ---
            Second scenario
            Given another thing
            Then another result
            """

        let parser = PlainTextParser()
        let feature = try parser.parse(text)

        #expect(feature.children.count == 2)
    }

    // MARK: - GherkinParser — Outline inside Rule

    @Test("GherkinParser — outline inside rule body")
    func parseOutlineInsideRule() throws {
        let source = """
            Feature: Rules with Outlines

              Rule: Pricing rules

                Scenario Outline: Discount for <qty>
                  Given <qty> items in the cart
                  Then the discount is <pct>%

                  Examples:
                    | qty | pct |
                    | 10  | 5   |
                    | 50  | 10  |
            """

        let parser = GherkinParser()
        let feature = try parser.parse(source)

        #expect(feature.rules.count == 1)
        let rule = feature.rules[0]
        #expect(rule.children.count == 1)
        guard case .outline(let outline) = rule.children[0] else {
            Issue.record("Expected outline in rule")
            return
        }
        #expect(outline.title == "Discount for <qty>")
        #expect(outline.examples.count == 1)
    }
}
