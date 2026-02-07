import Foundation

/// A stateless parser that reads Gherkin content into model objects.
///
/// `GherkinParser` uses a recursive descent approach to parse `.feature`
/// files, strings, and other input formats into ``Feature`` values.
///
/// ```swift
/// let parser = GherkinParser()
/// let feature = try parser.parse(contentsOfFile: "login.feature")
/// ```
///
/// The parser automatically detects the language from the `# language:` header
/// or falls back to English.
public struct GherkinParser: Sendable {

    /// Creates a new parser.
    public init() {}

    /// Parses a Gherkin string into a ``Feature``.
    ///
    /// - Parameter source: The Gherkin source string.
    /// - Returns: The parsed feature.
    /// - Throws: ``GherkinError/syntaxError(message:line:)`` on parse errors.
    public func parse(_ source: String) throws -> Feature {
        var cursor = ParserCursor(source: source)
        let language = cursor.detectLanguage()
        let keywords = language.keywords
        return try cursor.parseFeature(language: language, keywords: keywords)
    }

    /// Parses a `.feature` file into a ``Feature``.
    ///
    /// - Parameter path: The path to the `.feature` file.
    /// - Returns: The parsed feature.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if the file cannot be read,
    ///   or ``GherkinError/syntaxError(message:line:)`` on parse errors.
    public func parse(contentsOfFile path: String) throws -> Feature {
        let content: String
        do {
            content = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw GherkinError.importFailed(path: path, reason: error.localizedDescription)
        }
        return try parse(content)
    }

    /// Detects the language from a Gherkin source string.
    ///
    /// Looks for a `# language: xx` header in the first few lines.
    ///
    /// - Parameter source: The Gherkin source string.
    /// - Returns: The detected language, or ``GherkinLanguage/english`` if none found.
    public func detectLanguage(in source: String) -> GherkinLanguage {
        var cursor = ParserCursor(source: source)
        return cursor.detectLanguage()
    }
}

// MARK: - Parser Cursor

/// Internal mutable cursor that walks through lines of Gherkin source.
private struct ParserCursor {
    private let lines: [(number: Int, text: String)]
    private var position: Int

    init(source: String) {
        var numbered: [(number: Int, text: String)] = []
        var lineNumber = 1
        source.enumerateLines { line, _ in
            numbered.append((number: lineNumber, text: line))
            lineNumber += 1
        }
        self.lines = numbered
        self.position = 0
    }

    var isAtEnd: Bool { position >= lines.count }

    var currentLine: (number: Int, text: String)? {
        guard !isAtEnd else { return nil }
        return lines[position]
    }

    mutating func advance() { position += 1 }

    mutating func peekTrimmed() -> String? {
        currentLine.map { $0.text.trimmingCharacters(in: .whitespaces) }
    }

    private static let knownLanguages: [String: GherkinLanguage] = [
        "en": .english, "fr": .french, "de": .german, "es": .spanish,
        "it": .italian, "pt": .portuguese, "ja": .japanese, "zh-CN": .chinese,
        "ru": .russian, "ar": .arabic, "ko": .korean, "nl": .dutch,
        "pl": .polish, "tr": .turkish, "sv": .swedish
    ]

    mutating func detectLanguage() -> GherkinLanguage {
        let saved = position
        defer { position = saved }
        let maxLines = min(lines.count, 10)
        for index in 0..<maxLines {
            let trimmed = lines[index].text.trimmingCharacters(in: .whitespaces)
            if let code = parseLanguageDirective(trimmed) {
                return Self.knownLanguages[code]
                    ?? GherkinLanguage(code: code, name: code, nativeName: code)
            }
        }
        return .english
    }

    func parseLanguageDirective(_ line: String) -> String? {
        guard line.hasPrefix("#") else { return nil }
        let withoutHash = line.dropFirst().trimmingCharacters(in: .whitespaces)
        guard withoutHash.lowercased().hasPrefix("language:") else { return nil }
        let code = withoutHash.dropFirst("language:".count).trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return nil }
        return code
    }

    func currentLineNumber() -> Int {
        currentLine?.number ?? lines.last.map { $0.number + 1 } ?? 1
    }

    mutating func skipBlanksAndComments() {
        while !isAtEnd {
            guard let line = peekTrimmed() else { break }
            if line.isEmpty || line.hasPrefix("#") { advance() } else { break }
        }
    }

    func isLanguageDirective(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return false }
        let rest = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
        return rest.lowercased().hasPrefix("language:")
    }
}

