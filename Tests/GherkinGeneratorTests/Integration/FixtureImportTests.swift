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

@Suite("Fixture Import (CSV, JSON, Plain Text)")
struct FixtureImportTests {

    // MARK: - Helpers

    private func fixtureURL(_ name: String) throws -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: nil) else {
            Issue.record("Fixture not found: \(name)")
            throw GherkinError.importFailed(path: name, reason: "Fixture not found")
        }
        return url
    }

    // MARK: - CSV Import

    @Test("Parse scenarios.csv — comma delimiter")
    func parseCSVComma() throws {
        let url = try fixtureURL("scenarios.csv")
        let source = try String(contentsOf: url, encoding: .utf8)

        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then",
            tagColumn: "Tags"
        )
        let csvParser = CSVParser(configuration: config)
        let feature = try csvParser.parse(source, featureTitle: "User Authentication")

        #expect(feature.title == "User Authentication")
        #expect(feature.children.count == 6)
    }

    @Test("Parse scenarios.csv — scenario structure")
    func parseCSVScenarioStructure() throws {
        let url = try fixtureURL("scenarios.csv")
        let source = try String(contentsOf: url, encoding: .utf8)

        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then",
            tagColumn: "Tags"
        )
        let csvParser = CSVParser(configuration: config)
        let feature = try csvParser.parse(source, featureTitle: "Auth")

        guard case .scenario(let first) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(first.title == "User login")
        #expect(first.steps.count == 3)
        #expect(first.steps[0].keyword == .given)
        #expect(first.steps[1].keyword == .when)
        #expect(first.steps[2].keyword == .then)
        #expect(!first.tags.isEmpty)
    }

    @Test("Parse semicolon.csv — semicolon delimiter")
    func parseCSVSemicolon() throws {
        let url = try fixtureURL("semicolon.csv")
        let source = try String(contentsOf: url, encoding: .utf8)

        let config = CSVImportConfiguration(
            delimiter: ";",
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then",
            tagColumn: "Tags"
        )
        let csvParser = CSVParser(configuration: config)
        let feature = try csvParser.parse(source, featureTitle: "Shopping Cart")

        #expect(feature.title == "Shopping Cart")
        #expect(feature.children.count == 4)
    }

    // MARK: - JSON Import

    @Test("Parse simple-feature.json")
    func parseSimpleJSON() throws {
        let url = try fixtureURL("simple-feature.json")
        let data = try Data(contentsOf: url)
        let jsonParser = JSONFeatureParser()
        let feature = try jsonParser.parse(data: data)

        #expect(feature.title == "User Authentication")
        #expect(feature.tags.count == 1)
        #expect(feature.children.count == 1)
    }

    @Test("Parse complex-feature.json")
    func parseComplexJSON() throws {
        let url = try fixtureURL("complex-feature.json")
        let data = try Data(contentsOf: url)
        let jsonParser = JSONFeatureParser()
        let feature = try jsonParser.parse(data: data)

        #expect(feature.title == "Shopping Cart Management")
        #expect(feature.tags.count == 3)
        #expect(feature.background != nil)
        #expect(feature.children.count == 3)
    }

    @Test("Parse complex-feature.json — data table preserved")
    func parseComplexJSONDataTable() throws {
        let url = try fixtureURL("complex-feature.json")
        let data = try Data(contentsOf: url)
        let jsonParser = JSONFeatureParser()
        let feature = try jsonParser.parse(data: data)

        let removeScenario = feature.scenarios.first { $0.title.contains("Remove") }
        let table = removeScenario?.steps.first?.dataTable
        #expect(table != nil)
        #expect(table?.rowCount == 3)
    }

    @Test("Parse complex-feature.json — doc string preserved")
    func parseComplexJSONDocString() throws {
        let url = try fixtureURL("complex-feature.json")
        let data = try Data(contentsOf: url)
        let jsonParser = JSONFeatureParser()
        let feature = try jsonParser.parse(data: data)

        let apiScenario = feature.scenarios.first { $0.title.contains("API") }
        let docStep = apiScenario?.steps.first { $0.docString != nil }
        #expect(docStep?.docString?.mediaType == "application/json")
    }

    // MARK: - Plain Text Import

    @Test("Parse steps.txt")
    func parsePlainText() throws {
        let url = try fixtureURL("steps.txt")
        let source = try String(contentsOf: url, encoding: .utf8)

        let textParser = PlainTextParser()
        let feature = try textParser.parse(source)

        #expect(feature.title == "Inventory Management")
        #expect(feature.children.count == 3)
    }

    @Test("Parse steps.txt — scenario steps")
    func parsePlainTextSteps() throws {
        let url = try fixtureURL("steps.txt")
        let source = try String(contentsOf: url, encoding: .utf8)

        let textParser = PlainTextParser()
        let feature = try textParser.parse(source)

        guard case .scenario(let first) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(first.title == "Check product availability")
        #expect(first.steps.count == 5)
        #expect(first.steps[0].keyword == .given)
        #expect(first.steps[1].keyword == .and)
        #expect(first.steps[2].keyword == .when)
        #expect(first.steps[3].keyword == .then)
        #expect(first.steps[4].keyword == .and)
    }

    @Test("Parse steps.txt — But keyword")
    func parsePlainTextButKeyword() throws {
        let url = try fixtureURL("steps.txt")
        let source = try String(contentsOf: url, encoding: .utf8)

        let textParser = PlainTextParser()
        let feature = try textParser.parse(source)

        guard case .scenario(let second) = feature.children[1] else {
            Issue.record("Expected scenario")
            return
        }
        let butSteps = second.steps.filter { $0.keyword == .but }
        #expect(butSteps.count == 1)
    }
}
