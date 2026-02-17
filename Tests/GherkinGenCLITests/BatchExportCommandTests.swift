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

import ArgumentParser
import Foundation
import GherkinGenerator
import Testing

@testable import GherkinGenCLICore

@Suite("BatchExportCommand")
struct BatchExportCommandTests {

    private static let featureA = """
        Feature: Login
          Scenario: Successful login
            Given a valid account
            When the user logs in
            Then the dashboard is displayed
        """

    private static let featureB = """
        Feature: Cart
          Scenario: Add product
            Given an empty cart
            When I add a product
            Then the cart has 1 item
        """

    @Test("Batch-export parses and exports .feature files")
    func batchExport() async throws {
        let sourceDir = makeTempDir("source")
        let outputDir = NSTemporaryDirectory() + "batch-out-\(UUID().uuidString)"
        defer {
            cleanup(sourceDir)
            cleanup(outputDir)
        }

        try Self.featureA.write(
            toFile: (sourceDir as NSString).appendingPathComponent("login.feature"),
            atomically: true,
            encoding: .utf8
        )
        try Self.featureB.write(
            toFile: (sourceDir as NSString).appendingPathComponent("cart.feature"),
            atomically: true,
            encoding: .utf8
        )

        let arguments = [
            "batch-export", sourceDir,
            "--output", outputDir
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let files = try FileManager.default.contentsOfDirectory(atPath: outputDir)
        #expect(files.count == 2)
        #expect(files.contains { $0.hasSuffix(".feature") })
    }

    @Test("Batch-export to JSON format")
    func batchExportJSON() async throws {
        let sourceDir = makeTempDir("source-json")
        let outputDir = NSTemporaryDirectory() + "batch-json-\(UUID().uuidString)"
        defer {
            cleanup(sourceDir)
            cleanup(outputDir)
        }

        try Self.featureA.write(
            toFile: (sourceDir as NSString).appendingPathComponent("login.feature"),
            atomically: true,
            encoding: .utf8
        )

        let arguments = [
            "batch-export", sourceDir,
            "--output", outputDir,
            "--format", "json"
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let files = try FileManager.default.contentsOfDirectory(atPath: outputDir)
        #expect(files.count == 1)
        #expect(files[0].hasSuffix(".json"))
    }

    @Test("Nonexistent source directory fails")
    func nonexistentSource() async throws {
        let arguments = [
            "batch-export", "/nonexistent/dir",
            "--output", "/tmp/out"
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        await #expect(throws: (any Error).self) {
            try await execute(command)
        }
    }

    @Test("Empty source directory prints warning")
    func emptySource() async throws {
        let sourceDir = makeTempDir("empty")
        let outputDir = NSTemporaryDirectory() + "batch-empty-\(UUID().uuidString)"
        defer {
            cleanup(sourceDir)
            cleanup(outputDir)
        }

        let arguments = [
            "batch-export", sourceDir,
            "--output", outputDir
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        // Should not throw — just prints warning and returns
        try await execute(command)
    }

    // MARK: - Helpers

    private func makeTempDir(_ prefix: String) -> String {
        let path = NSTemporaryDirectory() + "cli-\(prefix)-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(
            atPath: path,
            withIntermediateDirectories: true
        )
        return path
    }

    private func cleanup(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}

/// Executes a parsed ArgumentParser command.
private func execute(_ command: any ParsableCommand) async throws {
    if var asyncCommand = command as? any AsyncParsableCommand {
        try await asyncCommand.run()
    } else {
        var mutableCommand = command
        try mutableCommand.run()
    }
}
