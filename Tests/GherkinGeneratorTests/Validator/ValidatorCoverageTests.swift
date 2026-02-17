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

@Suite("Validator — Coverage")
struct ValidatorCoverageTests {

    private let validator = GherkinValidator()

    // MARK: - Outline Inside Feature (not in rules)

    @Test("Validator checks outline steps at feature level")
    func validateOutlineSteps() {
        let feature = Feature(
            title: "Outlines",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Missing Given",
                        steps: [
                            Step(keyword: .when, text: "action"),
                            Step(keyword: .then, text: "result")
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
        )

        let errors = validator.collectErrors(in: feature)
        let missingGiven = errors.filter {
            if case .missingGiven = $0 { return true }
            return false
        }
        #expect(!missingGiven.isEmpty)
    }

    // MARK: - CoherenceRule on Outline

    @Test("CoherenceRule detects duplicate steps in outline")
    func coherenceOnOutline() {
        let feature = Feature(
            title: "Duplicates",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Dup outline",
                        steps: [
                            Step(keyword: .given, text: "something"),
                            Step(keyword: .given, text: "something"),
                            Step(keyword: .then, text: "result")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [["x"], ["1"]]))
                        ]
                    ))
            ]
        )

        let errors = CoherenceRule().validate(feature)
        let duplicates = errors.filter {
            if case .duplicateConsecutiveStep = $0 { return true }
            return false
        }
        #expect(!duplicates.isEmpty)
    }

    // MARK: - TableConsistencyRule on Outline Examples

    @Test("TableConsistencyRule checks outline example tables")
    func tableConsistencyOnOutline() {
        let feature = Feature(
            title: "Tables",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Table check",
                        steps: [
                            Step(keyword: .given, text: "input <x>"),
                            Step(keyword: .then, text: "output <y>")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["x", "y"],
                                    ["1"]  // inconsistent column count
                                ]))
                        ]
                    ))
            ]
        )

        let errors = TableConsistencyRule().validate(feature)
        let inconsistent = errors.filter {
            if case .inconsistentTableColumns = $0 { return true }
            return false
        }
        #expect(!inconsistent.isEmpty)
    }
}
