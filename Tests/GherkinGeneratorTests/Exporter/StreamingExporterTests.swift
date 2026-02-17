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

@Suite("StreamingExporter")
struct StreamingExporterTests {

    // MARK: - Test Fixtures

    private static let simpleFeature = Feature(
        title: "Login",
        children: [
            .scenario(
                Scenario(
                    title: "Successful login",
                    steps: [
                        Step(keyword: .given, text: "a valid account"),
                        Step(keyword: .when, text: "the user logs in"),
                        Step(keyword: .then, text: "the dashboard is displayed")
                    ]
                ))
        ]
    )

    private static func largeFeature(scenarioCount: Int) -> Feature {
        let children: [FeatureChild] = (0..<scenarioCount).map { index in
            .scenario(
                Scenario(
                    title: "Scenario \(index)",
                    steps: [
                        Step(keyword: .given, text: "precondition \(index)"),
                        Step(keyword: .when, text: "action \(index)"),
                        Step(keyword: .then, text: "result \(index)")
                    ]
                ))
        }
        return Feature(title: "Large Feature", children: children)
    }

    // MARK: - File Export

    @Test("Export simple feature to file via streaming")
    func exportSimpleFeature() async throws {
        let exporter = StreamingExporter()
        let tempPath = NSTemporaryDirectory() + "streaming-test-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        try await exporter.export(Self.simpleFeature, to: tempPath)

        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
        #expect(content.contains("Feature: Login"))
        #expect(content.contains("Given a valid account"))
        #expect(content.contains("When the user logs in"))
        #expect(content.contains("Then the dashboard is displayed"))
    }

    @Test("Streaming export matches formatter output")
    func streamingMatchesFormatter() async throws {
        let formatter = GherkinFormatter()
        let exporter = StreamingExporter(formatter: formatter)
        let tempPath = NSTemporaryDirectory() + "streaming-match-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        try await exporter.export(Self.simpleFeature, to: tempPath)

        let streamedContent = try String(contentsOfFile: tempPath, encoding: .utf8)
        let formattedContent = formatter.format(Self.simpleFeature)

        #expect(streamedContent == formattedContent)
    }

    @Test("Streaming export with background and rules")
    func exportComplexFeature() async throws {
        let feature = Feature(
            title: "Shopping Cart",
            tags: [Tag("smoke")],
            background: Background(steps: [
                Step(keyword: .given, text: "a logged-in user")
            ]),
            children: [
                .scenario(
                    Scenario(
                        title: "Add product",
                        steps: [
                            Step(keyword: .when, text: "I add a product"),
                            Step(keyword: .then, text: "the cart has 1 item")
                        ]
                    )),
                .rule(
                    Rule(
                        title: "Discounts",
                        children: [
                            .scenario(
                                Scenario(
                                    title: "Volume discount",
                                    steps: [
                                        Step(keyword: .given, text: "10 items"),
                                        Step(keyword: .then, text: "10% off")
                                    ]
                                ))
                        ]
                    ))
            ]
        )

        let formatter = GherkinFormatter()
        let exporter = StreamingExporter(formatter: formatter)
        let tempPath = NSTemporaryDirectory() + "streaming-complex-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        try await exporter.export(feature, to: tempPath)

        let streamedContent = try String(contentsOfFile: tempPath, encoding: .utf8)
        let formattedContent = formatter.format(feature)

        #expect(streamedContent == formattedContent)
    }

    @Test("Export to invalid path throws error")
    func exportInvalidPath() async throws {
        let exporter = StreamingExporter()
        let invalidPath = "/nonexistent-dir/file.feature"

        await #expect(throws: GherkinError.self) {
            try await exporter.export(Self.simpleFeature, to: invalidPath)
        }
    }

    // MARK: - Lines Stream

    @Test("Lines stream yields all formatted lines")
    func linesStream() async {
        let exporter = StreamingExporter()
        var collectedLines: [String] = []

        for await line in await exporter.lines(for: Self.simpleFeature) {
            collectedLines.append(line)
        }

        let joined = collectedLines.joined(separator: "\n") + "\n"
        let formatter = GherkinFormatter()
        let expected = formatter.format(Self.simpleFeature)

        #expect(joined == expected)
    }

    @Test("Lines stream with non-English language")
    func linesStreamFrench() async {
        let feature = Feature(
            title: "Authentification",
            language: .french,
            children: [
                .scenario(
                    Scenario(
                        title: "Connexion",
                        steps: [
                            Step(keyword: .given, text: "un compte valide"),
                            Step(keyword: .then, text: "je suis connect\u{00E9}")
                        ]
                    ))
            ]
        )

        let exporter = StreamingExporter()
        var lines: [String] = []
        for await line in await exporter.lines(for: feature) {
            lines.append(line)
        }

        let output = lines.joined(separator: "\n")
        #expect(output.contains("# language: fr"))
        #expect(output.contains("Fonctionnalit\u{00E9}: Authentification"))
    }

    // MARK: - Progress Reporting

    @Test("Progress stream reports correct fractions")
    func progressReporting() async {
        let feature = Self.largeFeature(scenarioCount: 5)
        let exporter = StreamingExporter()
        let tempPath = NSTemporaryDirectory() + "streaming-progress-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        var progressUpdates: [ExportProgress] = []
        for await progress in await exporter.exportWithProgress(feature, to: tempPath) {
            progressUpdates.append(progress)
        }

        #expect(progressUpdates.count == 5)
        #expect(progressUpdates[0].childIndex == 0)
        #expect(progressUpdates[0].totalChildren == 5)
        #expect(progressUpdates[4].fractionCompleted == 1.0)
    }

    @Test("Progress stream yields monotonically increasing fractions")
    func progressMonotonic() async {
        let feature = Self.largeFeature(scenarioCount: 10)
        let exporter = StreamingExporter()
        let tempPath = NSTemporaryDirectory() + "streaming-monotonic-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        var lastFraction = 0.0
        for await progress in await exporter.exportWithProgress(feature, to: tempPath) {
            #expect(progress.fractionCompleted >= lastFraction)
            lastFraction = progress.fractionCompleted
        }
        #expect(lastFraction == 1.0)
    }
}
