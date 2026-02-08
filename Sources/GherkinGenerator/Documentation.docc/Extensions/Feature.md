# ``GherkinGenerator/Feature``

An immutable value representing a complete Gherkin feature document.

## Overview

`Feature` is the core model type produced by ``GherkinFeature/build()``, ``GherkinParser/parse(_:)``, and other importers. It holds the title, language, tags, background, and all children (scenarios, outlines, and rules) of a `.feature` file.

```swift
let feature = try GherkinFeature(title: "Login")
    .addScenario("Successful login")
    .given("a valid account")
    .when("the user logs in")
    .then("the dashboard is displayed")
    .build()

print(feature.title)       // "Login"
print(feature.scenarios)   // [Scenario(title: "Successful login", ...)]
```

Pass a `Feature` to ``GherkinFormatter/format(_:)`` for pretty-printed Gherkin, ``GherkinValidator/validate(_:)`` for structural checks, or ``GherkinExporter/render(_:format:)`` for multi-format export.

## Topics

### Properties

- ``title``
- ``language``
- ``tags``
- ``description``
- ``background``
- ``children``
- ``comments``

### Convenience Accessors

- ``scenarios``
- ``outlines``
- ``rules``
