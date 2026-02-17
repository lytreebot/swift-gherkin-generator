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

@Suite("BatchValidator")
struct BatchValidatorTests {

    // MARK: - Test Fixtures

    private static let validFeature = """
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

    private static let invalidGherkin = """
        This is not valid Gherkin
        """

    private static let validationFailingFeature = """
        Feature: Bad Feature
          Scenario: No Given or Then
            When I do something
        """

    // MARK: - Validate Directory

    @Test("Validate directory with all valid files")
    func validateAllValid() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "login.feature": Self.validFeature,
            "registration.feature": Self.validFeatureB
        ])

        let validator = BatchValidator()
        let results = try await validator.validateDirectory(at: dir.path)

        #expect(results.count == 2)
        let allValid = results.allSatisfy(\.isSuccess)
        #expect(allValid)
    }

    @Test("Validate directory with parse error")
    func validateWithParseError() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "valid.feature": Self.validFeature,
            "invalid.feature": Self.invalidGherkin
        ])

        let validator = BatchValidator()
        let results = try await validator.validateDirectory(at: dir.path)

        #expect(results.count == 2)

        let failed = results.filter { !$0.isSuccess }
        #expect(failed.count == 1)
        #expect(failed[0].featureTitle == nil)
        #expect(!failed[0].errors.isEmpty)
    }

    @Test("Validate directory with validation errors")
    func validateWithValidationErrors() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "valid.feature": Self.validFeature,
            "bad.feature": Self.validationFailingFeature
        ])

        let validator = BatchValidator()
        let results = try await validator.validateDirectory(at: dir.path)

        #expect(results.count == 2)

        let valid = results.first { $0.featureTitle == "Login" }
        #expect(valid?.isSuccess == true)

        let invalid = results.first { $0.featureTitle == "Bad Feature" }
        #expect(invalid?.isSuccess == false)
        #expect(invalid?.errors.isEmpty == false)
    }

    @Test("Validate empty directory returns empty results")
    func validateEmptyDirectory() async throws {
        let dir = try FeatureFixtureDirectory(files: [:])

        let validator = BatchValidator()
        let results = try await validator.validateDirectory(at: dir.path)

        #expect(results.isEmpty)
    }

    @Test("Validate nonexistent directory throws error")
    func validateNonexistentDirectory() async {
        let validator = BatchValidator()

        await #expect(throws: GherkinError.self) {
            try await validator.validateDirectory(
                at: "/nonexistent-\(UUID().uuidString)"
            )
        }
    }

    @Test("Validate directory preserves file order")
    func validatePreservesOrder() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "b_second.feature": Self.validFeatureB,
            "a_first.feature": Self.validFeature
        ])

        let validator = BatchValidator()
        let results = try await validator.validateDirectory(at: dir.path)

        #expect(results.count == 2)
        #expect(results[0].featureTitle == "Login")
        #expect(results[1].featureTitle == "Registration")
    }

    // MARK: - Recursive Validation

    @Test("Validate directory recursively")
    func validateRecursive() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "login.feature": Self.validFeature,
            "sub/registration.feature": Self.validFeatureB
        ])

        let validator = BatchValidator()
        let nonRecursive = try await validator.validateDirectory(
            at: dir.path, recursive: false
        )
        let recursive = try await validator.validateDirectory(
            at: dir.path, recursive: true
        )

        #expect(nonRecursive.count == 1)
        #expect(recursive.count == 2)
    }

    // MARK: - Stream Validation

    @Test("Stream validation yields results for all files")
    func streamValidation() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "a.feature": Self.validFeature,
            "b.feature": Self.validFeatureB
        ])

        let validator = BatchValidator()
        var results: [BatchValidationResult] = []
        for await result in await validator.streamValidation(at: dir.path) {
            results.append(result)
        }

        #expect(results.count == 2)
    }

    @Test("Stream validation handles invalid path")
    func streamInvalidPath() async {
        let validator = BatchValidator()
        var results: [BatchValidationResult] = []

        for await result in await validator.streamValidation(
            at: "/nonexistent-\(UUID().uuidString)"
        ) {
            results.append(result)
        }

        #expect(results.count == 1)
        #expect(!results[0].isSuccess)
    }

    @Test("Stream validation reports mixed results")
    func streamMixedResults() async throws {
        let dir = try FeatureFixtureDirectory(files: [
            "valid.feature": Self.validFeature,
            "bad.feature": Self.validationFailingFeature
        ])

        let validator = BatchValidator()
        var successes = 0
        var failures = 0

        for await result in await validator.streamValidation(at: dir.path) {
            if result.isSuccess {
                successes += 1
            } else {
                failures += 1
            }
        }

        #expect(successes == 1)
        #expect(failures == 1)
    }

    // MARK: - BatchValidationResult

    @Test("BatchValidationResult isSuccess when no errors and title present")
    func resultIsSuccess() {
        let result = BatchValidationResult(
            path: "/test.feature", featureTitle: "Test", errors: []
        )
        #expect(result.isSuccess)
    }

    @Test("BatchValidationResult is not success when errors present")
    func resultIsNotSuccessWithErrors() {
        let result = BatchValidationResult(
            path: "/test.feature",
            featureTitle: "Test",
            errors: [.emptyFeature]
        )
        #expect(!result.isSuccess)
    }

    @Test("BatchValidationResult is not success when title is nil")
    func resultIsNotSuccessWithoutTitle() {
        let result = BatchValidationResult(
            path: "/test.feature",
            featureTitle: nil,
            errors: []
        )
        #expect(!result.isSuccess)
    }
}
