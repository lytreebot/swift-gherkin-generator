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

@Suite("GherkinExporter — Coverage")
struct ExporterCoverageTests {

    private let exporter = GherkinExporter()

    // MARK: - Markdown Rule with Tags and Outlines

    @Test("Markdown export — rule with tags")
    func markdownRuleWithTags() throws {
        let feature = Feature(
            title: "Pricing",
            children: [
                .rule(
                    Rule(
                        title: "Discounts",
                        tags: [Tag("pricing"), Tag("discount")],
                        description: "Pricing rules for discounts",
                        background: Background(steps: [
                            Step(keyword: .given, text: "a customer account")
                        ]),
                        children: [
                            .scenario(
                                Scenario(
                                    title: "10% off",
                                    steps: [
                                        Step(keyword: .given, text: "10 items"),
                                        Step(keyword: .then, text: "10% discount")
                                    ]
                                )),
                            .outline(
                                ScenarioOutline(
                                    title: "Discount for <qty>",
                                    steps: [
                                        Step(keyword: .given, text: "<qty> items"),
                                        Step(keyword: .then, text: "<pct>% off")
                                    ],
                                    examples: [
                                        Examples(
                                            table: DataTable(rows: [
                                                ["qty", "pct"],
                                                ["50", "10"],
                                                ["100", "15"]
                                            ]))
                                    ]
                                ))
                        ]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("`@pricing`"))
        #expect(markdown.contains("`@discount`"))
        #expect(markdown.contains("## Rule: Discounts"))
        #expect(markdown.contains("Pricing rules for discounts"))
        #expect(markdown.contains("### Background"))
        #expect(markdown.contains("## Scenario Outline: Discount for <qty>"))
        #expect(markdown.contains("### Examples"))
    }

    // MARK: - Markdown Scenario with Description

    @Test("Markdown export — scenario with description")
    func markdownScenarioDescription() throws {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Described scenario",
                        description: "This scenario has a description",
                        steps: [Step(keyword: .given, text: "something")]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("This scenario has a description"))
    }

    // MARK: - Markdown Outline with Description

    @Test("Markdown export — outline with description")
    func markdownOutlineDescription() throws {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Described outline",
                        description: "This outline has a description",
                        steps: [Step(keyword: .given, text: "input <x>")],
                        examples: [
                            Examples(
                                table: DataTable(rows: [["x"], ["1"]]))
                        ]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("This outline has a description"))
    }

    // MARK: - Streaming: exportWithProgress to invalid path

    @Test("Streaming exportWithProgress — invalid path yields empty stream")
    func streamingExportProgressInvalidPath() async {
        let exporter = StreamingExporter()
        var progressCount = 0
        for await _ in await exporter.exportWithProgress(
            Feature(title: "Test"),
            to: "/nonexistent-dir/file.feature"
        ) {
            progressCount += 1
        }
        #expect(progressCount == 0)
    }

    // MARK: - Streaming: exportWithProgress — background path

    @Test("Streaming exportWithProgress — feature with background")
    func streamingExportProgressWithBackground() async throws {
        let exporter = StreamingExporter()
        let tempPath = NSTemporaryDirectory() + "progress-bg-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let feature = Feature(
            title: "Test",
            background: Background(steps: [
                Step(keyword: .given, text: "something")
            ]),
            children: [
                .scenario(
                    Scenario(
                        title: "S1",
                        steps: [Step(keyword: .then, text: "result")]
                    ))
            ]
        )

        var updates: [ExportProgress] = []
        for await progress in await exporter.exportWithProgress(feature, to: tempPath) {
            updates.append(progress)
        }
        #expect(updates.count == 1)

        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
        #expect(content.contains("Background:"))
    }

    // MARK: - File export with format

    @Test("Export to file as JSON")
    func exportFileAsJSON() async throws {
        let tempPath = NSTemporaryDirectory() + "export-json-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let feature = Feature(
            title: "JSON Export",
            children: [
                .scenario(
                    Scenario(
                        title: "Test",
                        steps: [Step(keyword: .given, text: "data")]
                    ))
            ]
        )

        try await exporter.export(feature, to: tempPath, format: .json)

        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
        #expect(content.contains("\"title\""))
        #expect(content.contains("JSON Export"))
    }

    @Test("Export to file as Markdown")
    func exportFileAsMarkdown() async throws {
        let tempPath = NSTemporaryDirectory() + "export-md-\(UUID().uuidString).md"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let feature = Feature(
            title: "Markdown Export",
            children: [
                .scenario(
                    Scenario(
                        title: "Test",
                        steps: [Step(keyword: .given, text: "data")]
                    ))
            ]
        )

        try await exporter.export(feature, to: tempPath, format: .markdown)

        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
        #expect(content.contains("# Feature: Markdown Export"))
    }

    // MARK: - Export to invalid path

    @Test("Export to invalid path throws exportFailed")
    func exportInvalidPath() async {
        await #expect(throws: GherkinError.self) {
            try await exporter.export(
                Feature(title: "Test"),
                to: "/nonexistent-dir-abc/file.feature"
            )
        }
    }
}
