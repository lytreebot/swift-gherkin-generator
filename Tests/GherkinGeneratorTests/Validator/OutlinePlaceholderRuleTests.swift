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

@Suite("OutlinePlaceholderRule")
struct OutlinePlaceholderRuleTests {

    private let rule = OutlinePlaceholderRule()

    @Test("All placeholders defined passes")
    func allDefined() {
        let feature = Feature(
            title: "Email",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Validation",
                        steps: [
                            Step(keyword: .given, text: "the email <email>"),
                            Step(keyword: .when, text: "I validate"),
                            Step(keyword: .then, text: "the result is <valid>")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["email", "valid"],
                                    ["test@example.com", "true"],
                                    ["invalid", "false"]
                                ]))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Undefined placeholder reports error")
    func undefinedPlaceholder() {
        let feature = Feature(
            title: "Email",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Missing col",
                        steps: [
                            Step(keyword: .given, text: "the email <email>"),
                            Step(keyword: .then, text: "the result is <valid>")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["email"],
                                    ["test@example.com"]
                                ]))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .undefinedPlaceholder(placeholder: "valid", scenario: "Missing col"))
    }

    @Test("No placeholders passes")
    func noPlaceholders() {
        let feature = Feature(
            title: "Simple",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "No placeholders",
                        steps: [
                            Step(keyword: .given, text: "something"),
                            Step(keyword: .then, text: "result")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["a"],
                                    ["b"]
                                ]))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Multiple undefined placeholders reported")
    func multipleUndefined() {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Multi",
                        steps: [
                            Step(keyword: .given, text: "<a> and <b> and <c>"),
                            Step(keyword: .then, text: "done")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["a"],
                                    ["1"]
                                ]))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
        #expect(errors.contains(.undefinedPlaceholder(placeholder: "b", scenario: "Multi")))
        #expect(errors.contains(.undefinedPlaceholder(placeholder: "c", scenario: "Multi")))
    }

    @Test("Placeholders defined across multiple examples blocks passes")
    func multipleExamplesBlocks() {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Split",
                        steps: [
                            Step(keyword: .given, text: "<a> and <b>"),
                            Step(keyword: .then, text: "done")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["a"],
                                    ["1"]
                                ])),
                            Examples(
                                table: DataTable(rows: [
                                    ["b"],
                                    ["2"]
                                ]))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Outlines inside rules are validated")
    func outlineInRule() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(
                    Rule(
                        title: "Rule",
                        children: [
                            .outline(
                                ScenarioOutline(
                                    title: "In rule",
                                    steps: [
                                        Step(keyword: .given, text: "<x>"),
                                        Step(keyword: .then, text: "<y>")
                                    ],
                                    examples: [
                                        Examples(
                                            table: DataTable(rows: [
                                                ["x"],
                                                ["1"]
                                            ]))
                                    ]
                                ))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .undefinedPlaceholder(placeholder: "y", scenario: "In rule"))
    }

    @Test("Regular scenarios are ignored")
    func regularScenarioIgnored() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Not outline",
                        steps: [
                            Step(keyword: .given, text: "something <looks like placeholder>"),
                            Step(keyword: .then, text: "ok")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }
}
