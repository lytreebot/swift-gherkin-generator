# ``GherkinGenerator/GherkinParser``

A recursive descent parser for Gherkin `.feature` files.

## Overview

`GherkinParser` reads `.feature` file content and produces an immutable ``Feature`` value. It automatically detects the language from a `# language:` header, falling back to English when no header is present.

```swift
let parser = GherkinParser()
let feature = try parser.parse(contentsOfFile: "login.feature")
```

The parser supports all Gherkin keywords — `Feature`, `Scenario`, `Scenario Outline`, `Background`, `Rule`, `Examples`, `Given`, `When`, `Then`, `And`, `But`, and `*` — in 70+ languages.

## Topics

### Creating a Parser

- ``init()``

### Parsing

- ``parse(_:)``
- ``parse(contentsOfFile:)``

### Language Detection

- ``detectLanguage(in:)``
