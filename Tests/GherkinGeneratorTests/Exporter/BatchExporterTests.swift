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

// MARK: - Shared Fixtures

private let sampleFeatures: [Feature] = [
    Feature(
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
    ),
    Feature(
        title: "Shopping Cart",
        children: [
            .scenario(
                Scenario(
                    title: "Add product",
                    steps: [
                        Step(keyword: .given, text: "an empty cart"),
                        Step(keyword: .when, text: "I add a product"),
                        Step(keyword: .then, text: "the cart has 1 item")
                    ]
                ))
        ]
    ),
    Feature(
        title: "Checkout",
        children: [
            .scenario(
                Scenario(
                    title: "Complete checkout",
                    steps: [
                        Step(keyword: .given, text: "a cart with items"),
                        Step(keyword: .when, text: "I complete checkout"),
                        Step(keyword: .then, text: "the order is confirmed")
                    ]
                ))
        ]
    )
]

private func makeMinimalFeature(title: String) -> Feature {
    Feature(
        title: title,
        children: [
            .scenario(
                Scenario(
                    title: "Test",
                    steps: [
                        Step(keyword: .given, text: "x"),
                        Step(keyword: .then, text: "y")
                    ]
                ))
        ]
    )
}

private func makeTempDir() -> String {
    let path = NSTemporaryDirectory() + "batch-export-\(UUID().uuidString)"
    try? FileManager.default.createDirectory(
        atPath: path,
        withIntermediateDirectories: true
    )
    return path
}

private func cleanup(_ path: String) {
    try? FileManager.default.removeItem(atPath: path)
}

// MARK: - BatchExporter — Core

@Suite("BatchExporter")
struct BatchExporterTests {

    @Test("Export features to directory")
    func exportBasic() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let exporter = BatchExporter()
        let results = try await exporter.exportAll(sampleFeatures, to: tempDir)

        #expect(results.count == 3)
        for result in results {
            guard case .success(let path) = result else {
                Issue.record("Expected success, got failure")
                return
            }
            let content = try String(contentsOfFile: path, encoding: .utf8)
            #expect(!content.isEmpty)
        }
    }

    @Test("Feature titles are slugified into filenames")
    func slugifiedFilenames() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let features = [
            makeMinimalFeature(title: "Login & Registration"),
            makeMinimalFeature(title: "User  Profile  Page")
        ]

        let exporter = BatchExporter()
        let results = try await exporter.exportAll(features, to: tempDir)

        guard case .success(let path1) = results[0],
            case .success(let path2) = results[1]
        else {
            Issue.record("Expected success")
            return
        }

        #expect((path1 as NSString).lastPathComponent == "login-registration.feature")
        #expect((path2 as NSString).lastPathComponent == "user-profile-page.feature")
    }

    @Test("Slugify produces correct results")
    func slugifyEdgeCases() {
        #expect(BatchExporter.slugify("Hello World") == "hello-world")
        #expect(BatchExporter.slugify("Login & Registration") == "login-registration")
        #expect(BatchExporter.slugify("  spaces  ") == "spaces")
        #expect(BatchExporter.slugify("---dashes---") == "dashes")
        #expect(BatchExporter.slugify("") == "feature")
        #expect(BatchExporter.slugify("!!!") == "feature")
        #expect(BatchExporter.slugify("under_score") == "under-score")
    }

    @Test("Duplicate titles get numeric suffixes")
    func duplicateFilenames() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let duplicateFeatures = [
            makeMinimalFeature(title: "Login"),
            makeMinimalFeature(title: "Login"),
            makeMinimalFeature(title: "Login")
        ]

        let exporter = BatchExporter()
        let results = try await exporter.exportAll(duplicateFeatures, to: tempDir)

        let filenames = results.compactMap { result -> String? in
            guard case .success(let path) = result else { return nil }
            return (path as NSString).lastPathComponent
        }

        #expect(filenames.count == 3)
        #expect(filenames.contains("login.feature"))
        #expect(filenames.contains("login-1.feature"))
        #expect(filenames.contains("login-2.feature"))
    }

    @Test("Pre-existing file in directory triggers suffix")
    func existingFileSuffix() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        try "existing".write(
            toFile: (tempDir as NSString).appendingPathComponent("login.feature"),
            atomically: true,
            encoding: .utf8
        )

        let exporter = BatchExporter()
        let results = try await exporter.exportAll(
            [makeMinimalFeature(title: "Login")],
            to: tempDir
        )

        guard case .success(let path) = results[0] else {
            Issue.record("Expected success")
            return
        }

        #expect((path as NSString).lastPathComponent == "login-1.feature")
    }

    @Test("Creates output directory if it does not exist")
    func directoryCreated() async throws {
        let tempDir = makeTempDir()
        let nestedDir = (tempDir as NSString).appendingPathComponent("sub/nested")
        defer { cleanup(tempDir) }

        let exporter = BatchExporter()
        let results = try await exporter.exportAll([sampleFeatures[0]], to: nestedDir)

        #expect(results.count == 1)
        guard case .success(let path) = results[0] else {
            Issue.record("Expected success")
            return
        }
        #expect(FileManager.default.fileExists(atPath: path))
    }
}

// MARK: - BatchExporter — Progress & Formats

@Suite("BatchExporter — Progress & Formats")
struct BatchExporterProgressTests {

    @Test("Progress stream yields correct values")
    func progressStream() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let exporter = BatchExporter()
        var progressUpdates: [BatchExportProgress] = []

        for await progress in await exporter.exportAllWithProgress(
            sampleFeatures,
            to: tempDir
        ) {
            progressUpdates.append(progress)
        }

        #expect(progressUpdates.count == 3)
        for progress in progressUpdates {
            #expect(progress.total == 3)
            #expect(!progress.outputPath.isEmpty)
            #expect(!progress.featureTitle.isEmpty)
        }

        let fractions = progressUpdates.map(\.fractionCompleted).sorted()
        #expect(fractions.last == 1.0)
    }

    @Test("Error on one file does not block others")
    func errorIsolation() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let exporter = BatchExporter()
        let results = try await exporter.exportAll(sampleFeatures, to: tempDir)

        let successes = results.filter {
            if case .success = $0 { return true }
            return false
        }
        #expect(successes.count == sampleFeatures.count)
    }

    @Test("Export to JSON format")
    func exportJSON() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let exporter = BatchExporter()
        let results = try await exporter.exportAll(
            [sampleFeatures[0]],
            to: tempDir,
            format: .json
        )

        guard case .success(let path) = results[0] else {
            Issue.record("Expected success")
            return
        }

        #expect(path.hasSuffix(".json"))
        let content = try String(contentsOfFile: path, encoding: .utf8)
        #expect(content.contains("Login"))
    }

    @Test("Export to Markdown format")
    func exportMarkdown() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let exporter = BatchExporter()
        let results = try await exporter.exportAll(
            [sampleFeatures[0]],
            to: tempDir,
            format: .markdown
        )

        guard case .success(let path) = results[0] else {
            Issue.record("Expected success")
            return
        }

        #expect(path.hasSuffix(".md"))
        let content = try String(contentsOfFile: path, encoding: .utf8)
        #expect(content.contains("Login"))
    }
}
