import Testing

@testable import GherkinGenerator

// MARK: - Registry Tests

@Suite("Language Registry")
struct LanguageRegistryTests {

    @Test("Registry loads 70+ languages from JSON")
    func registryLoads70PlusLanguages() {
        let languages = LanguageKeywords.registeredLanguages
        #expect(languages.count >= 70)
    }

    @Test("GherkinLanguage.all returns all languages sorted by code")
    func allLanguagesSortedByCode() {
        let all = GherkinLanguage.all
        #expect(all.count >= 70)
        let codes = all.map(\.code)
        #expect(codes == codes.sorted())
    }

    @Test("GherkinLanguage init(code:) returns language for known code")
    func initWithKnownCode() {
        let french = GherkinLanguage(code: "fr")
        #expect(french != nil)
        #expect(french?.code == "fr")
        #expect(french?.name == "French")
        #expect(french?.nativeName == "fran\u{00E7}ais")
    }

    @Test("GherkinLanguage init(code:) returns nil for unknown code")
    func initWithUnknownCode() {
        let unknown = GherkinLanguage(code: "zz-unknown")
        #expect(unknown == nil)
    }

    @Test("Static shortcuts match registry values")
    func staticShortcutsMatchRegistry() {
        let fromRegistry = GherkinLanguage(code: "fr")
        #expect(GherkinLanguage.french == fromRegistry)

        let deFromRegistry = GherkinLanguage(code: "de")
        #expect(GherkinLanguage.german == deFromRegistry)

        let esFromRegistry = GherkinLanguage(code: "es")
        #expect(GherkinLanguage.spanish == esFromRegistry)
    }
}

// MARK: - Keyword Tests

@Suite("Language Keywords")
struct LanguageKeywordTests {

    @Test(
        "Keywords loaded for common languages",
        arguments: ["en", "fr", "de", "es", "it", "pt", "ja", "zh-CN", "ru", "ar", "ko", "nl"]
    )
    func keywordsLoadedForLanguage(code: String) {
        let kw = LanguageKeywords.keywords(for: code)
        #expect(!kw.feature.isEmpty)
        #expect(!kw.scenario.isEmpty)
        #expect(!kw.given.isEmpty)
        #expect(!kw.when.isEmpty)
        #expect(!kw.then.isEmpty)
    }

    @Test("English keywords match expected values")
    func englishKeywords() {
        let kw = LanguageKeywords.english
        #expect(kw.feature.contains("Feature"))
        #expect(kw.scenario.contains("Scenario"))
        #expect(kw.scenarioOutline.contains("Scenario Outline"))
        #expect(kw.background.contains("Background"))
        #expect(kw.examples.contains("Examples"))
        #expect(kw.given.contains("Given "))
        #expect(kw.when.contains("When "))
        #expect(kw.then.contains("Then "))
        #expect(kw.and.contains("And "))
        #expect(kw.but.contains("But "))
    }

    @Test("French keywords contain expected values")
    func frenchKeywords() {
        let kw = LanguageKeywords.keywords(for: "fr")
        #expect(kw.feature.contains("Fonctionnalit\u{00E9}"))
        #expect(kw.scenario.contains("Sc\u{00E9}nario"))
        #expect(kw.given.contains("Soit "))
        #expect(kw.when.contains("Quand "))
        #expect(kw.then.contains("Alors "))
    }

    @Test("German keywords contain expected values")
    func germanKeywords() {
        let kw = LanguageKeywords.keywords(for: "de")
        #expect(kw.feature.contains("Funktionalit\u{00E4}t"))
        #expect(kw.scenario.contains("Szenario"))
        #expect(kw.given.contains("Angenommen "))
        #expect(kw.when.contains("Wenn "))
        #expect(kw.then.contains("Dann "))
    }

    @Test("Japanese keywords loaded (non-Latin)")
    func japaneseKeywords() {
        let kw = LanguageKeywords.keywords(for: "ja")
        #expect(kw.feature.contains("\u{6A5F}\u{80FD}"))
        #expect(kw.scenario.contains("\u{30B7}\u{30CA}\u{30EA}\u{30AA}"))
        #expect(!kw.given.isEmpty)
        #expect(!kw.when.isEmpty)
        #expect(!kw.then.isEmpty)
    }

