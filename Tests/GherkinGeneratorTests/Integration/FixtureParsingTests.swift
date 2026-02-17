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

@Suite("Fixture Parsing")
struct FixtureParsingTests {

    private let parser = GherkinParser()

    // MARK: - Helpers

    private func fixtureURL(_ name: String) throws -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: nil) else {
            Issue.record("Fixture not found: \(name)")
            throw GherkinError.importFailed(path: name, reason: "Fixture not found")
        }
        return url
    }

    private func parseFixture(_ name: String) throws -> Feature {
        let url = try fixtureURL(name)
        let source = try String(contentsOf: url, encoding: .utf8)
        return try parser.parse(source)
    }

    // MARK: - Simple Feature

    @Test("Parse simple.feature")
    func parseSimple() throws {
        let feature = try parseFixture("simple.feature")

        #expect(feature.title == "User Authentication")
        #expect(feature.tags.isEmpty)
        #expect(feature.children.count == 1)

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.title == "Successful login with valid credentials")
        #expect(scenario.steps.count == 4)
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[1].keyword == .when)
        #expect(scenario.steps[2].keyword == .then)
        #expect(scenario.steps[3].keyword == .and)
    }

    // MARK: - Complex Feature

    @Test("Parse complex.feature — structure")
    func parseComplexStructure() throws {
        let feature = try parseFixture("complex.feature")

        #expect(feature.title == "Shopping Cart Management")
        #expect(feature.tags.count == 3)
        #expect(feature.tags.map(\.name).contains("e2e"))
        #expect(feature.tags.map(\.name).contains("smoke"))
        #expect(feature.tags.map(\.name).contains("cart"))
        #expect(feature.description != nil)
        #expect(feature.background != nil)
        #expect(feature.background?.steps.count == 3)
    }

    @Test("Parse complex.feature — scenarios count")
    func parseComplexScenarios() throws {
        let feature = try parseFixture("complex.feature")
        #expect(feature.children.count == 7)
    }

    @Test("Parse complex.feature — data table")
    func parseComplexDataTable() throws {
        let feature = try parseFixture("complex.feature")

        // The "Remove a product from the cart" scenario has a data table
        let removeScenario = feature.scenarios.first { $0.title == "Remove a product from the cart" }
        let table = try #require(removeScenario?.steps.first?.dataTable)
        #expect(table.rowCount == 4)  // header + 3 data rows
        #expect(table.columnCount == 3)
        #expect(table.headers == ["product", "quantity", "price"])
    }

    @Test("Parse complex.feature — doc string")
    func parseComplexDocString() throws {
        let feature = try parseFixture("complex.feature")

        let apiScenario = feature.scenarios.first { $0.title == "Verify cart contents via API" }
        let docStep = apiScenario?.steps.first { $0.docString != nil }
        let docString = try #require(docStep?.docString)
        #expect(docString.mediaType == "application/json")
        #expect(docString.content.contains("\"Wireless Headphones\""))
    }

    @Test("Parse complex.feature — scenario tags")
    func parseComplexScenarioTags() throws {
        let feature = try parseFixture("complex.feature")

        let happyPathScenarios = feature.scenarios.filter { $0.tags.map(\.name).contains("happy-path") }
        #expect(happyPathScenarios.count == 2)

        let apiScenarios = feature.scenarios.filter { $0.tags.map(\.name).contains("api") }
        #expect(apiScenarios.count == 2)
    }

    @Test("Parse complex.feature — comments")
    func parseComplexComments() throws {
        let feature = try parseFixture("complex.feature")
        #expect(!feature.comments.isEmpty)
    }

    // MARK: - Outline Feature

    @Test("Parse outline.feature — outlines")
    func parseOutlineFeature() throws {
        let feature = try parseFixture("outline.feature")

        #expect(feature.title == "Email Address Validation")
        #expect(feature.tags.count == 1)
        #expect(feature.tags[0].name == "validation")

        let outlines = feature.outlines
        #expect(outlines.count == 2)
    }

    @Test("Parse outline.feature — examples blocks")
    func parseOutlineExamples() throws {
        let feature = try parseFixture("outline.feature")

        let emailOutline = feature.outlines.first { $0.title == "Validate email format" }
        let outline = try #require(emailOutline)
        #expect(outline.examples.count == 2)

        let validExamples = outline.examples[0]
        #expect(validExamples.tags.map(\.name).contains("valid-emails"))
        #expect(validExamples.table.dataRows.count == 4)  // 4 valid emails

        let invalidExamples = outline.examples[1]
        #expect(invalidExamples.tags.map(\.name).contains("invalid-emails"))
        #expect(invalidExamples.table.dataRows.count == 5)  // 5 invalid emails
    }

    @Test("Parse outline.feature — placeholders in steps")
    func parseOutlinePlaceholders() throws {
        let feature = try parseFixture("outline.feature")
        let outline = try #require(feature.outlines.first)

        let hasPlaceholder = outline.steps.contains { $0.text.contains("<email>") }
        #expect(hasPlaceholder)
    }

    // MARK: - Rules Feature

    @Test("Parse rules.feature — rules structure")
    func parseRulesStructure() throws {
        let feature = try parseFixture("rules.feature")

        #expect(feature.title == "Order Pricing Engine")
        #expect(feature.background != nil)
        #expect(feature.rules.count == 3)
    }

    @Test("Parse rules.feature — rule backgrounds")
    func parseRuleBackgrounds() throws {
        let feature = try parseFixture("rules.feature")

        // Each rule should have its own background
        for rule in feature.rules {
            #expect(rule.background != nil, "Rule '\(rule.title)' should have a background")
        }
    }

    @Test("Parse rules.feature — rule children")
    func parseRuleChildren() throws {
        let feature = try parseFixture("rules.feature")

        let retailRule = feature.rules.first { $0.title.contains("Standard pricing") }
        let retail = try #require(retailRule)
        #expect(retail.children.count == 2)  // 2 scenarios

        let wholesaleRule = feature.rules.first { $0.title.contains("Volume discounts") }
        let wholesale = try #require(wholesaleRule)
        #expect(wholesale.children.count == 3)  // 3 scenarios

        let promoRule = feature.rules.first { $0.title.contains("Seasonal promotions") }
        let promo = try #require(promoRule)
        #expect(promo.children.count == 2)  // 2 scenarios
    }

    @Test("Parse rules.feature — feature-level tags")
    func parseRuleFeatureTags() throws {
        let feature = try parseFixture("rules.feature")

        #expect(feature.tags.map(\.name).contains("pricing"))
        #expect(feature.tags.map(\.name).contains("business-rules"))
    }

    // MARK: - French Feature

    @Test("Parse french.feature — language detection")
    func parseFrenchLanguage() throws {
        let feature = try parseFixture("french.feature")

        #expect(feature.language.code == "fr")
        #expect(feature.title == "Gestion des comptes utilisateurs")
    }

    @Test("Parse french.feature — structure")
    func parseFrenchStructure() throws {
        let feature = try parseFixture("french.feature")

        #expect(feature.background != nil)  // Contexte
        #expect(feature.tags.count == 2)
        #expect(feature.scenarios.count == 3)  // 3 Scénarios
        #expect(feature.outlines.count == 1)  // 1 Plan du Scénario
    }

    @Test("Parse french.feature — scenario outline examples")
    func parseFrenchOutline() throws {
        let feature = try parseFixture("french.feature")

        let outline = try #require(feature.outlines.first)
        #expect(outline.title == "Validation des rôles utilisateurs")
        #expect(outline.examples.count == 1)
        #expect(outline.examples[0].table.dataRows.count == 5)
    }

    // MARK: - German Feature

    @Test("Parse german.feature — language detection")
    func parseGermanLanguage() throws {
        let feature = try parseFixture("german.feature")

        #expect(feature.language.code == "de")
        #expect(feature.title == "Bestellverwaltung")
    }

    @Test("Parse german.feature — structure")
    func parseGermanStructure() throws {
        let feature = try parseFixture("german.feature")

        #expect(feature.background != nil)  // Grundlage
        #expect(feature.scenarios.count == 3)  // 3 Szenarios
        #expect(feature.tags.count == 2)
    }

    @Test("Parse german.feature — data table")
    func parseGermanDataTable() throws {
        let feature = try parseFixture("german.feature")

        let orderScenario = feature.scenarios.first { $0.title.contains("Neue Bestellung") }
        let scenario = try #require(orderScenario)
        let table = scenario.steps.compactMap(\.dataTable).first
        #expect(table != nil)
        #expect(table?.columnCount == 3)
    }

    // MARK: - Japanese Feature

    @Test("Parse japanese.feature — language detection")
    func parseJapaneseLanguage() throws {
        let feature = try parseFixture("japanese.feature")

        #expect(feature.language.code == "ja")
    }

    @Test("Parse japanese.feature — structure")
    func parseJapaneseStructure() throws {
        let feature = try parseFixture("japanese.feature")

        #expect(feature.background != nil)
        #expect(feature.children.count == 3)
    }

    // MARK: - Edge Cases Feature

    @Test("Parse edge-cases.feature — unicode")
    func parseEdgeCasesUnicode() throws {
        let feature = try parseFixture("edge-cases.feature")

        #expect(feature.title == "Edge Cases and Special Characters")

        let unicodeScenario = feature.scenarios.first { $0.title.contains("Unicode") }
        #expect(unicodeScenario != nil)
    }

    @Test("Parse edge-cases.feature — wildcard steps")
    func parseEdgeCasesWildcard() throws {
        let feature = try parseFixture("edge-cases.feature")

        let wildcardScenario = feature.scenarios.first { $0.title.contains("star keyword") }
        let scenario = try #require(wildcardScenario)
        let wildcardSteps = scenario.steps.filter { $0.keyword == .wildcard }
        #expect(wildcardSteps.count == 4)
    }

    @Test("Parse edge-cases.feature — multiple And/But steps")
    func parseEdgeCasesMultipleAndBut() throws {
        let feature = try parseFixture("edge-cases.feature")

        let multiScenario = feature.scenarios.first { $0.title.contains("Multiple consecutive") }
        let scenario = try #require(multiScenario)
        let andSteps = scenario.steps.filter { $0.keyword == .and }
        let butSteps = scenario.steps.filter { $0.keyword == .but }
        #expect(andSteps.count >= 4)
        #expect(butSteps.count >= 2)
    }

    @Test("Parse edge-cases.feature — doc string with XML")
    func parseEdgeCasesDocString() throws {
        let feature = try parseFixture("edge-cases.feature")

        let xmlScenario = feature.scenarios.first { $0.title.contains("Doc string") }
        let scenario = try #require(xmlScenario)
        let docStep = scenario.steps.first { $0.docString != nil }
        let docString = try #require(docStep?.docString)
        #expect(docString.mediaType == "xml")
        #expect(docString.content.contains("<?xml"))
    }

    // MARK: - Large Feature

    @Test("Parse large.feature — 52+ scenarios")
    func parseLargeFeature() throws {
        let feature = try parseFixture("large.feature")

        let totalChildren = feature.children.count
        #expect(totalChildren >= 52)
    }

    @Test("Parse large.feature — background")
    func parseLargeBackground() throws {
        let feature = try parseFixture("large.feature")

        #expect(feature.background != nil)
        #expect(feature.background?.steps.count == 2)
    }

}