// MARK: - Feature Header Result

/// The result of parsing the feature header (tags, title, description).
private struct FeatureHeader {
    let tags: [Tag]
    let title: String
    let description: String?
}

// MARK: - Parsing Methods

extension ParserCursor {

    // MARK: Feature

    mutating func parseFeature(
        language: GherkinLanguage,
        keywords: LanguageKeywords
    ) throws -> Feature {
        var comments: [Comment] = []
        let header = try parseFeatureHeader(
            keywords: keywords, comments: &comments
        )
        let (background, children) = try parseFeatureBody(
            keywords: keywords, comments: &comments
        )
        return Feature(
            title: header.title, language: language, tags: header.tags,
            description: header.description, background: background,
            children: children, comments: comments
        )
    }

    private mutating func parseFeatureHeader(
        keywords: LanguageKeywords,
        comments: inout [Comment]
    ) throws -> FeatureHeader {
        var pendingTags: [Tag] = []
        while let line = peekTrimmed(), !isAtEnd {
            if line.isEmpty || isLanguageDirective(line) {
                advance()
            } else if line.hasPrefix("#") {
                comments.append(Comment(text: line))
                advance()
            } else if line.hasPrefix("@") {
                pendingTags = parseTags(line)
                advance()
            } else {
                break
            }
        }
        guard let featureLine = peekTrimmed() else {
            throw GherkinError.syntaxError(message: "Expected Feature keyword", line: currentLineNumber())
        }
        guard let featureTitle = matchKeyword(featureLine, keywords: keywords.feature) else {
            throw GherkinError.syntaxError(
                message: "Expected Feature keyword, found '\(featureLine)'",
                line: currentLineNumber()
            )
        }
        advance()
        let description = parseDescription(keywords: keywords)
        return FeatureHeader(tags: pendingTags, title: featureTitle, description: description)
    }

    private mutating func parseFeatureBody(
        keywords: LanguageKeywords,
        comments: inout [Comment]
    ) throws -> (background: Background?, children: [FeatureChild]) {
        var background: Background?
        var children: [FeatureChild] = []
        var pendingTags: [Tag] = []
        while !isAtEnd {
            guard let line = peekTrimmed() else { break }
            if line.isEmpty {
                advance()
                continue
            }
            if line.hasPrefix("#") {
                if !isLanguageDirective(line) { comments.append(Comment(text: line)) }
                advance()
                continue
            }
            if line.hasPrefix("@") {
                pendingTags = parseTags(line)
                advance()
                continue
            }
            let child = try parseFeatureChild(
                line: line, pendingTags: &pendingTags,
                background: &background, keywords: keywords
            )
            if let child { children.append(child) }
        }
        return (background: background, children: children)
    }

    private mutating func parseFeatureChild(
        line: String, pendingTags: inout [Tag],
        background: inout Background?, keywords: LanguageKeywords
    ) throws -> FeatureChild? {
        if matchKeyword(line, keywords: keywords.background) != nil {
            background = try parseBackground(keywords: keywords)
            return nil
        }
        if let title = matchKeyword(line, keywords: keywords.scenarioOutline) {
            let outline = try parseScenarioOutline(title: title, tags: pendingTags, keywords: keywords)
            pendingTags = []
            return .outline(outline)
        }
        if let title = matchKeyword(line, keywords: keywords.scenario) {
            let scenario = try parseScenario(title: title, tags: pendingTags, keywords: keywords)
            pendingTags = []
            return .scenario(scenario)
        }
        if let title = matchKeyword(line, keywords: keywords.rule) {
            let rule = try parseRule(title: title, tags: pendingTags, keywords: keywords)
            pendingTags = []
            return .rule(rule)
        }
        throw GherkinError.unexpectedKeyword(keyword: line, line: currentLineNumber())
    }

    // MARK: Background

