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

@Suite("StructureRule")
struct StructureRuleTests {

    private let rule = StructureRule()

    @Test("Valid scenario with Given and Then passes")
    func validScenario() {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(
                    Scenario(
                        title: "Success",
                        steps: [
                            Step(keyword: .given, text: "a valid account"),
                            Step(keyword: .when, text: "the user logs in"),
                            Step(keyword: .then, text: "dashboard is displayed")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Scenario missing Given reports error")
    func missingGiven() {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(
                    Scenario(
                        title: "No given",
                        steps: [
                            Step(keyword: .when, text: "the user logs in"),
                            Step(keyword: .then, text: "dashboard is displayed")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .missingGiven(scenario: "No given"))
    }

    @Test("Scenario missing Then reports error")
    func missingThen() {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(
                    Scenario(
                        title: "No then",
                        steps: [
                            Step(keyword: .given, text: "a valid account"),
                            Step(keyword: .when, text: "the user logs in")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .missingThen(scenario: "No then"))
    }

    @Test("Scenario missing both Given and Then reports two errors")
    func missingBoth() {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(
                    Scenario(
                        title: "Empty-ish",
                        steps: [
                            Step(keyword: .when, text: "something happens")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
        #expect(errors.contains(.missingGiven(scenario: "Empty-ish")))
        #expect(errors.contains(.missingThen(scenario: "Empty-ish")))
    }

    @Test("And after Given counts as Given")
    func andAfterGiven() {
        let feature = Feature(
            title: "Setup",
            children: [
                .scenario(
                    Scenario(
                        title: "With And",
                        steps: [
                            Step(keyword: .given, text: "a user"),
                            Step(keyword: .and, text: "a product"),
                            Step(keyword: .then, text: "the page loads")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("But after Then counts as Then")
    func butAfterThen() {
        let feature = Feature(
            title: "Validation",
            children: [
                .scenario(
                    Scenario(
                        title: "With But",
                        steps: [
                            Step(keyword: .given, text: "a form"),
                            Step(keyword: .then, text: "success message shown"),
                            Step(keyword: .but, text: "no redirect happens")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Outline is also validated")
    func outlineValidated() {
        let feature = Feature(
            title: "Email",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Missing steps",
                        steps: [
                            Step(keyword: .when, text: "I validate <email>")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
        #expect(errors.contains(.missingGiven(scenario: "Missing steps")))
        #expect(errors.contains(.missingThen(scenario: "Missing steps")))
    }

    @Test("Scenarios inside rules are validated")
    func scenariosInsideRule() {
        let feature = Feature(
            title: "Discount",
            children: [
                .rule(
                    Rule(
                        title: "Premium rules",
                        children: [
                            .scenario(
                                Scenario(
                                    title: "No given in rule",
                                    steps: [
                                        Step(keyword: .when, text: "I buy"),
                                        Step(keyword: .then, text: "discount applied")
                                    ]
                                ))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .missingGiven(scenario: "No given in rule"))
    }

    @Test("Background is not checked for Given/Then")
    func backgroundNotChecked() {
        let feature = Feature(
            title: "Orders",
            background: Background(steps: [
                Step(keyword: .given, text: "a logged-in user")
            ]),
            children: [
                .scenario(
                    Scenario(
                        title: "View orders",
                        steps: [
                            Step(keyword: .given, text: "existing orders"),
                            Step(keyword: .when, text: "I view my orders"),
                            Step(keyword: .then, text: "the list is displayed")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }
}
