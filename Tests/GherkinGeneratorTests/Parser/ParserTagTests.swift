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

@Suite("GherkinParser - Tags")
struct GherkinParserTagTests {

    private let parser = GherkinParser()

    @Test("Parse feature-level and scenario-level tags")
    func tags() throws {
        let source = """
            @smoke @critical
            Feature: Payment

              @card @slow
              Scenario: Credit card
                Given a cart
                Then payment processed
            """
        let feature = try parser.parse(source)
        #expect(feature.tags.count == 2)
        #expect(feature.tags[0].name == "smoke")
        #expect(feature.tags[1].name == "critical")

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.tags.count == 2)
        #expect(scenario.tags[0].name == "card")
        #expect(scenario.tags[1].name == "slow")
    }
}