    private mutating func parseBackground(keywords: LanguageKeywords) throws -> Background {
        let line = peekTrimmed() ?? ""
        let name = matchKeyword(line, keywords: keywords.background)
        advance()
        let description = parseDescription(keywords: keywords)
        let steps = try parseSteps(keywords: keywords)
        return Background(
            name: name?.isEmpty == false ? name : nil,
            description: description, steps: steps
        )
    }

    // MARK: Scenario

    private mutating func parseScenario(
        title: String, tags: [Tag], keywords: LanguageKeywords
    ) throws -> Scenario {
        advance()
        let description = parseDescription(keywords: keywords)
        let steps = try parseSteps(keywords: keywords)
        return Scenario(title: title, tags: tags, description: description, steps: steps)
    }

    // MARK: Scenario Outline

    private mutating func parseScenarioOutline(
        title: String, tags: [Tag], keywords: LanguageKeywords
    ) throws -> ScenarioOutline {
        advance()
        let description = parseDescription(keywords: keywords)
        let steps = try parseSteps(keywords: keywords)
        var examples: [Examples] = []
        while !isAtEnd {
            skipBlanksAndComments()
            guard let line = peekTrimmed() else { break }
            if line.hasPrefix("@") {
                let exampleTags = parseTags(line)
                advance()
                skipBlanksAndComments()
                guard let nextLine = peekTrimmed(),
                    matchKeyword(nextLine, keywords: keywords.examples) != nil
                else { break }
                let exampleName = matchKeyword(nextLine, keywords: keywords.examples)
                advance()
                let table = parseDataTable()
                examples.append(
                    Examples(
                        name: exampleName?.isEmpty == false ? exampleName : nil,
                        tags: exampleTags, table: table
                    ))
                continue
            }
            guard matchKeyword(line, keywords: keywords.examples) != nil else { break }
            let exampleName = matchKeyword(line, keywords: keywords.examples)
            advance()
            let table = parseDataTable()
            examples.append(
                Examples(
                    name: exampleName?.isEmpty == false ? exampleName : nil, table: table
                ))
        }
        return ScenarioOutline(
            title: title, tags: tags, description: description,
            steps: steps, examples: examples
        )
    }

    // MARK: Rule

    private mutating func parseRule(
        title: String, tags: [Tag], keywords: LanguageKeywords
    ) throws -> Rule {
        advance()
        let description = parseDescription(keywords: keywords)
        var background: Background?
        var children: [RuleChild] = []
        var pendingTags: [Tag] = []
        while !isAtEnd {
            guard let line = peekTrimmed() else { break }
            if line.isEmpty {
                advance()
                continue
            }
            if line.hasPrefix("#") {
                advance()
                continue
            }
            if line.hasPrefix("@") {
                pendingTags = parseTags(line)
                advance()
                continue
            }
            if matchKeyword(line, keywords: keywords.feature) != nil { break }
            if matchKeyword(line, keywords: keywords.rule) != nil { break }
            if matchKeyword(line, keywords: keywords.background) != nil {
                background = try parseBackground(keywords: keywords)
                continue
            }
            if let outlineTitle = matchKeyword(line, keywords: keywords.scenarioOutline) {
                let outline = try parseScenarioOutline(
                    title: outlineTitle, tags: pendingTags, keywords: keywords
                )
                children.append(.outline(outline))
                pendingTags = []
                continue
            }
            if let scenarioTitle = matchKeyword(line, keywords: keywords.scenario) {
                let scenario = try parseScenario(
                    title: scenarioTitle, tags: pendingTags, keywords: keywords
                )
                children.append(.scenario(scenario))
                pendingTags = []
                continue
            }
            break
        }
        return Rule(
            title: title, tags: tags, description: description,
            background: background, children: children
        )
    }

    // MARK: Steps

