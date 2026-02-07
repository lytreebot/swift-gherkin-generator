import Testing

@testable import GherkinGenerator

@Suite("GherkinParser - Outline")
struct GherkinParserOutlineTests {

    private let parser = GherkinParser()

    @Test("Parse scenario outline with examples")
    func scenarioOutline() throws {
        let source = """
            Feature: Email Validation
              Scenario Outline: Email format
                Given the email <email>
                When I validate the format
                Then the result is <valid>

                Examples:
                  | email            | valid |
                  | test@example.com | true  |
                  | invalid          | false |
            """
        let feature = try parser.parse(source)
        guard case .outline(let outline) = feature.children[0] else {
            Issue.record("Expected outline")
            return
        }
        #expect(outline.title == "Email format")
        #expect(outline.steps.count == 3)
        #expect(outline.examples.count == 1)
        #expect(outline.examples[0].table.rowCount == 3)
        #expect(outline.examples[0].table.headers == ["email", "valid"])
    }

    @Test("Parse Scenario Template as Scenario Outline")
    func scenarioTemplate() throws {
        let source = """
            Feature: Template test
              Scenario Template: Email check
                Given the email <email>
                Then the result is <valid>

                Examples:
                  | email | valid |
                  | a@b.c | true  |
            """
        let feature = try parser.parse(source)
        guard case .outline(let outline) = feature.children[0] else {
            Issue.record("Expected outline")
            return
        }
        #expect(outline.title == "Email check")
    }
}
