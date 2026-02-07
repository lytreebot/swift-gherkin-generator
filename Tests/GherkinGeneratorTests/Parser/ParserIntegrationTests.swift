import Testing

@testable import GherkinGenerator

@Suite("GherkinParser - Integration")
struct GherkinParserIntegrationTests {

    private let parser = GherkinParser()

    private static let complexSource = """
        # language: en
        # Feature-level comment
        @smoke @regression
        Feature: Shopping Cart
          As a customer I want to manage my cart.

          Background:
            Given a logged-in user
            And an empty cart

          @happy
          Scenario: Add single product
            Given a product at 29 euros
            When I add it to the cart
            Then the cart contains 1 item
            And the total is 29 euros

          Scenario Outline: Add multiple products
            Given a product at <price> euros
            When I add <quantity> to the cart
            Then the total is <total> euros

            Examples:
              | price | quantity | total |
              | 10    | 2        | 20    |
              | 5     | 3        | 15    |

          Rule: Discount rules
            Background:
              Given a premium customer

            @discount
            Scenario: Volume discount
              When I add 10 items
              Then a 10% discount is applied
        """

    @Test("Complex feature structure: title, tags, description, background, children count, comments")
    func complexFeatureStructure() throws {
        let feature = try parser.parse(Self.complexSource)

        #expect(feature.title == "Shopping Cart")
        #expect(feature.tags.count == 2)
        #expect(feature.description?.contains("As a customer") == true)
        #expect(feature.background != nil)
        #expect(feature.background?.steps.count == 2)
        #expect(feature.comments.count == 1)
        #expect(feature.children.count == 3)
    }

    @Test("Complex feature: scenario with tags and outline with examples")
    func complexFeatureScenarioAndOutline() throws {
        let feature = try parser.parse(Self.complexSource)

        // Scenario with tags
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.tags.count == 1)
        #expect(scenario.tags[0].name == "happy")
        #expect(scenario.steps.count == 4)

        // Outline
        guard case .outline(let outline) = feature.children[1] else {
            Issue.record("Expected outline")
            return
        }
        #expect(outline.steps.count == 3)
        #expect(outline.examples.count == 1)
        #expect(outline.examples[0].table.rowCount == 3)
    }

    @Test("Complex feature: rule with background and child scenario")
    func complexFeatureRule() throws {
        let feature = try parser.parse(Self.complexSource)

        guard case .rule(let rule) = feature.children[2] else {
            Issue.record("Expected rule")
            return
        }
        #expect(rule.title == "Discount rules")
        #expect(rule.background != nil)
        #expect(rule.children.count == 1)
        if case .scenario(let ruleScenario) = rule.children[0] {
            #expect(ruleScenario.tags.count == 1)
            #expect(ruleScenario.tags[0].name == "discount")
        }
    }

    // MARK: - Roundtrip

    @Test("Parse then format produces valid output")
    func parseAndFormat() throws {
        let source = """
            Feature: Login
              Scenario: Success
                Given a valid account
                When the user logs in
                Then the dashboard is displayed
            """
        let feature = try parser.parse(source)
        let formatter = GherkinFormatter()
        let output = formatter.format(feature)
        #expect(output.contains("Feature: Login"))
        #expect(output.contains("Example: Success"))
        #expect(output.contains("Given a valid account"))
    }
}
