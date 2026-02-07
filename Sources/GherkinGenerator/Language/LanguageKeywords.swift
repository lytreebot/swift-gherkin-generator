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
/// print(kw.given)      // ["Soit", "Etant donné", "Etant donnée", ...]
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
    /// Falls back to English keywords if the code is not registered.
    ///
    /// - Parameter code: The ISO language code (e.g., `"en"`, `"fr"`).
    /// - Returns: The keyword set for the language.
    public static func keywords(for code: String) -> LanguageKeywords {
        builtInKeywords[code] ?? english
    }

    /// All registered language codes.
    public static var registeredLanguages: [String] {
        Array(builtInKeywords.keys.sorted())
    }

    // MARK: - Built-in Registry

    /// Built-in keyword definitions.
    /// - Note: The full 70+ languages will be generated from `gherkin-languages.json`.
    ///   This initial set covers the most common languages.
    private static let builtInKeywords: [String: LanguageKeywords] = [
        "en": english,
        "fr": french,
        "de": german,
        "es": spanish,
    ]
}

// MARK: - Built-in Language Keywords

extension LanguageKeywords {
    /// English keywords (default).
    public static let english = LanguageKeywords(
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

    /// French keywords.
    public static let french = LanguageKeywords(
        feature: ["Fonctionnalité"],
        rule: ["Règle"],
        background: ["Contexte"],
        scenario: ["Scénario"],
        scenarioOutline: ["Plan du Scénario", "Plan du scénario"],
        examples: ["Exemples"],
        given: ["Soit ", "Etant donné ", "Etant donnée ", "Etant donnés ", "Etant données ", "Étant donné ", "Étant donnée ", "Étant donnés ", "Étant données "],
        when: ["Quand ", "Lorsque ", "Lorsqu'"],
        then: ["Alors "],
        and: ["Et "],
        but: ["Mais "]
    )

    /// German keywords.
    public static let german = LanguageKeywords(
        feature: ["Funktionalität", "Funktion"],
        rule: ["Regel"],
        background: ["Grundlage", "Hintergrund", "Voraussetzungen", "Vorbedingungen"],
        scenario: ["Szenario"],
        scenarioOutline: ["Szenarien", "Szenariovorlage"],
        examples: ["Beispiele"],
        given: ["Angenommen ", "Gegeben sei ", "Gegeben seien "],
        when: ["Wenn "],
        then: ["Dann "],
        and: ["Und "],
        but: ["Aber "]
    )

    /// Spanish keywords.
    public static let spanish = LanguageKeywords(
        feature: ["Característica", "Necesidad del negocio", "Requisito"],
        rule: ["Regla"],
        background: ["Antecedentes"],
        scenario: ["Escenario", "Ejemplo"],
        scenarioOutline: ["Esquema del escenario"],
        examples: ["Ejemplos"],
        given: ["Dado ", "Dada ", "Dados ", "Dadas "],
        when: ["Cuando "],
        then: ["Entonces "],
        and: ["Y "],
        but: ["Pero "]
    )
}
