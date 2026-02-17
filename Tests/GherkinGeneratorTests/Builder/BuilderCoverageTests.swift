// SPDX-License-Identifier: Apache-2.0
//
// Copyright 2026 Atelier Socle SAS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import Testing

@testable import GherkinGenerator

@Suite("GherkinFeature Builder — Coverage")
struct BuilderCoverageTests {

    // MARK: - description()

    @Test("Feature description via builder")
    func featureDescription() throws {
        let feature = try GherkinFeature(title: "Login")
            .description("Covers authentication flows")
            .addScenario("Test")
            .given("something")
            .then("result")
            .build()

        #expect(feature.description == "Covers authentication flows")
    }

    // MARK: - comment()

    @Test("Feature comment via builder")
    func featureComment() throws {
        let feature = try GherkinFeature(title: "Login")
            .comment("Author: test suite")
            .addScenario("Test")
            .given("something")
            .then("result")
            .build()

        #expect(feature.comments.count == 1)
        #expect(feature.comments[0].text == "Author: test suite")
    }

    // MARK: - background(Background)

    @Test("Background with pre-built Background value")
    func backgroundPrebuilt() throws {
        let bg = Background(steps: [Step(keyword: .given, text: "a database")])
        let feature = try GherkinFeature(title: "DB Tests")
            .background(bg)
            .addScenario("Query")
            .given("a table")
            .then("rows returned")
            .build()

        #expect(feature.background != nil)
        #expect(feature.background?.steps.count == 1)
        #expect(feature.background?.steps[0].text == "a database")
    }

    // MARK: - step() (wildcard)

