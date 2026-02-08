# Validation

Validate Gherkin features for structural correctness, coherence, and convention compliance.

## Overview

``GherkinValidator`` checks a ``Feature`` for errors using a set of composable rules. It reports all issues found, not just the first, making it easy to fix everything in one pass.

## Validate a Feature

```swift
let validator = GherkinValidator()
let errors = validator.collectErrors(in: feature)
if errors.isEmpty {
    print("Feature is valid!")
}
```

Use ``GherkinValidator/validate(_:)`` to throw on the first error instead:

```swift
let validator = GherkinValidator()
try validator.validate(feature)
```

## Built-in Rules

The default validator applies 5 rules:

| Rule | Description |
|------|-------------|
| ``StructureRule`` | Every scenario must have at least one `Given` and one `Then` step |
| ``CoherenceRule`` | No consecutive duplicate steps |
| ``TagFormatRule`` | Tag names must be non-empty and contain no spaces |
| ``TableConsistencyRule`` | All rows must have the same column count, no empty cells |
| ``OutlinePlaceholderRule`` | Every `<placeholder>` must match an Examples column header |

## Custom Rules

Conform to the ``ValidationRule`` protocol to add project-specific checks:

```swift
struct MaxScenariosRule: ValidationRule {
    let maxCount: Int

    func validate(_ feature: Feature) -> [GherkinError] {
        if feature.children.count > maxCount {
            return [.emptyFeature]
        }
        return []
    }
}
```

Pass any combination of rules to the validator:

```swift
let validator = GherkinValidator(rules: [
    StructureRule(),
    TagFormatRule(),
    MaxScenariosRule(maxCount: 50),
])
let errors = validator.collectErrors(in: feature)
```

## Batch Validation

``BatchValidator`` is an actor that parses and validates all `.feature` files in a directory in parallel:

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

Use ``BatchValidator/streamValidation(at:recursive:)`` for progressive reporting via `AsyncStream`:

```swift
let validator = BatchValidator()
for await result in await validator.streamValidation(at: "features/") {
    if result.isSuccess {
        print("✓ \(result.featureTitle ?? result.path)")
    }
}
```
