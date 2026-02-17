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

/// An examples block for a Scenario Outline.
///
/// Examples provide concrete values for the placeholders defined in
/// a Scenario Outline's steps. Each examples block can have its own
/// tags and an optional name.
///
/// ```swift
/// let examples = Examples(
///     table: DataTable(rows: [
///         ["email", "valid"],
///         ["test@example.com", "true"],
///         ["invalid", "false"],
///     ])
/// )
/// ```
public struct Examples: Sendable, Hashable, Codable {
    /// An optional name for this examples block.
    public let name: String?

    /// Tags attached to this examples block.
    public let tags: [Tag]

    /// The data table containing header row and example rows.
    public let table: DataTable

    /// Creates a new examples block.
    ///
    /// - Parameters:
    ///   - name: An optional name. Defaults to `nil`.
    ///   - tags: Tags for this block. Defaults to empty.
    ///   - table: The data table with headers and rows.
    public init(name: String? = nil, tags: [Tag] = [], table: DataTable) {
        self.name = name
        self.tags = tags
        self.table = table
    }
}
