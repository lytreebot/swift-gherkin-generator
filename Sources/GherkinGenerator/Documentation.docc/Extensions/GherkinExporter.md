# ``GherkinGenerator/GherkinExporter``

A stateless exporter that writes Gherkin features to `.feature`, JSON, or Markdown.

## Overview

`GherkinExporter` renders a ``Feature`` to a string or writes it to disk in one of three formats: `.feature` (standard Gherkin), `.json` (Codable), or `.markdown` (documentation). For `.feature` output, it delegates to a ``GherkinFormatter`` whose configuration controls indentation and spacing.

```swift
let exporter = GherkinExporter()
let gherkin = try exporter.render(feature, format: .feature)
let json = try exporter.render(feature, format: .json)
let markdown = try exporter.render(feature, format: .markdown)
```

Use ``export(_:to:format:)`` to write directly to a file, or ``render(_:format:)`` to get a `String` for further processing. For large features, consider ``StreamingExporter`` instead.

## Topics

### Creating an Exporter

- ``init(formatter:)``

### Exporting

- ``export(_:to:format:)``
- ``render(_:format:)``

### Configuration

- ``formatter``
