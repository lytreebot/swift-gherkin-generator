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

/// A Gherkin Rule that groups related scenarios (Gherkin 6+).
///
/// Rules provide a way to organize scenarios under a business rule
/// within a feature. Each rule can have its own background and
/// contains scenarios and/or scenario outlines.
///
/// ```swift
/// let rule = Rule(
///     title: "Discount rules",
///     background: Background(steps: [
///         Step(keyword: .given, text: "a premium customer")
///     ]),
///     children: [
///         .scenario(Scenario(title: "10% off orders over 100€", steps: [...]))
///     ]
/// )
/// ```
public struct Rule: Sendable, Hashable, Codable {
    /// The rule title.
    public let title: String

    /// Tags attached to this rule.
    public let tags: [Tag]

    /// An optional description providing additional context.
    public let description: String?

    /// An optional background for scenarios within this rule.
    public let background: Background?

    /// The scenarios and scenario outlines within this rule.
    /// Rules cannot contain nested rules.
    public let children: [RuleChild]

    /// Creates a new rule.
    ///
    /// - Parameters:
    ///   - title: The rule title.
    ///   - tags: Tags for this rule. Defaults to empty.
    ///   - description: An optional description. Defaults to `nil`.
    ///   - background: An optional background. Defaults to `nil`.
    ///   - children: The scenarios and outlines. Defaults to empty.
    public init(
        title: String,
        tags: [Tag] = [],
        description: String? = nil,
        background: Background? = nil,
        children: [RuleChild] = []
    ) {
        self.title = title
        self.tags = tags
        self.description = description
        self.background = background
        self.children = children
    }
}

/// A child element of a rule (scenario or scenario outline only — no nested rules).
public enum RuleChild: Sendable, Hashable, Codable {
    /// A standard scenario within this rule.
    case scenario(Scenario)

    /// A parameterized scenario outline within this rule.
    case outline(ScenarioOutline)
}
