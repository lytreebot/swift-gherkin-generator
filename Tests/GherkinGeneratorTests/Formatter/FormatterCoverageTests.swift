import Testing

@testable import GherkinGenerator

@Suite("GherkinFormatter — Coverage")
struct FormatterCoverageTests {

    private let formatter = GherkinFormatter()

    // MARK: - Helpers

    private static var ruleWithOutlineFeature: Feature {
        Feature(
            title: "Pricing",
            children: [
                .rule(
                    Rule(
                        title: "Volume discounts",
                        tags: [Tag("pricing")],
                        description: "Discounts for large orders",
                        background: Background(steps: [
                            Step(keyword: .given, text: "a wholesale account")
                        ]),
                        children: [
                            .outline(
                                ScenarioOutline(
                                    title: "Discount for <quantity> items",
                                    tags: [Tag("discount")],
                                    steps: [
                                        Step(keyword: .given, text: "<quantity> items in the cart"),
                                        Step(keyword: .then, text: "the discount is <discount>%")
                                    ],
                                    examples: [
                                        Examples(
                                            name: "Standard discounts",
                                            tags: [Tag("standard")],
                                            table: DataTable(rows: [
                                                ["quantity", "discount"],
                                                ["10", "5"],
                                                ["50", "10"]
                                            ])
                                        ),
                                        Examples(
                                            table: DataTable(rows: [
                                                ["quantity", "discount"],
                                                ["100", "15"]
                                            ])
                                        )
                                    ]
                                )),
                            .scenario(
                                Scenario(
                                    title: "No discount for small orders",
                                    steps: [
                                        Step(keyword: .given, text: "2 items in the cart"),
                                        Step(keyword: .then, text: "no discount applied")
                                    ]
                                ))
                        ]
                    ))
            ]
        )
    }

    // MARK: - Rule with Outline — Structure

    @Test("Format rule with outline — tags and title")
    func formatRuleOutlineTags() {
        let output = formatter.format(Self.ruleWithOutlineFeature)

        #expect(output.contains("@pricing"))
        #expect(output.contains("Rule: Volume discounts"))
        #expect(output.contains("Discounts for large orders"))
        #expect(output.contains("Background:"))
        #expect(output.contains("Given a wholesale account"))
    }

    @Test("Format rule with outline — outline and examples")
    func formatRuleOutlineExamples() {
        let output = formatter.format(Self.ruleWithOutlineFeature)

        #expect(output.contains("@discount"))
        #expect(output.contains("Scenario Outline: Discount for <quantity> items"))
        #expect(output.contains("@standard"))
        #expect(output.contains("Examples: Standard discounts"))
        #expect(output.contains("Examples:"))
        #expect(output.contains("No discount for small orders"))
    }

    // MARK: - Feature with description

    @Test("Format feature with description")
    func formatFeatureWithDescription() {
        let feature = Feature(
            title: "Auth",
            description: "Covers login and registration",
            children: [
                .scenario(
                    Scenario(
                        title: "Login",
                        steps: [Step(keyword: .given, text: "credentials")]
                    ))
            ]
        )

        let output = formatter.format(feature)
        #expect(output.contains("Covers login and registration"))
    }

    // MARK: - Rule with description only (no background)

    @Test("Format rule with description but no background")
    func formatRuleWithDescriptionNoBackground() {
        let feature = Feature(
            title: "Pricing",
            children: [
                .rule(
                    Rule(
                        title: "Standard pricing",
                        description: "Regular customer pricing rules",
                        children: [
                            .scenario(
                                Scenario(
                                    title: "Full price",
                                    steps: [
                                        Step(keyword: .given, text: "a regular customer"),
                                        Step(keyword: .then, text: "full price applied")
                                    ]
                                ))
                        ]
                    ))
            ]
        )

        let output = formatter.format(feature)
        #expect(output.contains("Regular customer pricing rules"))
    }
}