    @Test("Arabic keywords loaded (RTL)")
    func arabicKeywords() {
        let kw = LanguageKeywords.keywords(for: "ar")
        #expect(!kw.feature.isEmpty)
        #expect(!kw.scenario.isEmpty)
        #expect(!kw.given.isEmpty)
    }

    @Test("Step keywords have trailing spaces")
    func stepKeywordsHaveTrailingSpaces() {
        let kw = LanguageKeywords.keywords(for: "en")
        for givenKeyword in kw.given {
            #expect(givenKeyword.hasSuffix(" "), "Given keyword '\(givenKeyword)' should end with space")
        }
        for whenKeyword in kw.when {
            #expect(whenKeyword.hasSuffix(" "), "When keyword '\(whenKeyword)' should end with space")
        }
        for thenKeyword in kw.then {
            #expect(thenKeyword.hasSuffix(" "), "Then keyword '\(thenKeyword)' should end with space")
        }
    }

    @Test("Wildcard '* ' is filtered from step keywords")
    func wildcardFiltered() {
        let kw = LanguageKeywords.keywords(for: "en")
        #expect(!kw.given.contains("* "))
        #expect(!kw.when.contains("* "))
        #expect(!kw.then.contains("* "))
        #expect(!kw.and.contains("* "))
        #expect(!kw.but.contains("* "))
    }

    @Test("Fallback to English for unknown language code")
    func fallbackToEnglish() {
        let kw = LanguageKeywords.keywords(for: "zz-nonexistent")
        #expect(kw.feature.contains("Feature"))
        #expect(kw.given.contains("Given "))
    }
}

// MARK: - GherkinLanguage Metadata Tests

@Suite("Language Metadata")
struct LanguageMetadataTests {

    @Test("GherkinLanguage has correct name and nativeName")
    func languageMetadata() {
        let japanese = GherkinLanguage(code: "ja")
        #expect(japanese?.name == "Japanese")
        #expect(japanese?.nativeName == "\u{65E5}\u{672C}\u{8A9E}")

        let russian = GherkinLanguage(code: "ru")
        #expect(russian?.name == "Russian")
    }

    @Test("GherkinLanguage keywords property uses registry")
    func keywordsViaLanguage() {
        let lang = GherkinLanguage.french
        let kw = lang.keywords
        #expect(kw.feature.contains("Fonctionnalit\u{00E9}"))
    }

    @Test("GherkinLanguage description format")
    func descriptionFormat() {
        let lang = GherkinLanguage.english
        #expect(lang.description == "English (en)")
    }
}

// MARK: - Parser Integration with Languages

@Suite("Parser with Non-English Languages")
struct ParserLanguageIntegrationTests {

    private let parser = GherkinParser()

    @Test("Parse German feature")
    func parseGerman() throws {
        let source = """
            # language: de
            Funktionalit\u{00E4}t: Anmeldung
              Szenario: Erfolgreiche Anmeldung
                Angenommen ein g\u{00FC}ltiges Konto
                Wenn ich mich anmelde
                Dann sehe ich das Dashboard
            """
        let feature = try parser.parse(source)
        #expect(feature.title == "Anmeldung")
        #expect(feature.language == .german)

        guard case .scenario(let scenario) = feature.children.first else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[0].text == "ein g\u{00FC}ltiges Konto")
        #expect(scenario.steps[1].keyword == .when)
        #expect(scenario.steps[2].keyword == .then)
    }

    @Test("Parse Japanese feature")
    func parseJapanese() throws {
        let source = """
            # language: ja
            \u{6A5F}\u{80FD}: \u{30ED}\u{30B0}\u{30A4}\u{30F3}
              \u{30B7}\u{30CA}\u{30EA}\u{30AA}: \u{6210}\u{529F}\u{3059}\u{308B}\u{30ED}\u{30B0}\u{30A4}\u{30F3}
                \u{524D}\u{63D0}\u{6709}\u{52B9}\u{306A}\u{30A2}\u{30AB}\u{30A6}\u{30F3}\u{30C8}
                \u{3082}\u{3057}\u{30ED}\u{30B0}\u{30A4}\u{30F3}\u{3059}\u{308B}
                \u{306A}\u{3089}\u{3070}\u{30C0}\u{30C3}\u{30B7}\u{30E5}\u{30DC}\u{30FC}\u{30C9}\u{304C}\u{8868}\u{793A}\u{3055}\u{308C}\u{308B}
            """
        let feature = try parser.parse(source)
        #expect(feature.title == "\u{30ED}\u{30B0}\u{30A4}\u{30F3}")
        #expect(feature.language.code == "ja")

        guard case .scenario(let scenario) = feature.children.first else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps.count == 3)
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[1].keyword == .when)
        #expect(scenario.steps[2].keyword == .then)
    }

    @Test("Parse Spanish feature")
    func parseSpanish() throws {
        let source = """
            # language: es
            Caracter\u{00ED}stica: Inicio de sesi\u{00F3}n
              Escenario: Inicio exitoso
                Dado una cuenta v\u{00E1}lida
                Cuando inicio sesi\u{00F3}n
                Entonces veo el panel
            """
        let feature = try parser.parse(source)
        #expect(feature.title == "Inicio de sesi\u{00F3}n")
        #expect(feature.language == .spanish)

        guard case .scenario(let scenario) = feature.children.first else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[1].keyword == .when)
        #expect(scenario.steps[2].keyword == .then)
    }

    @Test("Parse Russian feature")
    func parseRussian() throws {
        let featureKw = "Функция"
        let scenarioKw = "Сценарий"
        let source = """
            # language: ru
            \(featureKw): Аутентификация
              \(scenarioKw): Успешный вход
                Допустим действительный аккаунт
                Когда я вхожу
                Тогда я вижу панель
            """
        let feature = try parser.parse(source)
        #expect(feature.language.code == "ru")

        guard case .scenario(let scenario) = feature.children.first else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps.count == 3)
        #expect(scenario.steps[0].keyword == .given)
    }
}

