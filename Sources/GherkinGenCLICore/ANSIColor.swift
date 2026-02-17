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

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

/// Terminal color helpers for CLI output.
enum ANSIColor {

    /// Whether stdout is connected to a terminal (not piped).
    static let isTerminal: Bool = isatty(STDOUT_FILENO) != 0

    /// Wraps text in green ANSI escape codes.
    static func green(_ text: String) -> String {
        isTerminal ? "\u{001B}[32m\(text)\u{001B}[0m" : text
    }

    /// Wraps text in red ANSI escape codes.
    static func red(_ text: String) -> String {
        isTerminal ? "\u{001B}[31m\(text)\u{001B}[0m" : text
    }

    /// Wraps text in bold ANSI escape codes.
    static func bold(_ text: String) -> String {
        isTerminal ? "\u{001B}[1m\(text)\u{001B}[0m" : text
    }

    /// Wraps text in yellow ANSI escape codes.
    static func yellow(_ text: String) -> String {
        isTerminal ? "\u{001B}[33m\(text)\u{001B}[0m" : text
    }
}
