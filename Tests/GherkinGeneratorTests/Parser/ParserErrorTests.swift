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

@Suite("GherkinParser - Errors")
struct GherkinParserErrorTests {

    private let parser = GherkinParser()

    // MARK: - Syntax Errors

    @Test("Missing Feature keyword throws syntax error")
    func missingSyntaxError() {
        #expect(throws: GherkinError.self) {
            try parser.parse("Scenario: No feature")
        }
    }

    @Test("Unexpected line in feature body throws error")
    func unexpectedLineInBody() {
        let source = """
            Feature: Test
              Scenario: Valid
                Given something
                Then result

              this is not a valid keyword or tag
            """
        #expect(throws: GherkinError.self) {
            try parser.parse(source)
        }
    }

    @Test("Empty source throws syntax error")
    func emptySource() {
        #expect(throws: GherkinError.self) {
            try parser.parse("")
        }
    }

    // MARK: - File Import Error

    @Test("Import nonexistent file throws importFailed")
    func nonexistentFile() {
        #expect(throws: GherkinError.self) {
            try parser.parse(contentsOfFile: "/nonexistent/path.feature")
        }
    }
}
