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

/// A language for Gherkin keyword localization.
///
/// Gherkin supports 70+ languages, each providing localized keywords
/// for `Feature`, `Scenario`, `Given`, `When`, `Then`, etc.
///
/// Use ``keywords`` to access the localized keyword set for a language.
///
/// ```swift
/// let lang = GherkinLanguage.french
/// print(lang.keywords.feature) // ["Fonctionnalité"]
/// print(lang.keywords.given)   // ["Soit", "Etant donné", ...]
/// ```
///
/// - Note: The full set of 70+ languages will be loaded from the official
///   `gherkin-languages.json`. This enum provides the most commonly used
///   languages as static members with support for custom languages.
public struct GherkinLanguage: Sendable, Codable {
    /// The ISO language code (e.g., `"en"`, `"fr"`, `"de"`).
    public let code: String

    /// The language name in English.
    public let name: String

    /// The native language name.
    public let nativeName: String

    /// Creates a language with the given code and names.
    ///
    /// - Parameters:
    ///   - code: The ISO language code.
    ///   - name: The English language name.
    ///   - nativeName: The native language name.
    public init(code: String, name: String, nativeName: String) {
        self.code = code
        self.name = name
        self.nativeName = nativeName
    }

    /// The localized keywords for this language.
    ///
    /// Returns the keyword set registered for this language code,
    /// or falls back to English keywords if the code is not registered.
    public var keywords: LanguageKeywords {
        LanguageKeywords.keywords(for: code)
    }
}

// MARK: - Registry Lookup

extension GherkinLanguage {
    /// All available languages loaded from the official `gherkin-languages.json`.
    ///
    /// Returns an array of all registered languages, sorted by language code.
    /// Typically contains 70+ languages.
    public static var all: [GherkinLanguage] {
        Array(GherkinLanguageRegistry.shared.languages.values).sorted { $0.code < $1.code }
    }

    /// Creates a language by looking up the given code in the registry.
    ///
    /// Returns `nil` if the code is not found in the official language list.
    ///
    /// - Parameter code: The ISO language code (e.g., `"en"`, `"fr"`, `"ja"`).
    public init?(code: String) {
        guard let language = GherkinLanguageRegistry.shared.languages[code] else { return nil }
        self = language
    }
}

// MARK: - Common Languages

extension GherkinLanguage {
    /// English (default).
    public static let english = GherkinLanguage(code: "en", name: "English", nativeName: "English")

    /// French.
    public static let french = GherkinLanguage(code: "fr", name: "French", nativeName: "Français")

    /// German.
    public static let german = GherkinLanguage(code: "de", name: "German", nativeName: "Deutsch")

    /// Spanish.
    public static let spanish = GherkinLanguage(code: "es", name: "Spanish", nativeName: "Español")

    /// Italian.
    public static let italian = GherkinLanguage(code: "it", name: "Italian", nativeName: "Italiano")

    /// Portuguese.
    public static let portuguese = GherkinLanguage(code: "pt", name: "Portuguese", nativeName: "Português")

    /// Japanese.
    public static let japanese = GherkinLanguage(code: "ja", name: "Japanese", nativeName: "日本語")

    /// Chinese (Simplified).
    public static let chinese = GherkinLanguage(code: "zh-CN", name: "Chinese (Simplified)", nativeName: "简体中文")

    /// Russian.
    public static let russian = GherkinLanguage(code: "ru", name: "Russian", nativeName: "Русский")

    /// Arabic.
    public static let arabic = GherkinLanguage(code: "ar", name: "Arabic", nativeName: "العربية")

    /// Korean.
    public static let korean = GherkinLanguage(code: "ko", name: "Korean", nativeName: "한국어")

    /// Dutch.
    public static let dutch = GherkinLanguage(code: "nl", name: "Dutch", nativeName: "Nederlands")

    /// Polish.
    public static let polish = GherkinLanguage(code: "pl", name: "Polish", nativeName: "Polski")

    /// Turkish.
    public static let turkish = GherkinLanguage(code: "tr", name: "Turkish", nativeName: "Türkçe")

    /// Swedish.
    public static let swedish = GherkinLanguage(code: "sv", name: "Swedish", nativeName: "Svenska")
}

// MARK: - Equatable & Hashable (by code only)

extension GherkinLanguage: Equatable {
    public static func == (lhs: GherkinLanguage, rhs: GherkinLanguage) -> Bool {
        lhs.code == rhs.code
    }
}

extension GherkinLanguage: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension GherkinLanguage: CustomStringConvertible {
    public var description: String { "\(name) (\(code))" }
}