    @Test("Wildcard step via builder")
    func wildcardStep() throws {
        let feature = try GherkinFeature(title: "Wildcard")
            .addScenario("Star steps")
            .step("setup the environment")
            .step("run the test")
            .step("check the result")
            .build()

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps.count == 3)
        #expect(scenario.steps[0].keyword == .wildcard)
        #expect(scenario.steps[1].keyword == .wildcard)
        #expect(scenario.steps[2].keyword == .wildcard)
    }

    // MARK: - docString()

    @Test("Doc string on scenario step via builder")
    func docStringOnStep() throws {
        let feature = try GherkinFeature(title: "API")
            .addScenario("POST request")
            .given("a request body")
            .docString("{\"key\": \"value\"}", mediaType: "application/json")
            .then("status 201")
            .build()

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps[0].docString != nil)
        #expect(scenario.steps[0].docString?.content == "{\"key\": \"value\"}")
        #expect(scenario.steps[0].docString?.mediaType == "application/json")
    }

    @Test("Doc string on outline step via builder")
    func docStringOnOutlineStep() throws {
        let feature = try GherkinFeature(title: "API")
            .addOutline("POST <endpoint>")
            .given("a request body")
            .docString("{\"name\": \"<name>\"}")
            .then("status 201")
            .examples([
                ["endpoint", "name"],
                ["/users", "Alice"]
            ])
            .build()

        guard case .outline(let outline) = feature.children[0] else {
            Issue.record("Expected outline")
            return
        }
        #expect(outline.steps[0].docString != nil)
        #expect(outline.steps[0].docString?.content == "{\"name\": \"<name>\"}")
    }

    // MARK: - examples(rows:name:tags:)

    @Test("Named and tagged examples via builder")
    func namedTaggedExamples() throws {
        let feature = try GherkinFeature(title: "Validation")
            .addOutline("Check <input>")
            .given("the input <input>")
            .then("the result is <result>")
            .examples(
                [
                    ["input", "result"],
                    ["valid", "true"]
                ],
                name: "Valid inputs",
                tags: ["@happy-path"]
            )
            .examples(
                [
                    ["input", "result"],
                    ["invalid", "false"]
                ],
                name: "Invalid inputs",
                tags: ["@error-path"]
            )
            .build()

        guard case .outline(let outline) = feature.children[0] else {
            Issue.record("Expected outline")
            return
        }
        #expect(outline.examples.count == 2)
        #expect(outline.examples[0].name == "Valid inputs")
        #expect(outline.examples[0].tags.map(\.name) == ["happy-path"])
        #expect(outline.examples[1].name == "Invalid inputs")
        #expect(outline.examples[1].tags.map(\.name) == ["error-path"])
    }

    @Test("Examples on regular scenario is no-op")
    func examplesOnRegularScenario() throws {
        let feature = try GherkinFeature(title: "Test")
            .addScenario("Not an outline")
            .given("something")
            .then("result")
            .examples([["a"], ["b"]])
            .build()

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        // examples() should be silently ignored on a regular scenario
        #expect(scenario.steps.count == 2)
    }

    // MARK: - addRule()

    @Test("Add rule via builder")
    func addRule() throws {
        let rule = Rule(
            title: "Discount rules",
            children: [
                .scenario(
                    Scenario(
                        title: "10% off",
                        steps: [
                            Step(keyword: .given, text: "a premium customer"),
                            Step(keyword: .then, text: "10% discount")
                        ]
                    ))
            ]
        )
        let feature = try GherkinFeature(title: "Pricing")
            .addScenario("Base price")
            .given("a regular customer")
            .then("full price")
            .addRule(rule)
            .build()

        #expect(feature.children.count == 2)
        guard case .rule(let resultRule) = feature.children[1] else {
            Issue.record("Expected rule")
            return
        }
        #expect(resultRule.title == "Discount rules")
    }

    // MARK: - appendOutline()

    @Test("Mutating appendOutline")
    func appendOutline() throws {
        var builder = GherkinFeature(title: "Tests")
        builder.appendOutline(
            ScenarioOutline(
                title: "Validate <input>",
                steps: [
                    Step(keyword: .given, text: "the input <input>"),
                    Step(keyword: .then, text: "the result is <result>")
                ],
                examples: [
                    Examples(
                        table: DataTable(rows: [
                            ["input", "result"],
                            ["valid", "true"]
                        ]))
                ]
            )
        )

        let feature = try builder.build()
        #expect(feature.children.count == 1)
        guard case .outline(let outline) = feature.children[0] else {
            Issue.record("Expected outline")
            return
        }
        #expect(outline.title == "Validate <input>")
    }

    // MARK: - validate()

    @Test("Builder validate succeeds for valid feature")
    func validateSuccess() throws {
        let builder = GherkinFeature(title: "Valid")
            .addScenario("Test")
            .given("something")
            .then("result")

        #expect(throws: Never.self) {
            try builder.validate()
        }
    }

    @Test("Builder validate throws for empty title")
    func validateEmptyTitle() {
        let builder = GherkinFeature(title: "")

        #expect(throws: GherkinError.self) {
            try builder.validate()
        }
    }

    // MARK: - export()

    @Test("Builder export writes file")
    func exportWritesFile() async throws {
        let tempPath = NSTemporaryDirectory() + "builder-export-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let builder = GherkinFeature(title: "Export Test")
            .addScenario("Scenario")
            .given("a precondition")
            .then("a result")

        try await builder.export(to: tempPath)

        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
        #expect(content.contains("Feature: Export Test"))
        #expect(content.contains("Given a precondition"))
    }

    // MARK: - BackgroundBuilder.but()

    @Test("Background with But step")
    func backgroundWithBut() throws {
        let feature = try GherkinFeature(title: "Test")
            .background {
                $0.given("a logged-in user")
                    .and("a shopping cart")
                    .but("no items in the cart")
            }
            .addScenario("Add item")
            .when("I add a product")
            .then("the cart has 1 item")
            .build()

        #expect(feature.background?.steps.count == 3)
        #expect(feature.background?.steps[2].keyword == .but)
        #expect(feature.background?.steps[2].text == "no items in the cart")
    }

    // MARK: - Table on outline step

    @Test("Data table on outline step")
    func dataTableOnOutlineStep() throws {
        let feature = try GherkinFeature(title: "Tables")
            .addOutline("Check <scenario>")
            .given("the following data")
            .table([
                ["column1", "column2"],
                ["<value1>", "<value2>"]
            ])
            .then("result is <expected>")
            .examples([
                ["scenario", "value1", "value2", "expected"],
                ["test1", "a", "b", "pass"]
            ])
            .build()

        guard case .outline(let outline) = feature.children[0] else {
            Issue.record("Expected outline")
            return
        }
        #expect(outline.steps[0].dataTable != nil)
    }
}
