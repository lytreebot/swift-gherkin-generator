# ``GherkinGenerator/GherkinValidator``

A rule-based validation engine for Gherkin features.

## Overview

`GherkinValidator` checks a ``Feature`` against a set of composable rules. The default configuration applies five built-in rules covering structure, coherence, tag format, table consistency, and outline placeholders.

```swift
let validator = GherkinValidator()
let errors = validator.collectErrors(in: feature)
```

Use ``validate(_:)`` to throw on the first error, or ``collectErrors(in:)`` to gather all issues for batch reporting. Extend validation by conforming to the ``ValidationRule`` protocol.

## Topics

### Creating a Validator

- ``init()``
- ``init(rules:)``

### Validating

- ``validate(_:)``
- ``collectErrors(in:)``

### Default Rules

- ``defaultRules``
