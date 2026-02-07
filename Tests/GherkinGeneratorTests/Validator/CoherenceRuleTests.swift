import Testing

@testable import GherkinGenerator

@Suite("CoherenceRule")
struct CoherenceRuleTests {

    private let rule = CoherenceRule()

    @Test("No duplicates passes")
    func noDuplicates() {
        let feature = Feature(
            title: "Cart",
            children: [
                .scenario(
                    Scenario(
                        title: "Add product",
                        steps: [
                            Step(keyword: .given, text: "an empty cart"),
                            Step(keyword: .when, text: "I add a product"),
                            Step(keyword: .then, text: "cart has 1 item")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Consecutive duplicate steps reports error")
    func consecutiveDuplicate() {
        let feature = Feature(
            title: "Cart",
            children: [
                .scenario(
                    Scenario(
                        title: "Duplicate",
                        steps: [
                            Step(keyword: .given, text: "an empty cart"),
                            Step(keyword: .given, text: "an empty cart"),
                            Step(keyword: .then, text: "cart is empty")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .duplicateConsecutiveStep(step: "an empty cart", scenario: "Duplicate"))
    }

    @Test("Same text but different keyword is not a duplicate")
    func sameTextDifferentKeyword() {
        let feature = Feature(
            title: "Cart",
            children: [
                .scenario(
                    Scenario(
                        title: "Not duplicate",
                        steps: [
                            Step(keyword: .given, text: "a product exists"),
                            Step(keyword: .when, text: "a product exists"),
                            Step(keyword: .then, text: "ok")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Duplicates in background are detected")
    func duplicatesInBackground() {
        let feature = Feature(
            title: "Setup",
            background: Background(steps: [
                Step(keyword: .given, text: "a user"),
                Step(keyword: .given, text: "a user")
            ]),
            children: [
                .scenario(
                    Scenario(
                        title: "Test",
                        steps: [
                            Step(keyword: .given, text: "data"),
                            Step(keyword: .then, text: "ok")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .duplicateConsecutiveStep(step: "a user", scenario: "Setup"))
    }

    @Test("Duplicates in outline are detected")
    func duplicatesInOutline() {
        let feature = Feature(
            title: "Email",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Dup outline",
                        steps: [
                            Step(keyword: .given, text: "email <email>"),
                            Step(keyword: .given, text: "email <email>"),
                            Step(keyword: .then, text: "result <valid>")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .duplicateConsecutiveStep(step: "email <email>", scenario: "Dup outline"))
    }

    @Test("Duplicates in rule children are detected")
    func duplicatesInRuleChildren() {
        let feature = Feature(
            title: "Rules",
            children: [
                .rule(
                    Rule(
                        title: "Business",
                        children: [
                            .scenario(
                                Scenario(
                                    title: "Dup in rule",
                                    steps: [
                                        Step(keyword: .then, text: "ok"),
                                        Step(keyword: .then, text: "ok")
                                    ]
                                ))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .duplicateConsecutiveStep(step: "ok", scenario: "Dup in rule"))
    }

    @Test("Multiple consecutive duplicates reports multiple errors")
    func multipleDuplicates() {
        let feature = Feature(
            title: "Cart",
            children: [
                .scenario(
                    Scenario(
                        title: "Triple",
                        steps: [
                            Step(keyword: .given, text: "a"),
                            Step(keyword: .given, text: "a"),
                            Step(keyword: .given, text: "a"),
                            Step(keyword: .then, text: "done")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
    }
}