    private mutating func parseSteps(keywords: LanguageKeywords) throws -> [Step] {
        var steps: [Step] = []
        while !isAtEnd {
            guard let line = peekTrimmed() else { break }
            if line.isEmpty {
                advance()
                continue
            }
            if line.hasPrefix("#") {
                advance()
                continue
            }
            guard let (keyword, text) = matchStepKeyword(line, keywords: keywords) else { break }
            advance()
            var docString: DocString?
            if let trimmed = peekTrimmed(), trimmed.hasPrefix("\"\"\"") {
                docString = parseDocString()
            }
            var dataTable: DataTable?
            if docString == nil, let trimmed = peekTrimmed(), trimmed.hasPrefix("|") {
                dataTable = parseDataTable()
            }
            steps.append(
                Step(
                    keyword: keyword, text: text, dataTable: dataTable, docString: docString
                ))
        }
        return steps
    }

    // MARK: Data Table

    private mutating func parseDataTable() -> DataTable {
        var rows: [[String]] = []
        while !isAtEnd {
            guard let line = peekTrimmed(), line.hasPrefix("|") else { break }
            rows.append(parseTableRow(line))
            advance()
        }
        return DataTable(rows: rows)
    }

    private func parseTableRow(_ line: String) -> [String] {
        let stripped = line.trimmingCharacters(in: .whitespaces)
        guard stripped.hasPrefix("|"), stripped.hasSuffix("|") else { return [] }
        let inner = stripped.dropFirst().dropLast()
        return inner.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: Doc String

    private mutating func parseDocString() -> DocString {
        guard let openingLine = peekTrimmed() else { return DocString(content: "") }
        let afterQuotes = openingLine.dropFirst(3).trimmingCharacters(in: .whitespaces)
        let mediaType: String? = afterQuotes.isEmpty ? nil : afterQuotes
        advance()
        var contentLines: [String] = []
        while !isAtEnd {
            guard let line = currentLine else { break }
            let trimmed = line.text.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("\"\"\"") {
                advance()
                break
            }
            contentLines.append(line.text)
            advance()
        }
        return DocString(content: contentLines.joined(separator: "\n"), mediaType: mediaType)
    }

    // MARK: Description

    private mutating func parseDescription(keywords: LanguageKeywords) -> String? {
        var descriptionLines: [String] = []
        while !isAtEnd {
            guard let line = peekTrimmed() else { break }
            if line.isEmpty {
                if descriptionLines.isEmpty {
                    advance()
                    continue
                } else {
                    break
                }
            }
            if line.hasPrefix("@") || line.hasPrefix("#") || line.hasPrefix("|") { break }
            if isKeywordLine(line, keywords: keywords) { break }
            descriptionLines.append(line)
            advance()
        }
        let result = descriptionLines.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }

    // MARK: Tags

    private func parseTags(_ line: String) -> [Tag] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        var tags: [Tag] = []
        for part in trimmed.split(separator: " ") {
            let tagString = String(part)
            if tagString.hasPrefix("@") { tags.append(Tag(tagString)) }
        }
        return tags
    }

    // MARK: Keyword Matching

    private func matchKeyword(_ line: String, keywords: [String]) -> String? {
        for keyword in keywords {
            let prefix = keyword + ":"
            if line.hasPrefix(prefix) {
                return line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private func matchStepKeyword(
        _ line: String, keywords: LanguageKeywords
    ) -> (StepKeyword, String)? {
        if line.hasPrefix("* ") {
            return (.wildcard, String(line.dropFirst(2)))
        }
        let keywordGroups: [(StepKeyword, [String])] = [
            (.given, keywords.given), (.when, keywords.when), (.then, keywords.then),
            (.and, keywords.and), (.but, keywords.but)
        ]
        for (stepKeyword, group) in keywordGroups {
            if let matched = group.first(where: { line.hasPrefix($0) }) {
                return (stepKeyword, String(line.dropFirst(matched.count)))
            }
        }
        return nil
    }

    private func isKeywordLine(_ line: String, keywords: LanguageKeywords) -> Bool {
        matchKeyword(line, keywords: keywords.feature) != nil
            || matchKeyword(line, keywords: keywords.scenario) != nil
            || matchKeyword(line, keywords: keywords.scenarioOutline) != nil
            || matchKeyword(line, keywords: keywords.background) != nil
            || matchKeyword(line, keywords: keywords.rule) != nil
            || matchKeyword(line, keywords: keywords.examples) != nil
            || matchStepKeyword(line, keywords: keywords) != nil
    }
}