// MARK: - Formatter Integration with Languages

@Suite("Formatter with Non-English Languages")
struct FormatterLanguageIntegrationTests {

    private let formatter = GherkinFormatter()
    private let parser = GherkinParser()

    @Test("Format German feature produces valid output")
    func formatGerman() {
        let feature = Feature(
            title: "Anmeldung",
            language: .german,
            children: [
                .scenario(
                    Scenario(
                        title: "Erfolgreiche Anmeldung",
                        steps: [
                            Step(keyword: .given, text: "ein g\u{00FC}ltiges Konto"),
                            Step(keyword: .when, text: "ich mich anmelde"),
                            Step(keyword: .then, text: "sehe ich das Dashboard")
                        ]
                    ))
            ]
        )
        let output = formatter.format(feature)
        #expect(output.contains("# language: de"))
        #expect(output.contains("Funktionalit\u{00E4}t: Anmeldung"))
        #expect(output.contains("Beispiel: Erfolgreiche Anmeldung"))
        #expect(output.contains("Angenommen ein g\u{00FC}ltiges Konto"))
        #expect(output.contains("Wenn ich mich anmelde"))
        #expect(output.contains("Dann sehe ich das Dashboard"))
    }

    @Test("Format then parse round-trip for German")
    func germanRoundtrip() throws {
        let feature = Feature(
            title: "Anmeldung",
            language: .german,
            children: [
                .scenario(
                    Scenario(
                        title: "Test",
                        steps: [
                            Step(keyword: .given, text: "eine Voraussetzung"),
                            Step(keyword: .when, text: "eine Aktion"),
                            Step(keyword: .then, text: "ein Ergebnis")
                        ]
                    ))
            ]
        )
        let firstOutput = formatter.format(feature)
        let parsed = try parser.parse(firstOutput)
        let secondOutput = formatter.format(parsed)
        #expect(firstOutput == secondOutput)
    }

    @Test("Format then parse round-trip for Japanese")
    func japaneseRoundtrip() throws {
        let feature = Feature(
            title: "\u{30ED}\u{30B0}\u{30A4}\u{30F3}",
            language: .japanese,
            children: [
                .scenario(
                    Scenario(
                        title: "\u{30C6}\u{30B9}\u{30C8}",
                        steps: [
                            Step(keyword: .given, text: "\u{524D}\u{63D0}\u{6761}\u{4EF6}"),
                            Step(keyword: .when, text: "\u{30A2}\u{30AF}\u{30B7}\u{30E7}\u{30F3}"),
                            Step(keyword: .then, text: "\u{7D50}\u{679C}")
                        ]
                    ))
            ]
        )
        let firstOutput = formatter.format(feature)
        let parsed = try parser.parse(firstOutput)
        let secondOutput = formatter.format(parsed)
        #expect(firstOutput == secondOutput)
    }
}
