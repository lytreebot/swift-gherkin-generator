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

@Suite("BatchImporter")
struct BatchImporterTests {

    // MARK: - Test Fixtures

    private static let validFeatureA = """
        Feature: Login
          Scenario: Successful login
            Given a valid account
            When the user logs in
            Then the dashboard is displayed
        """

    private static let validFeatureB = """
        Feature: Registration
          Scenario: New user
            Given a registration form
            When I fill in my details
            Then an account is created
        """

    private static let invalidFeature = """
        This is not valid Gherkin
        It has no Feature keyword
        """

    // MARK: - Import Directory

    @Test("Import directory with valid feature files")
    func importValidDirectory() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "login.feature": Self.validFeatureA,
            "registration.feature": Self.validFeatureB
        ])

        let importer = BatchImporter()
        let results = try await importer.importDirectory(at: dir.path)

        #expect(results.count == 2)
        for result in results {
            switch result {
            case .success:
                break
            case .failure(let error):
                Issue.record("Unexpected failure: \(error)")
            }
        }
    }

    @Test("Import directory returns results in sorted file order")
    func importPreservesOrder() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "b_second.feature": Self.validFeatureB,
            "a_first.feature": Self.validFeatureA
        ])

        let importer = BatchImporter()
        let results = try await importer.importDirectory(at: dir.path)

        #expect(results.count == 2)
        if case .success(let first) = results[0] {
            #expect(first.title == "Login")
        }
        if case .success(let second) = results[1] {
            #expect(second.title == "Registration")
        }
    }

    @Test("Import directory handles invalid files gracefully")
    func importWithInvalidFile() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "valid.feature": Self.validFeatureA,
            "invalid.feature": Self.invalidFeature
        ])

        let importer = BatchImporter()
        let results = try await importer.importDirectory(at: dir.path)

        #expect(results.count == 2)
        let successCount = results.filter {
            if case .success = $0 { return true }
            return false
        }.count
        let failureCount = results.filter {
            if case .failure = $0 { return true }
            return false
        }.count
        #expect(successCount == 1)
        #expect(failureCount == 1)
    }

    @Test("Import empty directory returns empty array")
    func importEmptyDirectory() async throws {
        let dir = try FeatureFixtureDirectory(files: [:])

        let importer = BatchImporter()
        let results = try await importer.importDirectory(at: dir.path)

        #expect(results.isEmpty)
    }

    @Test("Import nonexistent directory throws error")
    func importNonexistentDirectory() async {
        let importer = BatchImporter()

        await #expect(throws: GherkinError.self) {
            try await importer.importDirectory(at: "/nonexistent-path-\(UUID().uuidString)")
        }
    }

    @Test("Import directory ignores non-feature files")
    func importIgnoresNonFeatureFiles() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "login.feature": Self.validFeatureA,
            "readme.md": "# Features",
            "notes.txt": "Some notes"
        ])

        let importer = BatchImporter()
        let results = try await importer.importDirectory(at: dir.path)

        #expect(results.count == 1)
    }

    // MARK: - Recursive Import

    @Test("Import directory recursively finds files in subdirectories")
    func importRecursive() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "login.feature": Self.validFeatureA,
            "sub/registration.feature": Self.validFeatureB
        ])

        let importer = BatchImporter()
        let nonRecursive = try await importer.importDirectory(at: dir.path, recursive: false)
        let recursive = try await importer.importDirectory(at: dir.path, recursive: true)

        #expect(nonRecursive.count == 1)
        #expect(recursive.count == 2)
    }

    // MARK: - Stream Directory

    @Test("Stream directory yields all features")
    func streamDirectory() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "a.feature": Self.validFeatureA,
            "b.feature": Self.validFeatureB
        ])

        let importer = BatchImporter()
        var results: [Result<Feature, GherkinError>] = []
        for await result in await importer.streamDirectory(at: dir.path) {
            results.append(result)
        }

        #expect(results.count == 2)
    }

    @Test("Stream directory handles invalid path")
    func streamInvalidPath() async {
        let importer = BatchImporter()
        var results: [Result<Feature, GherkinError>] = []

        for await result in await importer.streamDirectory(
            at: "/nonexistent-\(UUID().uuidString)"
        ) {
            results.append(result)
        }

        #expect(results.count == 1)
        if case .failure = results[0] {
            // Expected
        } else {
            Issue.record("Expected failure result")
        }
    }

    @Test("Stream directory with mixed valid and invalid files")
    func streamMixedFiles() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "valid.feature": Self.validFeatureA,
            "invalid.feature": Self.invalidFeature
        ])

        let importer = BatchImporter()
        var successes = 0
        var failures = 0

        for await result in await importer.streamDirectory(at: dir.path) {
            switch result {
            case .success:
                successes += 1
            case .failure:
                failures += 1
            }
        }

        #expect(successes == 1)
        #expect(failures == 1)
    }
}
