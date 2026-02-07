import Testing

@testable import GherkinGenerator

@Suite("GherkinParser - Tags")
struct GherkinParserTagTests {

    private let parser = GherkinParser()

    @Test("Parse feature-level and scenario-level tags")
    func tags() throws {
        let source = """
            @smoke @critical
            Feature: Payment

              @card @slow
              Scenario: Credit card
                Given a cart
                Then payment processed
            """
        let feature = try parser.parse(source)
        #expect(feature.tags.count == 2)
        #expect(feature.tags[0].name == "smoke")
        #expect(feature.tags[1].name == "critical")

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.tags.count == 2)
        #expect(scenario.tags[0].name == "card")
        #expect(scenario.tags[1].name == "slow")
    }
}
