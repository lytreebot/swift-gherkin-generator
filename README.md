<!-- Logo placeholder -->
<!-- <p align="center"><img src="Assets/logo.png" width="200" alt="GherkinGenerator logo"></p> -->

<h1 align="center">GherkinGenerator</h1>

<p align="center">
  <strong>Compose, validate, import, and export Gherkin <code>.feature</code> files in Swift.</strong>
</p>

<!-- Badges placeholder -->
<!-- [![Swift 6.2+](https://img.shields.io/badge/Swift-6.2%2B-orange)](https://swift.org) -->
<!-- [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) -->
<!-- [![CI](https://github.com/atelier-socle/swift-gherkin-generator/actions/workflows/ci.yml/badge.svg)](https://github.com/atelier-socle/swift-gherkin-generator/actions) -->
<!-- [![codecov](https://codecov.io/gh/atelier-socle/swift-gherkin-generator/branch/main/graph/badge.svg)](https://codecov.io/gh/atelier-socle/swift-gherkin-generator) -->

## Overview

GherkinGenerator is a Swift library that replaces manual Gherkin authoring with a type-safe, fluent API. Build features programmatically, validate them against 5 built-in rules, import from CSV/JSON/plain text, and export to `.feature`, JSON, or Markdown -- with full multi-language support for 70+ languages.

Part of the [Atelier Socle](https://www.atelier-socle.com) Gherkin ecosystem alongside **GherkinTesting** (execute `.feature` files as Swift Testing tests).

## Features

- **Fluent Builder API** -- chainable, immutable, `Sendable`-safe construction of features, scenarios, outlines, backgrounds, rules, data tables, and doc strings
- **Validation Engine** -- 5 built-in rules (structure, coherence, tag format, table consistency, outline placeholders) plus custom rules via the `ValidationRule` protocol
- **Multi-format Export** -- `.feature`, JSON (`Codable`), and Markdown
- **Multi-format Import** -- `.feature` (recursive descent parser), CSV, JSON, and plain text
- **70+ Languages** -- localized keywords from the official `gherkin-languages.json` with language detection
- **Streaming & Batch** -- `AsyncStream`-based streaming export and batch import/validation via actors
- **Swift 6.2 Strict Concurrency** -- all types are `Sendable`, actors for shared state, `async/await` throughout

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| Swift | 6.2+ |
| macOS | 14+ |
| iOS | 17+ |
| tvOS | 17+ |
| watchOS | 10+ |
| visionOS | 1+ |
| Mac Catalyst | 17+ |
| Linux | Supported |

## Installation

### Swift Package Manager

Add GherkinGenerator to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/atelier-socle/swift-gherkin-generator", from: "0.1.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["GherkinGenerator"]
)
```

## Quick Start

```swift
import GherkinGenerator

// Build a feature with the fluent API
let feature = try GherkinFeature(title: "Login")
    .addScenario("Successful login")
    .given("a valid account")
    .when("the user logs in")
    .then("the dashboard is displayed")
    .build()
```

> Source: `Tests/GherkinGeneratorTests/Builder/GherkinFeatureBuilderTests.swift` -- `simpleScenario()`

## API Reference

### Builder

The `GherkinFeature` builder provides a chainable, immutable API. Every method returns a new copy.

#### Scenario with Continuations

```swift
let feature = try GherkinFeature(title: "Cart")
    .addScenario("Add product")
    .given("an empty cart")
    .when("I add a product at 29\u{20AC}")
    .then("the cart contains 1 item")
    .and("the total is 29\u{20AC}")
    .but("no discount is applied")
    .build()
```

> Source: `Tests/GherkinGeneratorTests/Builder/GherkinFeatureBuilderTests.swift` -- `scenarioWithContinuations()`

#### Background

```swift
let feature = try GherkinFeature(title: "Orders")
    .background {
        $0.given("a logged-in user")
            .and("at least one existing order")
    }
    .addScenario("View orders")
    .when("I view my orders")
    .then("the list is displayed")
    .build()
```

> Source: `Tests/GherkinGeneratorTests/Builder/GherkinFeatureBuilderTests.swift` -- `backgroundClosure()`

#### Scenario Outline with Examples

```swift
let feature = try GherkinFeature(title: "Email Validation")
    .addOutline("Email format")
    .given("the email <email>")
    .when("I validate the format")
    .then("the result is <valid>")
    .examples([
        ["email", "valid"],
        ["test@example.com", "true"],
        ["invalid", "false"]
    ])
    .build()
```

> Source: `Tests/GherkinGeneratorTests/Builder/GherkinFeatureBuilderTests.swift` -- `scenarioOutline()`

#### Data Table

```swift
let feature = try GherkinFeature(title: "Pricing")
    .addScenario("Price by quantity")
    .given("the following prices")
    .table([
        ["Quantity", "Unit Price"],
        ["1-10", "10\u{20AC}"],
        ["11-50", "8\u{20AC}"]
    ])
    .when("I order 25 units")
    .then("the unit price is 8\u{20AC}")
    .build()
```

> Source: `Tests/GherkinGeneratorTests/Builder/GherkinFeatureBuilderTests.swift` -- `dataTable()`

#### Doc String

```swift
let feature = try GherkinFeature(title: "API")
    .addScenario("POST request")
    .given("a request body")
    .docString("{\"key\": \"value\"}", mediaType: "application/json")
    .then("status 201")
    .build()
```

> Source: `Tests/GherkinGeneratorTests/Builder/BuilderCoverageTests.swift` -- `docStringOnStep()`

#### Tags

```swift
let feature = try GherkinFeature(title: "Payment")
    .tags(["@payment", "@critical"])
    .addScenario("Credit card")
    .scenarioTags(["@card", "@slow"])
    .given("a validated cart")
    .then("payment is processed")
    .build()
```

> Source: `Tests/GherkinGeneratorTests/Builder/GherkinFeatureBuilderTests.swift` -- `tags()`

#### Mass Generation

```swift
let endpoints = ["users", "products", "orders"]
var builder = GherkinFeature(title: "API Smoke Tests")

for endpoint in endpoints {
    builder =
        builder
        .addScenario("GET /\(endpoint) returns 200")
        .given("the API is running")
        .when("I request GET /api/\(endpoint)")
        .then("the response status is 200")
}

let feature = try builder.build()
```

> Source: `Tests/GherkinGeneratorTests/Builder/GherkinFeatureBuilderTests.swift` -- `massGeneration()`

#### Validate and Export

```swift
let builder = GherkinFeature(title: "Export Test")
    .addScenario("Scenario")
    .given("a precondition")
    .then("a result")

try await builder.export(to: "output.feature")
```

> Source: `Tests/GherkinGeneratorTests/Builder/BuilderCoverageTests.swift` -- `exportWritesFile()`

### Parser

#### Parse `.feature` Files

```swift
let parser = GherkinParser()
let feature = try parser.parse(contentsOfFile: "login.feature")
```

> Source: `Sources/GherkinGenerator/Parser/GherkinParser.swift` -- doc comment

#### Parse Gherkin Strings

```swift
let parser = GherkinParser()
let feature = try parser.parse("""
    Feature: Login

      Scenario: Successful login
        Given a valid account
        When the user logs in
        Then the dashboard is displayed
    """)
```

> Source: `Sources/GherkinGenerator/Parser/GherkinParser.swift` -- `parse(_:)`

#### Language Detection

```swift
let parser = GherkinParser()
let language = parser.detectLanguage(in: "# language: fr\nFonctionnalit\u{00E9}: ...")
// language == .french
```

> Source: `Sources/GherkinGenerator/Parser/GherkinParser.swift` -- `detectLanguage(in:)`

### Importers

#### CSV Import

```swift
let csv = """
    Scenario,Given,When,Then
    Login,valid credentials,user logs in,dashboard shown
    """
let config = CSVImportConfiguration(
    scenarioColumn: "Scenario",
    givenColumn: "Given",
    whenColumn: "When",
    thenColumn: "Then"
)
let feature = try CSVParser(configuration: config).parse(csv, featureTitle: "Auth")
```

> Source: `Sources/GherkinGenerator/Parser/CSVParser.swift` -- doc comment

#### JSON Import

```swift
let parser = JSONFeatureParser()
let feature = try parser.parse(jsonString)
```

> Source: `Sources/GherkinGenerator/Parser/JSONFeatureParser.swift` -- doc comment

#### Plain Text Import

```swift
let text = """
    Shopping Cart
    Add a product
    Given an empty cart
    When I add a product
    Then the cart has 1 item
    ---
    Remove a product
    Given a cart with 1 item
    When I remove the product
    Then the cart is empty
    """
let feature = try PlainTextParser().parse(text)
```

> Source: `Sources/GherkinGenerator/Parser/PlainTextParser.swift` -- doc comment

#### Batch Import

```swift
let importer = BatchImporter()
let results = try await importer.importDirectory(at: "features/")
for result in results {
    switch result {
    case .success(let feature):
        print("Imported: \(feature.title)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

> Source: `Sources/GherkinGenerator/Parser/BatchImporter.swift` -- doc comment

### Validator

#### Validate a Feature

```swift
let validator = GherkinValidator()
let errors = validator.collectErrors(in: feature)
if errors.isEmpty {
    print("Feature is valid!")
}
```

> Source: `Sources/GherkinGenerator/Validator/GherkinValidator.swift` -- doc comment

#### Built-in Rules

| Rule | Description |
|------|-------------|
| `StructureRule` | Every scenario must have at least one `Given` and one `Then` step |
| `CoherenceRule` | No consecutive duplicate steps |
| `TagFormatRule` | Tag names must be non-empty and contain no spaces |
| `TableConsistencyRule` | All rows must have the same column count, no empty cells |
| `OutlinePlaceholderRule` | Every `<placeholder>` must match an Examples column header |

#### Custom Rules

```swift
struct MaxScenariosRule: ValidationRule {
    let maxCount: Int

    func validate(_ feature: Feature) -> [GherkinError] {
        if feature.children.count > maxCount {
            // Return appropriate errors
        }
        return []
    }
}

let validator = GherkinValidator(rules: [
    StructureRule(),
    TagFormatRule(),
    MaxScenariosRule(maxCount: 50),
])
```

> Source: `Sources/GherkinGenerator/Validator/ValidationRule.swift` and `Sources/GherkinGenerator/Validator/GherkinValidator.swift` -- doc comments

#### Batch Validation

```swift
let validator = BatchValidator()
let results = try await validator.validateDirectory(at: "features/")
for result in results {
    if result.isSuccess {
        print("\u{2713} \(result.featureTitle ?? result.path)")
    } else {
        print("\u{2717} \(result.path): \(result.errors)")
    }
}
```

> Source: `Sources/GherkinGenerator/Validator/BatchValidator.swift` -- doc comment

### Formatter

```swift
let formatter = GherkinFormatter(configuration: .default)
let output = formatter.format(feature)
```

> Source: `Sources/GherkinGenerator/Formatter/GherkinFormatter.swift` -- doc comment

#### Configuration Presets

| Preset | Description |
|--------|-------------|
| `.default` | 2-space indent, non-compact |
| `.compact` | Minimal whitespace |
| `.tabs` | Tab-based indentation (1 tab per level) |

### Exporter

#### Export to File

```swift
let exporter = GherkinExporter()
try await exporter.export(feature, to: "output.feature")
try await exporter.export(feature, to: "output.json", format: .json)
try await exporter.export(feature, to: "output.md", format: .markdown)
```

> Source: `Sources/GherkinGenerator/Exporter/GherkinExporter.swift` -- `export(_:to:format:)`

#### Render to String

```swift
let exporter = GherkinExporter()
let gherkin = try exporter.render(feature, format: .feature)
let json = try exporter.render(feature, format: .json)
let markdown = try exporter.render(feature, format: .markdown)
```

> Source: `Sources/GherkinGenerator/Exporter/GherkinExporter.swift` -- `render(_:format:)`

### Streaming

The `StreamingExporter` actor writes features line-by-line without loading the entire output in memory.

```swift
let exporter = StreamingExporter()
try await exporter.export(largeFeature, to: "large.feature")
```

> Source: `Sources/GherkinGenerator/Exporter/GherkinExporter.swift` -- `StreamingExporter` doc comment

#### Line-by-Line Stream

```swift
let exporter = StreamingExporter()
for await line in exporter.lines(for: feature) {
    print(line)
}
```

> Source: `Sources/GherkinGenerator/Exporter/GherkinExporter.swift` -- `lines(for:)`

#### Progress Reporting

```swift
let exporter = StreamingExporter()
for await progress in await exporter.exportWithProgress(feature, to: path) {
    print("\(Int(progress.fractionCompleted * 100))%")
}
```

> Source: `Sources/GherkinGenerator/Exporter/GherkinExporter.swift` -- `exportWithProgress(_:to:)`

### Languages

GherkinGenerator supports 70+ languages from the official Gherkin specification.

```swift
// Use a built-in language shortcut
let feature = try GherkinFeature(title: "Authentification", language: .french)
    .addScenario("Connexion")
    .given("un compte valide")
    .when("je me connecte")
    .then("je suis connect\u{00E9}")
    .build()
```

> Source: `Tests/GherkinGeneratorTests/Builder/GherkinFeatureBuilderTests.swift` -- `multiLanguage()`

#### Available Shortcuts

`.english`, `.french`, `.german`, `.spanish`, `.italian`, `.portuguese`, `.japanese`, `.chinese`, `.russian`, `.arabic`, `.korean`, `.dutch`, `.polish`, `.turkish`, `.swedish`

#### Lookup by Code

```swift
let language = GherkinLanguage(code: "ja") // Japanese
let allLanguages = GherkinLanguage.all     // 70+ languages
```

> Source: `Sources/GherkinGenerator/Language/GherkinLanguage.swift` -- `init?(code:)` and `all`

#### Accessing Keywords

```swift
let lang = GherkinLanguage.french
print(lang.keywords.feature) // ["Fonctionnalit\u{00E9}"]
print(lang.keywords.given)   // ["Soit ", "Etant donn\u{00E9} ", ...]
```

> Source: `Sources/GherkinGenerator/Language/GherkinLanguage.swift` -- doc comment

## Architecture

```
Sources/GherkinGenerator/
    Model/        # Feature, Scenario, Step, Tag, DataTable, DocString, ...
    Builder/      # GherkinFeature fluent builder
    Parser/       # GherkinParser, CSVParser, JSONFeatureParser, PlainTextParser, BatchImporter
    Validator/    # GherkinValidator, ValidationRule, built-in rules, BatchValidator
    Formatter/    # GherkinFormatter, FormatterConfiguration
    Exporter/     # GherkinExporter, StreamingExporter, ExportFormat
    Language/     # GherkinLanguage, LanguageKeywords, GherkinLanguageRegistry
```

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contact

[Atelier Socle](https://www.atelier-socle.com/en/contact)
