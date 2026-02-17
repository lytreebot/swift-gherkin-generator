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

@Suite("TagFormatRule")
struct TagFormatRuleTests {

    private let rule = TagFormatRule()

    @Test("Valid tags pass")
    func validTags() {
        let feature = Feature(
            title: "Payment",
            tags: [Tag("smoke"), Tag("critical")],
            children: [
                .scenario(
                    Scenario(
                        title: "Pay",
                        tags: [Tag("card")],
                        steps: [
                            Step(keyword: .given, text: "a cart"),
                            Step(keyword: .then, text: "paid")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Empty tag name reports error")
    func emptyTagName() {
        let feature = Feature(
            title: "Test",
            tags: [Tag("")],
            children: []
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .invalidTagFormat(tag: "@"))
    }

    @Test("Tag with spaces reports error")
    func tagWithSpaces() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Scenario",
                        tags: [Tag("has space")],
                        steps: []
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .invalidTagFormat(tag: "@has space"))
    }

    @Test("Invalid tags on rule are detected")
    func invalidTagOnRule() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(
                    Rule(
                        title: "My rule",
                        tags: [Tag("ok"), Tag("not valid")]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .invalidTagFormat(tag: "@not valid"))
    }

    @Test("Invalid tags on examples are detected")
    func invalidTagOnExamples() {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Outline",
                        steps: [
                            Step(keyword: .given, text: "something <x>"),
                            Step(keyword: .then, text: "result <y>")
                        ],
                        examples: [
                            Examples(
                                tags: [Tag("bad tag")],
                                table: DataTable(rows: [["x", "y"], ["1", "2"]])
                            )
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .invalidTagFormat(tag: "@bad tag"))
    }

    @Test("Invalid tags on scenarios inside rules are detected")
    func invalidTagOnScenarioInsideRule() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(
                    Rule(
                        title: "Rule",
                        children: [
                            .scenario(
                                Scenario(
                                    title: "Nested",
                                    tags: [Tag("has space")],
                                    steps: []
                                ))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
    }

    @Test("Invalid tags on outlines inside rules are detected")
    func invalidTagOnOutlineInsideRule() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(
                    Rule(
                        title: "Rule",
                        children: [
                            .outline(
                                ScenarioOutline(
                                    title: "Outline in rule",
                                    tags: [Tag("bad tag")],
                                    examples: [
                                        Examples(
                                            tags: [Tag("another bad")],
                                            table: DataTable(rows: [["a"], ["b"]])
                                        )
                                    ]
                                ))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
    }
}
