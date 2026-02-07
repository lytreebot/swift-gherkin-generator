import Testing

@testable import GherkinGenerator

@Suite("GherkinParser - Language")
struct GherkinParserLanguageTests {

    private let parser = GherkinParser()

    // MARK: - Language Detection

    @Test("Detect French language")
    func detectFrench() {
        let source = """
            # language: fr
            Fonctionnalité: Authentification
              Scénario: Connexion
                Soit un compte valide
                Quand je me connecte
                Alors je suis connecté
            """
        let language = parser.detectLanguage(in: source)
        #expect(language == .french)
    }

    @Test("Default to English when no language header")
    func defaultEnglish() {
        let source = """
            Feature: Login
              Scenario: Test
                Given something
                Then result
            """
        let language = parser.detectLanguage(in: source)
        #expect(language == .english)
    }

    // MARK: - French Parsing

    @Test("Parse French feature")
    func frenchFeature() throws {
        let source = """
            # language: fr
            Fonctionnalité: Authentification
              Scénario: Connexion
                Soit un compte valide
                Quand je me connecte
                Alors je suis connecté
            """
        let feature = try parser.parse(source)
        #expect(feature.title == "Authentification")
        #expect(feature.language == .french)

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.title == "Connexion")
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[0].text == "un compte valide")
        #expect(scenario.steps[1].keyword == .when)
        #expect(scenario.steps[2].keyword == .then)
    }

    @Test("Parse French with Etant donne")
    func frenchEtantDonne() throws {
        let source = """
            # language: fr
            Fonctionnalité: Test
              Scénario: Test
                Etant donné un utilisateur
                Alors le résultat est ok
            """
        let feature = try parser.parse(source)
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[0].text == "un utilisateur")
    }
}
