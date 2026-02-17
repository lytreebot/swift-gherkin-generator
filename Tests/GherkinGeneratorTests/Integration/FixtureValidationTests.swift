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

@Suite("Fixture Validation")
struct FixtureValidationTests {

    private let parser = GherkinParser()
    private let validator = GherkinValidator()

    // MARK: - Helpers

    private func parseFixture(_ name: String) throws -> Feature {
        guard let url = Bundle.module.url(forResource: name, withExtension: nil) else {
            throw GherkinError.importFailed(path: name, reason: "Fixture not found")
        }
        let source = try String(contentsOf: url, encoding: .utf8)
        return try parser.parse(source)
    }

    // MARK: - Valid Features Should Pass Validation

    @Test(
        "Valid fixtures pass validation",
        arguments: [
            "simple.feature",
            "complex.feature",
            "rules.feature",
            "large.feature"
        ]
    )
    func validFeaturesPass(fixture: String) throws {
        let feature = try parseFixture(fixture)
        let errors = validator.collectErrors(in: feature)
        #expect(errors.isEmpty, "Expected no validation errors for \(fixture), got: \(errors)")
    }

    // MARK: - Multilanguage Features

    @Test(
        "Multilanguage fixtures parse without errors",
        arguments: [
            "french.feature",
            "german.feature",
            "japanese.feature"
        ]
    )
    func multilangFeaturesParseSuccessfully(fixture: String) throws {
        let feature = try parseFixture(fixture)
        #expect(!feature.title.isEmpty)
        #expect(!feature.children.isEmpty)
    }

    // MARK: - Structure Validation

    @Test("simple.feature has valid structure")
    func simpleStructure() throws {
        let feature = try parseFixture("simple.feature")
        let errors = StructureRule().validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("complex.feature has valid structure")
    func complexStructure() throws {
        let feature = try parseFixture("complex.feature")
        let errors = StructureRule().validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("rules.feature has valid structure")
    func rulesStructure() throws {
        let feature = try parseFixture("rules.feature")
        let errors = StructureRule().validate(feature)
        #expect(errors.isEmpty)
    }

    // MARK: - Tag Validation

    @Test("complex.feature has valid tags")
    func complexTagFormat() throws {
        let feature = try parseFixture("complex.feature")
        let errors = TagFormatRule().validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("outline.feature has valid example tags")
    func outlineExampleTags() throws {
        let feature = try parseFixture("outline.feature")
        let errors = TagFormatRule().validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("rules.feature has valid tags")
    func rulesTagFormat() throws {
        let feature = try parseFixture("rules.feature")
        let errors = TagFormatRule().validate(feature)
        #expect(errors.isEmpty)
    }

    // MARK: - Table Consistency

    @Test("complex.feature has consistent tables")
    func complexTableConsistency() throws {
        let feature = try parseFixture("complex.feature")
        let errors = TableConsistencyRule().validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("outline.feature — empty cells in valid emails detected")
    func outlineTableEmptyCells() throws {
        let feature = try parseFixture("outline.feature")
        let errors = TableConsistencyRule().validate(feature)
        // Valid email examples have empty "message" column — expected
        let emptyCellErrors = errors.filter {
            if case .emptyTableCell = $0 { return true }
            return false
        }
        #expect(!emptyCellErrors.isEmpty)
    }

    // MARK: - Outline Placeholder Validation

    @Test("outline.feature placeholders match examples")
    func outlinePlaceholders() throws {
        let feature = try parseFixture("outline.feature")
        let errors = OutlinePlaceholderRule().validate(feature)
        #expect(errors.isEmpty)
    }

    // MARK: - Invalid Structure Detection

    @Test("invalid-structure.feature has validation errors")
    func invalidStructureDetected() throws {
        let feature = try parseFixture("invalid-structure.feature")
        let errors = validator.collectErrors(in: feature)
        #expect(!errors.isEmpty, "Expected validation errors for invalid-structure.feature")
    }

    @Test("invalid-structure.feature — missing Given detected")
    func missingGivenDetected() throws {
        let feature = try parseFixture("invalid-structure.feature")
        let errors = StructureRule().validate(feature)
        let missingGivenErrors = errors.filter {
            if case .missingGiven = $0 { return true }
            return false
        }
        #expect(!missingGivenErrors.isEmpty)
    }

    @Test("invalid-structure.feature — missing Then detected")
    func missingThenDetected() throws {
        let feature = try parseFixture("invalid-structure.feature")
        let errors = StructureRule().validate(feature)
        let missingThenErrors = errors.filter {
            if case .missingThen = $0 { return true }
            return false
        }
        #expect(!missingThenErrors.isEmpty)
    }

    @Test("invalid-structure.feature — empty scenario detected")
    func emptyScenarioDetected() throws {
        let feature = try parseFixture("invalid-structure.feature")
        let errors = StructureRule().validate(feature)
        // Empty scenario = missing both Given and Then
        #expect(errors.count >= 2)
    }

    // MARK: - Coherence Rule

    @Test("No duplicate consecutive steps in valid fixtures")
    func noDuplicateSteps() throws {
        let feature = try parseFixture("complex.feature")
        let errors = CoherenceRule().validate(feature)
        #expect(errors.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("edge-cases.feature — empty table cells detected")
    func edgeCasesEmptyCells() throws {
        let feature = try parseFixture("edge-cases.feature")
        let errors = TableConsistencyRule().validate(feature)
        // The edge-cases feature has deliberately empty cells in the data table
        let emptyCellErrors = errors.filter {
            if case .emptyTableCell = $0 { return true }
            return false
        }
        #expect(!emptyCellErrors.isEmpty)
    }
}
