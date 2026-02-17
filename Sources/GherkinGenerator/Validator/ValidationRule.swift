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

/// A rule that validates a Gherkin feature.
///
/// Conform to this protocol to create custom validation rules
/// that can be added to a ``GherkinValidator``.
///
/// ```swift
/// struct MaxScenariosRule: ValidationRule {
///     let maxCount: Int
///
///     func validate(_ feature: Feature) -> [GherkinError] {
///         if feature.children.count > maxCount {
///             // Return appropriate errors
///         }
///         return []
///     }
/// }
/// ```
public protocol ValidationRule: Sendable {
    /// Validates a feature and returns any errors found.
    ///
    /// - Parameter feature: The feature to validate.
    /// - Returns: An array of errors (empty if the feature passes this rule).
    func validate(_ feature: Feature) -> [GherkinError]
}
