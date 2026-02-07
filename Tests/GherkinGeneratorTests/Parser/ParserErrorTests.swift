import Testing

@testable import GherkinGenerator

@Suite("GherkinParser - Errors")
struct GherkinParserErrorTests {

    private let parser = GherkinParser()

    // MARK: - Syntax Errors

    @Test("Missing Feature keyword throws syntax error")
    func missingSyntaxError() {
        #expect(throws: GherkinError.self) {
            try parser.parse("Scenario: No feature")
        }
    }

    @Test("Unexpected line in feature body throws error")
    func unexpectedLineInBody() {
        let source = """
            Feature: Test
              Scenario: Valid
                Given something
                Then result

              this is not a valid keyword or tag
            """
        #expect(throws: GherkinError.self) {
            try parser.parse(source)
        }
    }

    @Test("Empty source throws syntax error")
    func emptySource() {
        #expect(throws: GherkinError.self) {
            try parser.parse("")
        }
    }

    // MARK: - File Import Error

    @Test("Import nonexistent file throws importFailed")
    func nonexistentFile() {
        #expect(throws: GherkinError.self) {
            try parser.parse(contentsOfFile: "/nonexistent/path.feature")
        }
    }
}
