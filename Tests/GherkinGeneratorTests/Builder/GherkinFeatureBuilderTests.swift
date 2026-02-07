import Testing

@testable import GherkinGenerator

@Suite("GherkinFeature Builder")
struct GherkinFeatureBuilderTests {

    @Test("Simple scenario with Given/When/Then")
    func simpleScenario() throws {
        let feature = try GherkinFeature(title: "Login")
            .addScenario("Successful login")
            .given("a valid account")
            .when("the user logs in")
            .then("the dashboard is displayed")
            .build()

        #expect(feature.title == "Login")
        #expect(feature.children.count == 1)

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected a scenario")
            return
        }

        #expect(scenario.title == "Successful login")
        #expect(scenario.steps.count == 3)
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[0].text == "a valid account")
        #expect(scenario.steps[1].keyword == .when)
        #expect(scenario.steps[2].keyword == .then)
    }

    @Test("Scenario with And/But continuations")
    func scenarioWithContinuations() throws {
        let feature = try GherkinFeature(title: "Cart")
            .addScenario("Add product")
            .given("an empty cart")
            .when("I add a product at 29€")
            .then("the cart contains 1 item")
            .and("the total is 29€")
            .but("no discount is applied")
            .build()

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected a scenario")
            return
        }

        #expect(scenario.steps.count == 5)
        #expect(scenario.steps[3].keyword == .and)
        #expect(scenario.steps[4].keyword == .but)
    }

    @Test("Multiple scenarios")
    func multipleScenarios() throws {
        let feature = try GherkinFeature(title: "Auth")
            .addScenario("Login success")
            .given("valid credentials")
            .then("access granted")
            .addScenario("Login failure")
            .given("invalid credentials")
            .then("error displayed")
            .build()

        #expect(feature.children.count == 2)
    }

    @Test("Background with closure")
    func backgroundClosure() throws {
        let feature = try GherkinFeature(title: "Orders")
            .background {
                $0.given("a logged-in user")
                    .and("at least one existing order")
            }
            .addScenario("View orders")
            .when("I view my orders")
            .then("the list is displayed")
            .build()

        #expect(feature.background != nil)
        #expect(feature.background?.steps.count == 2)
    }

    @Test("Scenario Outline with Examples")
    func scenarioOutline() throws {
        let feature = try GherkinFeature(title: "Email Validation")
            .addOutline("Email format")
            .given("the email <email>")
            .when("I validate the format")
            .then("the result is <valid>")
            .examples([
                ["email", "valid"],
                ["test@example.com", "true"],
                ["invalid", "false"]
            ])
            .build()

        guard case .outline(let outline) = feature.children[0] else {
            Issue.record("Expected an outline")
            return
        }

        #expect(outline.title == "Email format")
        #expect(outline.steps.count == 3)
        #expect(outline.examples.count == 1)
        #expect(outline.examples[0].table.rowCount == 3)
    }

    @Test("Data table on step")
    func dataTable() throws {
        let feature = try GherkinFeature(title: "Pricing")
            .addScenario("Price by quantity")
            .given("the following prices")
            .table([
                ["Quantity", "Unit Price"],
                ["1-10", "10€"],
                ["11-50", "8€"]
            ])
            .when("I order 25 units")
            .then("the unit price is 8€")
            .build()

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected a scenario")
            return
        }

        #expect(scenario.steps[0].dataTable != nil)
        #expect(scenario.steps[0].dataTable?.rowCount == 3)
        #expect(scenario.steps[0].dataTable?.columnCount == 2)
    }

    @Test("Feature tags and scenario tags")
    func tags() throws {
        let feature = try GherkinFeature(title: "Payment")
            .tags(["@payment", "@critical"])
            .addScenario("Credit card")
            .scenarioTags(["@card", "@slow"])
            .given("a validated cart")
            .then("payment is processed")
            .build()

        #expect(feature.tags.count == 2)
        #expect(feature.tags[0].rawValue == "@payment")

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected a scenario")
            return
        }

        #expect(scenario.tags.count == 2)
        #expect(scenario.tags[0].rawValue == "@card")
    }

    @Test("Multi-language feature")
    func multiLanguage() throws {
        let feature = try GherkinFeature(title: "Authentification", language: .french)
            .addScenario("Connexion")
            .given("un compte valide")
            .when("je me connecte")
            .then("je suis connecté")
            .build()

        #expect(feature.language == .french)
        #expect(feature.language.code == "fr")
    }

    @Test("Empty title throws")
    func emptyTitle() {
        #expect(throws: GherkinError.emptyTitle) {
            try GherkinFeature(title: "").build()
        }
    }

    @Test("Mass generation with loop")
    func massGeneration() throws {
        let endpoints = ["users", "products", "orders"]
        var builder = GherkinFeature(title: "API Smoke Tests")

        for endpoint in endpoints {
            builder =
                builder
                .addScenario("GET /\(endpoint) returns 200")
                .given("the API is running")
                .when("I request GET /api/\(endpoint)")
                .then("the response status is 200")
        }

        let feature = try builder.build()
        #expect(feature.children.count == 3)
    }

    @Test("Mutating appendScenario")
    func appendScenario() throws {
        var builder = GherkinFeature(title: "Tests")
        builder.appendScenario(
            Scenario(
                title: "Test 1",
                steps: [
                    Step(keyword: .given, text: "something"),
                    Step(keyword: .then, text: "result")
                ]
            )
        )

        let feature = try builder.build()
        #expect(feature.children.count == 1)
    }
}
