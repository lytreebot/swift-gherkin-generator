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

@Suite("Model Types")
struct ModelTests {

    // MARK: - Tag

    @Test("Tag strips @ prefix")
    func tagStripsPrefix() {
        let tag = Tag("@smoke")
        #expect(tag.name == "smoke")
        #expect(tag.rawValue == "@smoke")
    }

    @Test("Tag without @ prefix")
    func tagWithoutPrefix() {
        let tag = Tag("critical")
        #expect(tag.name == "critical")
        #expect(tag.rawValue == "@critical")
    }

    @Test("Tag from string literal")
    func tagStringLiteral() {
        let tag: GherkinGenerator.Tag = "@regression"
        #expect(tag.name == "regression")
    }

    // MARK: - DataTable

    @Test("DataTable properties")
    func dataTableProperties() {
        let table = DataTable(rows: [
            ["name", "role"],
            ["Alice", "admin"],
            ["Bob", "user"]
        ])

        #expect(table.columnCount == 2)
        #expect(table.rowCount == 3)
        #expect(table.headers == ["name", "role"])
        #expect(table.dataRows.count == 2)
        #expect(!table.isEmpty)
    }

    @Test("Empty DataTable")
    func emptyDataTable() {
        let table = DataTable(rows: [])
        #expect(table.isEmpty)
        #expect(table.columnCount == 0)
        #expect(table.headers == nil)
        #expect(table.dataRows.isEmpty)
    }

    // MARK: - Step

    @Test("Step with data table")
    func stepWithTable() {
        let table = DataTable(rows: [["a", "b"]])
        let step = Step(keyword: .given, text: "data")
            .withTable(table)

        #expect(step.dataTable != nil)
        #expect(step.docString == nil)
    }

    @Test("Step with doc string")
    func stepWithDocString() {
        let doc = DocString(content: "{}", mediaType: "application/json")
        let step = Step(keyword: .given, text: "payload")
            .withDocString(doc)

        #expect(step.docString != nil)
        #expect(step.docString?.mediaType == "application/json")
    }

    // MARK: - Comment

    @Test("Comment strips # prefix")
    func commentStripsPrefix() {
        let comment = Comment(text: "# This is a comment")
        #expect(comment.text == "This is a comment")
    }

    @Test("Comment without # prefix")
    func commentWithoutPrefix() {
        let comment = Comment(text: "This is a comment")
        #expect(comment.text == "This is a comment")
    }

    // MARK: - Sendable Conformance

    @Test("All model types are Sendable")
    func sendableConformance() {
        // Compile-time check — these must all be Sendable
        let _: any Sendable = Step(keyword: .given, text: "test")
        let _: any Sendable = Tag("test")
        let _: any Sendable = DataTable(rows: [])
        let _: any Sendable = DocString(content: "")
        let _: any Sendable = Examples(table: DataTable(rows: []))
        let _: any Sendable = Background()
        let _: any Sendable = Scenario(title: "test")
        let _: any Sendable = ScenarioOutline(title: "test")
        let _: any Sendable = Rule(title: "test")
        let _: any Sendable = Feature(title: "test")
        let _: any Sendable = Comment(text: "test")
        let _: any Sendable = GherkinLanguage.english
    }
}
