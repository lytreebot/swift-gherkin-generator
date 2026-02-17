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

@Suite("Model Types — Coverage")
struct ModelCoverageTests {

    // MARK: - Comment.description

    @Test("Comment CustomStringConvertible")
    func commentDescription() {
        let comment = Comment(text: "This is a test")
        #expect(comment.description == "# This is a test")
    }

    @Test("Comment from # prefix — description")
    func commentFromPrefixDescription() {
        let comment = Comment(text: "# Already prefixed")
        #expect(comment.description == "# Already prefixed")
    }

    // MARK: - Tag.description

    @Test("Tag CustomStringConvertible")
    func tagDescription() {
        let tag = Tag("smoke")
        #expect(tag.description == "@smoke")
    }

    @Test("Tag from @-prefixed — description")
    func tagFromPrefixDescription() {
        let tag = Tag("@critical")
        #expect(tag.description == "@critical")
    }

    // MARK: - GherkinLanguage.hash

    @Test("GherkinLanguage hashing — same code, same hash")
    func languageHashEquality() {
        let lang1 = GherkinLanguage.english
        let lang2 = GherkinLanguage.english
        #expect(lang1.hashValue == lang2.hashValue)
    }

    @Test("GherkinLanguage hashing — different codes, different hash")
    func languageHashDifference() {
        let english = GherkinLanguage.english
        let french = GherkinLanguage.french
        #expect(english.hashValue != french.hashValue)
    }

    @Test("GherkinLanguage usable as Set element")
    func languageInSet() {
        var languages: Set<GherkinLanguage> = []
        languages.insert(.english)
        languages.insert(.french)
        languages.insert(.english)  // duplicate

        #expect(languages.count == 2)
    }

    // MARK: - Feature.rules computed property with no rules

    @Test("Feature.rules returns empty when no rules")
    func featureRulesEmpty() {
        let feature = Feature(
            title: "No rules",
            children: [
                .scenario(Scenario(title: "Test", steps: [Step(keyword: .given, text: "x")]))
            ]
        )
        #expect(feature.rules.isEmpty)
    }
}
