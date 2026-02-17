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

/// Thread-safe registry of all Gherkin languages loaded from the official
/// `gherkin-languages.json` resource.
///
/// Uses `static let` for lazy, thread-safe initialization (Swift guarantees
/// `dispatch_once` semantics for static let).
struct GherkinLanguageRegistry: Sendable {

    /// All keyword sets indexed by language code.
    let keywords: [String: LanguageKeywords]

    /// All language metadata indexed by language code.
    let languages: [String: GherkinLanguage]

    /// The shared, lazily-loaded registry instance.
    static let shared: GherkinLanguageRegistry = loadFromBundle()

    // MARK: - Loading

    private static func loadFromBundle() -> GherkinLanguageRegistry {
        guard
            let url = Bundle.module.url(
                forResource: "gherkin-languages", withExtension: "json"
            )
        else {
            return GherkinLanguageRegistry(keywords: [:], languages: [:])
        }

        guard let data = try? Data(contentsOf: url) else {
            return GherkinLanguageRegistry(keywords: [:], languages: [:])
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return GherkinLanguageRegistry(keywords: [:], languages: [:])
        }

        var keywordsMap: [String: LanguageKeywords] = [:]
        var languagesMap: [String: GherkinLanguage] = [:]

        for (code, value) in json {
            guard let entry = value as? [String: Any] else { continue }
            guard let kw = parseKeywords(from: entry) else { continue }
            keywordsMap[code] = kw

            let name = entry["name"] as? String ?? code
            let native = entry["native"] as? String ?? code
            languagesMap[code] = GherkinLanguage(code: code, name: name, nativeName: native)
        }

        return GherkinLanguageRegistry(keywords: keywordsMap, languages: languagesMap)
    }

    private static func parseKeywords(from entry: [String: Any]) -> LanguageKeywords? {
        guard let feature = entry["feature"] as? [String],
            let rule = entry["rule"] as? [String],
            let background = entry["background"] as? [String],
            let scenario = entry["scenario"] as? [String],
            let scenarioOutline = entry["scenarioOutline"] as? [String],
            let examples = entry["examples"] as? [String],
            let given = entry["given"] as? [String],
            let when = entry["when"] as? [String],
            let then = entry["then"] as? [String],
            let and = entry["and"] as? [String],
            let but = entry["but"] as? [String]
        else {
            return nil
        }

        return LanguageKeywords(
            feature: feature,
            rule: rule,
            background: background,
            scenario: scenario,
            scenarioOutline: scenarioOutline,
            examples: examples,
            given: filterWildcard(given),
            when: filterWildcard(when),
            then: filterWildcard(then),
            and: filterWildcard(and),
            but: filterWildcard(but)
        )
    }

    /// Removes the `"* "` wildcard entry from step keyword arrays.
    ///
    /// The wildcard step is handled separately by the parser/formatter via
    /// ``StepKeyword/wildcard``, so it must not appear in the keyword arrays.
    private static func filterWildcard(_ keywords: [String]) -> [String] {
        keywords.filter { $0 != "* " }
    }
}
