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

/// A background block that provides shared precondition steps.
///
/// Background steps run before each scenario in a feature or rule.
/// They avoid repeating the same `Given` steps across multiple scenarios.
///
/// ```swift
/// let background = Background(steps: [
///     Step(keyword: .given, text: "a logged-in user"),
///     Step(keyword: .and, text: "at least one existing order"),
/// ])
/// ```
public struct Background: Sendable, Hashable, Codable {
    /// An optional name for the background.
    public let name: String?

    /// An optional description providing additional context.
    public let description: String?

    /// The steps in this background block.
    public let steps: [Step]

    /// Creates a new background.
    ///
    /// - Parameters:
    ///   - name: An optional name. Defaults to `nil`.
    ///   - description: An optional description. Defaults to `nil`.
    ///   - steps: The background steps.
    public init(name: String? = nil, description: String? = nil, steps: [Step] = []) {
        self.name = name
        self.description = description
        self.steps = steps
    }
}
