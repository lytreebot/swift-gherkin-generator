# Parsing and Importing

Import Gherkin features from `.feature` files, CSV, JSON, plain text, and Excel.

## Overview

GherkinGenerator provides parsers for multiple input formats. Each parser produces an immutable ``Feature`` value that can be validated, formatted, or exported.

## Parse .feature Files

``GherkinParser`` uses a recursive descent approach. It automatically detects the language from a `# language:` header or falls back to English:

```swift
let parser = GherkinParser()
let feature = try parser.parse(contentsOfFile: "login.feature")
```

Parse Gherkin source directly from a string:

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

Detect the language of a Gherkin source without parsing it:

```swift
let parser = GherkinParser()
let language = parser.detectLanguage(in: "# language: fr\nFonctionnalité: ...")
```

## CSV Import

``CSVParser`` maps CSV columns to Gherkin step types via ``CSVImportConfiguration``. Each row becomes a scenario:

```swift
let csv = """
    Scenario,Given,When,Then,Tags
    Search products,the catalog is loaded,the user searches for laptop,15 results are shown,@search
    Add to cart,an empty cart,the user adds an item,the cart has 1 item,@cart @smoke
    Checkout,a cart with items,the user checks out,the order is confirmed,@checkout
    """
let config = CSVImportConfiguration(
    scenarioColumn: "Scenario",
    givenColumn: "Given",
    whenColumn: "When",
    thenColumn: "Then",
    tagColumn: "Tags"
)
let feature = try CSVParser(configuration: config)
    .parse(csv, featureTitle: "E-Commerce CSV Import")
```

Custom delimiters are supported via the `delimiter` parameter on ``CSVImportConfiguration``.

## JSON Import

``JSONFeatureParser`` decodes JSON produced by ``GherkinExporter``, providing a round-trip guarantee — exporting to JSON and importing back produces an identical ``Feature``:

```swift
let parser = JSONFeatureParser()
let feature = try parser.parse(jsonString)
```

Also supports `parse(data:)` for raw `Data` and `parse(contentsOfFile:)` for file paths.

## Plain Text Import

``PlainTextParser`` parses informal plain text into scenarios. Lines starting with `Given`/`When`/`Then` become steps, `---` separates scenarios:

```swift
let text = """
    Given the product catalog is loaded
    When the user searches for "laptop"
    Then 15 results are displayed
    ---
    Given an empty cart
    When the user adds a product
    Then the cart contains 1 item
    """
let feature = try PlainTextParser()
    .parse(text, featureTitle: "E-Commerce Text Import")
```

All prefixes and the separator are configurable via ``PlainTextImportConfiguration``.

## Excel Import

``ExcelParser`` reads `.xlsx` files natively using a built-in ZIP/OOXML reader. It works cross-platform on macOS, iOS, and Linux via the system `zlib` library. Configure column mapping with ``ExcelImportConfiguration``:

```swift
let config = ExcelImportConfiguration(
    scenarioColumn: "Scenario",
    givenColumn: "Given",
    whenColumn: "When",
    thenColumn: "Then"
)
let data = try Data(contentsOf: URL(fileURLWithPath: "tests.xlsx"))
let feature = try ExcelParser(configuration: config)
    .parse(data, featureTitle: "Auth")
```

An optional `tagColumn` parameter maps a column to scenario-level tags (space or comma separated). The `sheetIndex` parameter selects which worksheet to read (defaults to `0`).

## Batch Import

``BatchImporter`` is an actor that scans a directory for `.feature` files and parses them in parallel using `TaskGroup`:

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

Use `streamDirectory(at:)` for progressive processing via `AsyncStream`:

```swift
let importer = BatchImporter()
for await result in await importer.streamDirectory(at: tempDir) {
    switch result {
    case .success(let feature):
        print("Parsed: \(feature.title)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```
