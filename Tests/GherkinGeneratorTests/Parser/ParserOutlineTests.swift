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

@Suite("GherkinParser - Outline")
struct GherkinParserOutlineTests {

    private let parser = GherkinParser()

    @Test("Parse scenario outline with examples")
    func scenarioOutline() throws {
        let source = """
            Feature: Email Validation
              Scenario Outline: Email format
                Given the email <email>
                When I validate the format
                Then the result is <valid>

                Examples:
                  | email            | valid |
                  | test@example.com | true  |
                  | invalid          | false |
            """
        let feature = try parser.parse(source)
        guard case .outline(let outline) = feature.children[0] else {
            Issue.record("Expected outline")
            return
        }
        #expect(outline.title == "Email format")
        #expect(outline.steps.count == 3)
        #expect(outline.examples.count == 1)
        #expect(outline.examples[0].table.rowCount == 3)
        #expect(outline.examples[0].table.headers == ["email", "valid"])
    }

    @Test("Parse Scenario Template as Scenario Outline")
    func scenarioTemplate() throws {
        let source = """
            Feature: Template test
              Scenario Template: Email check
                Given the email <email>
                Then the result is <valid>

                Examples:
                  | email | valid |
                  | a@b.c | true  |
            """
        let feature = try parser.parse(source)
        guard case .outline(let outline) = feature.children[0] else {
            Issue.record("Expected outline")
            return
        }
        #expect(outline.title == "Email check")
    }
}
