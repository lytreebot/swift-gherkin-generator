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

/// Errors that can occur during Gherkin generation, validation, or parsing.
///
/// `GherkinError` provides detailed, actionable error messages with
/// context information such as scenario names, line numbers, and
/// specific details about the issue.
public enum GherkinError: Error, Sendable, Hashable {

    // MARK: - Validation Errors

    /// A scenario is missing at least one `Given` step.
    ///
    /// - Parameter scenario: The name of the scenario.
    case missingGiven(scenario: String)

    /// A scenario is missing at least one `Then` step.
    ///
    /// - Parameter scenario: The name of the scenario.
    case missingThen(scenario: String)

    /// Consecutive duplicate steps were found.
    ///
    /// - Parameters:
    ///   - step: The duplicate step text.
    ///   - scenario: The scenario containing the duplicate.
    case duplicateConsecutiveStep(step: String, scenario: String)

    /// A tag has an invalid format (must start with `@`, no spaces).
    ///
    /// - Parameter tag: The invalid tag string.
    case invalidTagFormat(tag: String)

    /// A data table has inconsistent column counts across rows.
    ///
    /// - Parameters:
    ///   - expected: The expected column count (from header row).
    ///   - found: The actual column count.
    ///   - row: The zero-based row index.
    case inconsistentTableColumns(expected: Int, found: Int, row: Int)

    /// A data table contains an empty cell.
    ///
    /// - Parameters:
    ///   - row: The zero-based row index.
    ///   - column: The zero-based column index.
    case emptyTableCell(row: Int, column: Int)

    /// A placeholder in a Scenario Outline step is not present in the Examples columns.
    ///
    /// - Parameters:
    ///   - placeholder: The placeholder name (without angle brackets).
    ///   - scenario: The scenario outline title.
    case undefinedPlaceholder(placeholder: String, scenario: String)

    /// The feature has no scenarios.
    case emptyFeature

    /// A feature title is empty.
    case emptyTitle

    // MARK: - Builder Errors

    /// A step was added without first starting a scenario.
    case stepWithoutScenario

    /// Examples were added to a regular scenario (not an outline).
    case examplesOnNonOutline(scenario: String)

    /// A background was added after scenarios.
    case backgroundAfterScenario

    // MARK: - Parser Errors

    /// A syntax error was encountered during parsing.
    ///
    /// - Parameters:
    ///   - message: A description of the syntax error.
    ///   - line: The one-based line number.
    case syntaxError(message: String, line: Int)

    /// An unexpected keyword was encountered.
    ///
    /// - Parameters:
    ///   - keyword: The unexpected keyword.
    ///   - line: The one-based line number.
    case unexpectedKeyword(keyword: String, line: Int)

    /// The language specified in the file is not supported.
    ///
    /// - Parameter language: The language identifier.
    case unsupportedLanguage(language: String)

    // MARK: - Export Errors

    /// An error occurred while writing to the file system.
    ///
    /// - Parameters:
    ///   - path: The file path.
    ///   - reason: A description of the I/O error.
    case exportFailed(path: String, reason: String)

    // MARK: - Import Errors

    /// The file could not be read.
    ///
    /// - Parameters:
    ///   - path: The file path.
    ///   - reason: A description of the read error.
    case importFailed(path: String, reason: String)

    /// The file format is not supported.
    ///
    /// - Parameter format: The file extension or format name.
    case unsupportedFormat(format: String)
}

extension GherkinError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingGiven(let scenario):
            "Scenario '\(scenario)' is missing a Given step."
        case .missingThen(let scenario):
            "Scenario '\(scenario)' is missing a Then step."
        case .duplicateConsecutiveStep(let step, let scenario):
            "Duplicate consecutive step '\(step)' in scenario '\(scenario)'."
        case .invalidTagFormat(let tag):
            "Invalid tag format: '\(tag)'. Tags must start with '@' and contain no spaces."
        case .inconsistentTableColumns(let expected, let found, let row):
            "Data table row \(row) has \(found) columns, expected \(expected)."
        case .emptyTableCell(let row, let column):
            "Empty cell at row \(row), column \(column)."
        case .undefinedPlaceholder(let placeholder, let scenario):
            "Placeholder '<\(placeholder)>' in outline '\(scenario)' is not defined in Examples."
        case .emptyFeature:
            "Feature has no scenarios."
        case .emptyTitle:
            "Feature title is empty."
        case .stepWithoutScenario:
            "Step added without first starting a scenario."
        case .examplesOnNonOutline(let scenario):
            "Examples added to regular scenario '\(scenario)'. Use addOutline() instead."
        case .backgroundAfterScenario:
            "Background must be defined before any scenarios."
        case .syntaxError(let message, let line):
            "Syntax error at line \(line): \(message)"
        case .unexpectedKeyword(let keyword, let line):
            "Unexpected keyword '\(keyword)' at line \(line)."
        case .unsupportedLanguage(let language):
            "Unsupported language: '\(language)'."
        case .exportFailed(let path, let reason):
            "Export to '\(path)' failed: \(reason)"
        case .importFailed(let path, let reason):
            "Import from '\(path)' failed: \(reason)"
        case .unsupportedFormat(let format):
            "Unsupported format: '\(format)'."
        }
    }
}
