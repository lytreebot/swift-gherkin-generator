# Streaming and Batch Processing

Export, import, and validate features at directory scale with parallel I/O and streaming progress.

## Overview

GherkinGenerator provides actor-based processors for working with many features at once. ``StreamingExporter`` writes large features line-by-line without loading the entire output in memory. ``BatchExporter``, ``BatchImporter``, and ``BatchValidator`` operate on directories of `.feature` files in parallel using structured concurrency.

## Streaming Export

### Line-by-Line Export

``StreamingExporter`` writes features to disk one line at a time, making it suitable for features with hundreds of scenarios:

```swift
let exporter = StreamingExporter()
try await exporter.export(feature, to: "large-feature.feature")
```

### Progress Tracking

Use ``StreamingExporter/exportWithProgress(_:to:)`` to receive ``ExportProgress`` values as each child (scenario, outline, or rule) is written:

```swift
let exporter = StreamingExporter()
for await progress in await exporter.exportWithProgress(feature, to: "output.feature") {
    print("Progress: \(Int(progress.fractionCompleted * 100))%")
}
```

### Lines as AsyncStream

Use ``StreamingExporter/lines(for:)`` to get formatted lines without writing to disk:

```swift
let exporter = StreamingExporter()
for await line in await exporter.lines(for: feature) {
    print(line)
}
```

## Batch Export

``BatchExporter`` writes an array of features to a directory in parallel. Each feature is saved as a separate file with a slug-based filename:

```swift
let exporter = BatchExporter()
let results = try await exporter.exportAll(features, to: "output/")
for result in results {
    switch result {
    case .success(let path):
        print("Exported: \(path)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

Errors on individual files do not stop the rest of the batch.

### Batch Export with Progress

Use ``BatchExporter/exportAllWithProgress(_:to:format:)`` for progressive reporting via `AsyncStream`:

```swift
let exporter = BatchExporter()
for await progress in await exporter.exportAllWithProgress(features, to: "output/") {
    print("[\(Int(progress.fractionCompleted * 100))%] \(progress.featureTitle) → \(progress.outputPath)")
}
```

Each ``BatchExportProgress`` value includes the feature title, index, total count, fraction completed, and output path.

### Export Formats

Batch export supports all three formats:

```swift
let exporter = BatchExporter()
try await exporter.exportAll(features, to: "json-output/", format: .json)
try await exporter.exportAll(features, to: "md-output/", format: .markdown)
```

## Batch Import

``BatchImporter`` scans a directory for `.feature` files and parses them in parallel using `TaskGroup`:

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

### Recursive Import

Pass `recursive: true` to scan subdirectories:

```swift
let results = try await importer.importDirectory(at: "features/", recursive: true)
```

### Streaming Import

Use ``BatchImporter/streamDirectory(at:recursive:)`` for progressive processing via `AsyncStream`:

```swift
let importer = BatchImporter()
for await result in await importer.streamDirectory(at: "features/") {
    switch result {
    case .success(let feature):
        print("Parsed: \(feature.title)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Batch Validation

``BatchValidator`` parses and validates all `.feature` files in a directory in parallel:

```swift
let validator = BatchValidator()
let results = try await validator.validateDirectory(at: "features/")
for result in results {
    if result.isSuccess {
        print("✓ \(result.featureTitle ?? result.path)")
    } else {
        print("✗ \(result.path): \(result.errors)")
    }
}
```

Each ``BatchValidationResult`` includes the file path, parsed feature title, validation errors, and a computed ``BatchValidationResult/isSuccess`` property.

### Streaming Validation

Use ``BatchValidator/streamValidation(at:recursive:)`` for progressive reporting:

```swift
let validator = BatchValidator()
for await result in await validator.streamValidation(at: "features/") {
    if result.isSuccess {
        print("✓ \(result.featureTitle ?? result.path)")
    }
}
```

## Custom Configuration

All batch actors accept custom instances of their underlying processors:

```swift
// Custom formatter for batch export
let formatter = GherkinFormatter(configuration: .compact)
let exporter = BatchExporter(formatter: formatter)

// Custom parser for batch import
let parser = GherkinParser()
let importer = BatchImporter(parser: parser)

// Custom validator for batch validation
let validator = GherkinValidator(rules: [StructureRule(), TagFormatRule()])
let batchValidator = BatchValidator(validator: validator)
```

## Concurrency Safety

All batch processors are actors, ensuring thread-safe access to shared state. They use `TaskGroup` internally for parallel I/O:

- ``BatchExporter`` — actor
- ``BatchImporter`` — actor
- ``BatchValidator`` — actor
- ``StreamingExporter`` — actor

All progress types are `Sendable`:

- ``ExportProgress``
- ``BatchExportProgress``
- ``BatchValidationResult``
