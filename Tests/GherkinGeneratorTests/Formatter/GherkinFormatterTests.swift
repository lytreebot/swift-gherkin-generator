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

@Suite("GherkinFormatter")
struct GherkinFormatterTests {

    @Test("Simple feature formatting")
    func simpleFeature() {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(
                    Scenario(
                        title: "Successful login",
                        steps: [
                            Step(keyword: .given, text: "a valid account"),
                            Step(keyword: .when, text: "the user logs in"),
                            Step(keyword: .then, text: "the dashboard is displayed")
                        ]
                    ))
            ]
        )

        let formatter = GherkinFormatter()
        let output = formatter.format(feature)

        #expect(output.contains("Feature: Login"))
        #expect(output.contains("Example: Successful login"))
        #expect(output.contains("Given a valid account"))
        #expect(output.contains("When the user logs in"))
        #expect(output.contains("Then the dashboard is displayed"))
    }

    @Test("French feature formatting")
    func frenchFeature() {
        let feature = Feature(
            title: "Authentification",
            language: .french,
            children: [
                .scenario(
                    Scenario(
                        title: "Connexion",
                        steps: [
                            Step(keyword: .given, text: "un compte valide"),
                            Step(keyword: .when, text: "je me connecte"),
                            Step(keyword: .then, text: "je suis connecté")
                        ]
                    ))
            ]
        )

        let formatter = GherkinFormatter()
        let output = formatter.format(feature)

        #expect(output.contains("# language: fr"))
        #expect(output.contains("Fonctionnalité: Authentification"))
        #expect(output.contains("Soit un compte valide"))
        #expect(output.contains("Quand je me connecte"))
        #expect(output.contains("Alors je suis connecté"))
    }

    @Test("Data table alignment")
    func dataTableAlignment() {
        let feature = Feature(
            title: "Pricing",
            children: [
                .scenario(
                    Scenario(
                        title: "Prices",
                        steps: [
                            Step(
                                keyword: .given,
                                text: "the following prices",
                                dataTable: DataTable(rows: [
                                    ["Quantity", "Price"],
                                    ["1-10", "10€"],
                                    ["11-50", "8€"]
                                ])
                            )
                        ]
                    ))
            ]
        )

        let formatter = GherkinFormatter()
        let output = formatter.format(feature)

        // Verify pipes are present (alignment details tested more thoroughly later)
        #expect(output.contains("|"))
        #expect(output.contains("Quantity"))
        #expect(output.contains("Price"))
    }

    @Test("Tags are included in output")
    func tagsInOutput() {
        let feature = Feature(
            title: "Payment",
            tags: [Tag("payment"), Tag("critical")],
            children: [
                .scenario(
                    Scenario(
                        title: "Credit card",
                        tags: [Tag("card")],
                        steps: [
                            Step(keyword: .given, text: "a cart"),
                            Step(keyword: .then, text: "payment done")
                        ]
                    ))
            ]
        )

        let formatter = GherkinFormatter()
        let output = formatter.format(feature)

        #expect(output.contains("@payment @critical"))
        #expect(output.contains("@card"))
    }
}
