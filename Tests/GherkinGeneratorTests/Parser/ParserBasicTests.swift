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

import Testing

@testable import GherkinGenerator

@Suite("GherkinParser - Basic")
struct GherkinParserBasicTests {

    private let parser = GherkinParser()

    // MARK: - Simple Feature

    @Test("Parse simple feature with one scenario")
    func simpleFeature() throws {
        let source = """
            Feature: Login
              Scenario: Successful login
                Given a valid account
                When the user logs in
                Then the dashboard is displayed
            """
        let feature = try parser.parse(source)

        #expect(feature.title == "Login")
        #expect(feature.language == .english)
        #expect(feature.children.count == 1)

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.title == "Successful login")
        #expect(scenario.steps.count == 3)
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[0].text == "a valid account")
        #expect(scenario.steps[1].keyword == .when)
        #expect(scenario.steps[1].text == "the user logs in")
        #expect(scenario.steps[2].keyword == .then)
        #expect(scenario.steps[2].text == "the dashboard is displayed")
    }

    // MARK: - Multiple Scenarios

    @Test("Parse feature with multiple scenarios")
    func multipleScenarios() throws {
        let source = """
            Feature: Auth
              Scenario: Login success
                Given valid credentials
                Then access granted

              Scenario: Login failure
                Given invalid credentials
                Then error displayed
            """
        let feature = try parser.parse(source)
        #expect(feature.children.count == 2)

        guard case .scenario(let first) = feature.children[0],
            case .scenario(let second) = feature.children[1]
        else {
            Issue.record("Expected two scenarios")
            return
        }
        #expect(first.title == "Login success")
        #expect(second.title == "Login failure")
    }

    // MARK: - And / But / Wildcard

    @Test("Parse And, But, and wildcard steps")
    func andButWildcard() throws {
        let source = """
            Feature: Cart
              Scenario: Add product
                Given an empty cart
                And a product catalog
                When I add a product
                But it is out of stock
                * something else
                Then cart is still empty
            """
        let feature = try parser.parse(source)
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps.count == 6)
        #expect(scenario.steps[1].keyword == .and)
        #expect(scenario.steps[3].keyword == .but)
        #expect(scenario.steps[4].keyword == .wildcard)
        #expect(scenario.steps[4].text == "something else")
    }

    // MARK: - Background

    @Test("Parse feature with background")
    func background() throws {
        let source = """
            Feature: Orders
              Background:
                Given a logged-in user
                And at least one existing order

              Scenario: View orders
                When I view my orders
                Then the list is displayed
            """
        let feature = try parser.parse(source)
        #expect(feature.background != nil)
        #expect(feature.background?.steps.count == 2)
        #expect(feature.background?.steps[0].keyword == .given)
        #expect(feature.background?.steps[0].text == "a logged-in user")
        #expect(feature.children.count == 1)
    }

    // MARK: - Description

    @Test("Parse feature description")
    func featureDescription() throws {
        let source = """
            Feature: Login
              As a user
              I want to log in
              So that I can access my account

              Scenario: Test
                Given something
                Then result
            """
        let feature = try parser.parse(source)
        #expect(feature.description != nil)
        #expect(feature.description?.contains("As a user") == true)
        #expect(feature.description?.contains("So that I can access my account") == true)
    }

    // MARK: - Comments

    @Test("Parse comments")
    func comments() throws {
        let source = """
            # This is a comment
            Feature: Login
              # Another comment
              Scenario: Test
                Given something
                Then result
            """
        let feature = try parser.parse(source)
        #expect(feature.comments.count == 2)
    }
}
