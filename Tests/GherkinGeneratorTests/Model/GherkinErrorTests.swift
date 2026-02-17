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

@Suite("GherkinError — errorDescription")
struct GherkinErrorTests {

    @Test("missingGiven has descriptive message")
    func missingGiven() {
        let error = GherkinError.missingGiven(scenario: "Login")
        #expect(error.errorDescription?.contains("Login") == true)
        #expect(error.errorDescription?.contains("Given") == true)
    }

    @Test("missingThen has descriptive message")
    func missingThen() {
        let error = GherkinError.missingThen(scenario: "Login")
        #expect(error.errorDescription?.contains("Login") == true)
        #expect(error.errorDescription?.contains("Then") == true)
    }

    @Test("duplicateConsecutiveStep has descriptive message")
    func duplicateConsecutiveStep() {
        let error = GherkinError.duplicateConsecutiveStep(step: "click button", scenario: "Test")
        #expect(error.errorDescription?.contains("click button") == true)
        #expect(error.errorDescription?.contains("Test") == true)
    }

    @Test("invalidTagFormat has descriptive message")
    func invalidTagFormat() {
        let error = GherkinError.invalidTagFormat(tag: "bad tag")
        #expect(error.errorDescription?.contains("bad tag") == true)
    }

    @Test("inconsistentTableColumns has descriptive message")
    func inconsistentTableColumns() {
        let error = GherkinError.inconsistentTableColumns(expected: 3, found: 2, row: 1)
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("3"))
        #expect(desc.contains("2"))
        #expect(desc.contains("1"))
    }

    @Test("emptyTableCell has descriptive message")
    func emptyTableCell() {
        let error = GherkinError.emptyTableCell(row: 2, column: 1)
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("2"))
        #expect(desc.contains("1"))
    }

    @Test("undefinedPlaceholder has descriptive message")
    func undefinedPlaceholder() {
        let error = GherkinError.undefinedPlaceholder(placeholder: "email", scenario: "Validate")
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("email"))
        #expect(desc.contains("Validate"))
    }

    @Test("emptyFeature has descriptive message")
    func emptyFeature() {
        let error = GherkinError.emptyFeature
        #expect(error.errorDescription?.contains("no scenarios") == true)
    }

    @Test("emptyTitle has descriptive message")
    func emptyTitle() {
        let error = GherkinError.emptyTitle
        #expect(error.errorDescription?.contains("title") == true)
    }

    @Test("stepWithoutScenario has descriptive message")
    func stepWithoutScenario() {
        let error = GherkinError.stepWithoutScenario
        #expect(error.errorDescription?.contains("scenario") == true)
    }

    @Test("examplesOnNonOutline has descriptive message")
    func examplesOnNonOutline() {
        let error = GherkinError.examplesOnNonOutline(scenario: "Login")
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("Login"))
        #expect(desc.contains("addOutline"))
    }

    @Test("backgroundAfterScenario has descriptive message")
    func backgroundAfterScenario() {
        let error = GherkinError.backgroundAfterScenario
        #expect(error.errorDescription?.contains("Background") == true)
    }

    @Test("syntaxError has descriptive message")
    func syntaxError() {
        let error = GherkinError.syntaxError(message: "unexpected token", line: 42)
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("unexpected token"))
        #expect(desc.contains("42"))
    }

    @Test("unexpectedKeyword has descriptive message")
    func unexpectedKeyword() {
        let error = GherkinError.unexpectedKeyword(keyword: "Fonctionnalité", line: 10)
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("Fonctionnalité"))
        #expect(desc.contains("10"))
    }

    @Test("unsupportedLanguage has descriptive message")
    func unsupportedLanguage() {
        let error = GherkinError.unsupportedLanguage(language: "zz")
        #expect(error.errorDescription?.contains("zz") == true)
    }

    @Test("exportFailed has descriptive message")
    func exportFailed() {
        let error = GherkinError.exportFailed(path: "/tmp/out.feature", reason: "disk full")
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("/tmp/out.feature"))
        #expect(desc.contains("disk full"))
    }

    @Test("importFailed has descriptive message")
    func importFailed() {
        let error = GherkinError.importFailed(path: "/tmp/in.csv", reason: "not found")
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("/tmp/in.csv"))
        #expect(desc.contains("not found"))
    }

    @Test("unsupportedFormat has descriptive message")
    func unsupportedFormat() {
        let error = GherkinError.unsupportedFormat(format: "xml")
        #expect(error.errorDescription?.contains("xml") == true)
    }
}
