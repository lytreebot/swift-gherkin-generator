import Testing

@testable import GherkinGenerator

@Suite("GherkinParser - Tables & Doc Strings")
struct GherkinParserTableDocStringTests {

    private let parser = GherkinParser()

    // MARK: - Data Tables

    @Test("Parse step with data table")
    func dataTable() throws {
        let source = """
            Feature: Pricing
              Scenario: Prices by quantity
                Given the following prices
                  | Quantity | Price |
                  | 1-10     | 10    |
                  | 11-50    | 8     |
                When I order 25 units
                Then the unit price is 8
            """
        let feature = try parser.parse(source)
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps[0].dataTable != nil)
        #expect(scenario.steps[0].dataTable?.rowCount == 3)
        #expect(scenario.steps[0].dataTable?.columnCount == 2)
        #expect(scenario.steps[0].dataTable?.headers == ["Quantity", "Price"])
        #expect(scenario.steps[1].dataTable == nil)
    }

    // MARK: - Doc Strings

    @Test("Parse step with doc string")
    func docString() throws {
        let source = """
            Feature: API
              Scenario: POST request
                Given the following payload
                  \"\"\"
                  {"name": "Alice"}
                  \"\"\"
                When I send a POST request
                Then the response is 201
            """
        let feature = try parser.parse(source)
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps[0].docString != nil)
        #expect(scenario.steps[0].docString?.content.contains("Alice") == true)
        #expect(scenario.steps[0].docString?.mediaType == nil)
    }

    @Test("Parse doc string with media type")
    func docStringWithMediaType() throws {
        let source = """
            Feature: API
              Scenario: POST JSON
                Given the payload
                  \"\"\"json
                  {"key": "value"}
                  \"\"\"
                Then ok
            """
        let feature = try parser.parse(source)
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps[0].docString?.mediaType == "json")
    }
}
