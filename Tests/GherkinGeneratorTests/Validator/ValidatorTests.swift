import Testing

@testable import GherkinGenerator

@Suite("GherkinValidator")
struct GherkinValidatorTests {

    @Test("Valid feature passes all default rules")
    func validFeaturePasses() {
        let feature = Feature(
            title: "Shopping Cart",
            tags: [Tag("smoke")],
            children: [
                .scenario(
                    Scenario(
                        title: "Add product",
                        tags: [Tag("cart")],
                        steps: [
                            Step(keyword: .given, text: "an empty cart"),
                            Step(keyword: .when, text: "I add a product"),
                            Step(keyword: .then, text: "cart contains 1 item")
                        ]
                    ))
            ]
        )
        let validator = GherkinValidator()
        let errors = validator.collectErrors(in: feature)
        #expect(errors.isEmpty)
    }

    @Test("validate() throws on first error")
    func validateThrows() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "No steps",
                        steps: []
                    ))
            ]
        )
        let validator = GherkinValidator()
        #expect(throws: GherkinError.self) {
            try validator.validate(feature)
        }
    }

    @Test("Custom rules are applied")
    func customRules() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Valid",
                        steps: [
                            Step(keyword: .given, text: "a"),
                            Step(keyword: .then, text: "b")
                        ]
                    ))
            ]
        )
        let validator = GherkinValidator(rules: [StructureRule()])
        let errors = validator.collectErrors(in: feature)
        #expect(errors.isEmpty)
    }

    @Test("Multiple rules accumulate errors")
    func multipleRulesAccumulate() {
        let feature = Feature(
            title: "Test",
            tags: [Tag("has space")],
            children: [
                .scenario(
                    Scenario(
                        title: "Bad",
                        steps: [
                            Step(keyword: .when, text: "something")
                        ]
                    ))
            ]
        )
        let validator = GherkinValidator(rules: [StructureRule(), TagFormatRule()])
        let errors = validator.collectErrors(in: feature)
        #expect(errors.count == 3)
    }
}
