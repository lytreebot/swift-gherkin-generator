/// Localized keywords for a Gherkin language.
///
/// Each language has its own set of keywords for Gherkin constructs.
/// Keywords are arrays because some languages have multiple synonyms
/// (e.g., French has both "Soit" and "Etant donné" for Given).
///
/// The first keyword in each array is the preferred/default one used for export.
///
/// ```swift
/// let kw = LanguageKeywords.keywords(for: "fr")
/// print(kw.feature)    // ["Fonctionnalité"]
/// print(kw.given)      // ["Soit", "Sachant que", ...]
/// print(kw.given[0])   // "Soit" (preferred for export)
/// ```
public struct LanguageKeywords: Sendable, Hashable {
    /// Keywords for `Feature`.
    public let feature: [String]

    /// Keywords for `Rule`.
    public let rule: [String]

    /// Keywords for `Background`.
    public let background: [String]

    /// Keywords for `Scenario`.
    public let scenario: [String]

    /// Keywords for `Scenario Outline`.
    public let scenarioOutline: [String]

    /// Keywords for `Examples`.
    public let examples: [String]

    /// Keywords for `Given`.
    public let given: [String]

    /// Keywords for `When`.
    public let when: [String]

    /// Keywords for `Then`.
    public let then: [String]

    /// Keywords for `And`.
    public let and: [String]

    /// Keywords for `But`.
    public let but: [String]

    /// Creates a keyword set with all localized keyword arrays.
    public init(
        feature: [String],
        rule: [String],
        background: [String],
        scenario: [String],
        scenarioOutline: [String],
        examples: [String],
        given: [String],
        when: [String],
        then: [String],
        and: [String],
        but: [String]
    ) {
        self.feature = feature
        self.rule = rule
        self.background = background
        self.scenario = scenario
        self.scenarioOutline = scenarioOutline
        self.examples = examples
        self.given = given
        self.when = when
        self.then = then
        self.and = and
        self.but = but
    }
}

// MARK: - Keyword Registry

extension LanguageKeywords {
    /// Returns the keywords for the given language code.
    ///
    /// Loads keywords from the official `gherkin-languages.json` resource.
    /// Falls back to English keywords if the code is not registered.
    ///
    /// - Parameter code: The ISO language code (e.g., `"en"`, `"fr"`).
    /// - Returns: The keyword set for the language.
    public static func keywords(for code: String) -> LanguageKeywords {
        GherkinLanguageRegistry.shared.keywords[code] ?? fallbackEnglish
    }

    /// All registered language codes (70+ languages).
    public static var registeredLanguages: [String] {
        Array(GherkinLanguageRegistry.shared.keywords.keys.sorted())
    }

    /// English keywords loaded from the official JSON.
    ///
    /// Falls back to a hardcoded subset if the JSON resource is unavailable.
    public static let english: LanguageKeywords =
        GherkinLanguageRegistry.shared.keywords["en"] ?? fallbackEnglish

    /// Hardcoded English keywords used only when the JSON resource cannot be loaded.
    private static let fallbackEnglish = LanguageKeywords(
        feature: ["Feature"],
        rule: ["Rule"],
        background: ["Background"],
        scenario: ["Scenario"],
        scenarioOutline: ["Scenario Outline", "Scenario Template"],
        examples: ["Examples", "Scenarios"],
        given: ["Given "],
        when: ["When "],
        then: ["Then "],
        and: ["And "],
        but: ["But "]
    )
}
