# Getting Started

Set up GherkinGenerator in your Swift project and compose your first feature.

## Overview

This guide walks you through adding GherkinGenerator to your Swift package, building your first feature with the fluent API, and exporting it to a `.feature` file.

### Requirements

- Swift 6.2+ with strict concurrency
- Xcode 26+ or a compatible Swift toolchain
- Swift Package Manager
- **Platforms**: iOS 17+ · macOS 14+ · tvOS 17+ · watchOS 10+ · visionOS 1+ · Mac Catalyst 17+ · Linux

## Installation

Add GherkinGenerator to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/atelier-socle/swift-gherkin-generator.git", from: "0.1.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["GherkinGenerator"]
)
```

## Your First Feature

Build a feature with the ``GherkinFeature`` fluent builder and produce an immutable ``Feature`` value:

```swift
import GherkinGenerator

let feature = try GherkinFeature(title: "User Authentication")
    .tags(["auth"])
    .background {
        $0.given("the login page is displayed")
    }
    .addScenario("Successful login")
    .given("a valid account")
    .when("the user logs in")
    .then("the dashboard is displayed")
    .build()
```

The ``GherkinFeature`` builder is immutable — every method returns a new copy. Call `.build()` to finalize the feature into a ``Feature`` value.

## Build, Validate, Export

Combine building, validation, and file export in a single workflow:

```swift
let feature = try GherkinFeature(title: "User Authentication")
    .tags(["auth"])
    .background {
        $0.given("the login page is displayed")
    }
    .addScenario("Successful login")
    .given("a valid account")
    .when("the user logs in")
    .then("the dashboard is displayed")
    .build()

// Validate
let validator = GherkinValidator()
let errors = validator.collectErrors(in: feature)

// Format
let formatter = GherkinFormatter()
let output = formatter.format(feature)

// Export
let exporter = GherkinExporter()
let gherkin = try exporter.render(feature, format: .feature)
let json = try exporter.render(feature, format: .json)
let markdown = try exporter.render(feature, format: .markdown)
```

Or use the convenience method that builds, validates, and exports in one call:

```swift
let builder = GherkinFeature(title: "Export Test")
    .addScenario("Scenario")
    .given("a precondition")
    .then("a result")

try await builder.export(to: "output.feature")
```

## Parse Existing Files

Import existing `.feature` files with ``GherkinParser``:

```swift
let parser = GherkinParser()
let feature = try parser.parse(contentsOfFile: "login.feature")
```

## Next Steps

- <doc:BuildingFeatures> — Learn the full fluent builder API
- <doc:ParsingAndImporting> — Import from CSV, JSON, plain text, and Excel
- <doc:ValidationGuide> — Understand the validation engine and custom rules
- <doc:FormattingAndExporting> — Format and export features
