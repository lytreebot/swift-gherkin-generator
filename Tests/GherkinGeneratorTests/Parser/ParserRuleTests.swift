import Testing

@testable import GherkinGenerator

@Suite("GherkinParser - Rules")
struct GherkinParserRuleTests {

    private let parser = GherkinParser()

    @Test("Parse feature with rule")
    func rule() throws {
        let source = """
            Feature: Discount
              Rule: Premium customers
                Scenario: 10% discount
                  Given a premium customer
                  When they buy over 100
                  Then 10% discount applied

                Scenario: Free shipping
                  Given a premium customer
                  When order over 50
                  Then shipping is free
            """
        let feature = try parser.parse(source)
        guard case .rule(let rule) = feature.children[0] else {
            Issue.record("Expected rule")
            return
        }
        #expect(rule.title == "Premium customers")
        #expect(rule.children.count == 2)
    }

    @Test("Parse rule with background")
    func ruleWithBackground() throws {
        let source = """
            Feature: Discount
              Rule: Premium rules
                Background:
                  Given a premium customer

                Scenario: Discount
                  When they buy over 100
                  Then 10% discount applied
            """
        let feature = try parser.parse(source)
        guard case .rule(let rule) = feature.children[0] else {
            Issue.record("Expected rule")
            return
        }
        #expect(rule.background != nil)
        #expect(rule.background?.steps.count == 1)
        #expect(rule.children.count == 1)
    }

    @Test("Parse rule with tags")
    func ruleWithTags() throws {
        let source = """
            Feature: Discount
              @premium
              Rule: Premium rules
                Scenario: Test
                  Given something
                  Then result
            """
        let feature = try parser.parse(source)
        guard case .rule(let rule) = feature.children[0] else {
            Issue.record("Expected rule")
            return
        }
        #expect(rule.tags.count == 1)
        #expect(rule.tags[0].name == "premium")
    }
}
