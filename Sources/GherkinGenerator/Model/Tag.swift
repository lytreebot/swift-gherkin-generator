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

/// A Gherkin tag attached to features, rules, scenarios, or examples.
///
/// Tags in Gherkin start with `@` and are used for filtering and organization.
/// The `Tag` type stores the name without the `@` prefix and provides
/// the full representation via ``rawValue``.
///
/// ```swift
/// let tag = Tag("smoke")
/// print(tag.rawValue) // "@smoke"
/// ```
public struct Tag: Sendable, Hashable, Codable {
    /// The tag name without the `@` prefix.
    public let name: String

    /// The full tag string including the `@` prefix.
    public var rawValue: String { "@\(name)" }

    /// Creates a new tag.
    ///
    /// If the provided name starts with `@`, the prefix is stripped automatically.
    ///
    /// - Parameter name: The tag name, with or without the `@` prefix.
    public init(_ name: String) {
        if name.hasPrefix("@") {
            self.name = String(name.dropFirst())
        } else {
            self.name = name
        }
    }
}

extension Tag: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Tag: CustomStringConvertible {
    public var description: String { rawValue }
}
