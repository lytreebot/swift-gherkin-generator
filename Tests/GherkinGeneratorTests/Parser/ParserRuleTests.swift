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

@Suite("GherkinParser - Rules")
struct GherkinParserRuleTests {

    private let parser = GherkinParser()

    @Test("Parse feature with rule")
    func rule() throws {
        let source = """
            Feature: Discount
              Rule: Premium customers
                Scenario: 10% discount
                  Given a premium customer
                  When they buy over 100
                  Then 10% discount applied

                Scenario: Free shipping
                  Given a premium customer
                  When order over 50
                  Then shipping is free
            """
        let feature = try parser.parse(source)
        guard case .rule(let rule) = feature.children[0] else {
            Issue.record("Expected rule")
            return
        }
        #expect(rule.title == "Premium customers")
        #expect(rule.children.count == 2)
    }

    @Test("Parse rule with background")
    func ruleWithBackground() throws {
        let source = """
            Feature: Discount
              Rule: Premium rules
                Background:
                  Given a premium customer

                Scenario: Discount
                  When they buy over 100
                  Then 10% discount applied
            """
        let feature = try parser.parse(source)
        guard case .rule(let rule) = feature.children[0] else {
            Issue.record("Expected rule")
            return
        }
        #expect(rule.background != nil)
        #expect(rule.background?.steps.count == 1)
        #expect(rule.children.count == 1)
    }

    @Test("Parse rule with tags")
    func ruleWithTags() throws {
        let source = """
            Feature: Discount
              @premium
              Rule: Premium rules
                Scenario: Test
                  Given something
                  Then result
            """
        let feature = try parser.parse(source)
        guard case .rule(let rule) = feature.children[0] else {
            Issue.record("Expected rule")
            return
        }
        #expect(rule.tags.count == 1)
        #expect(rule.tags[0].name == "premium")
    }
}
