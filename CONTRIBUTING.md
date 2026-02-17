# Contributing to GherkinGenerator

Thank you for your interest in contributing to GherkinGenerator! This guide will help you get started.

## Getting Started

### Prerequisites

- **Swift 6.2+** (Xcode 26.2+)
- **macOS 14+** (for development)
- **SwiftLint** -- `brew install swiftlint`
- **swift-format** -- included with the Swift toolchain

### Clone and Build

```bash
git clone https://github.com/atelier-socle/swift-gherkin-generator.git
cd swift-gherkin-generator
swift build
```

### Run Tests

```bash
swift test
```

All tests use **Swift Testing** (`@Test`, `@Suite`, `#expect`). XCTest is not used.

## Development Workflow

### Branch Model

| Branch | Purpose |
|--------|---------|
| `main` | Stable, protected. All CI checks must pass. |
| `feat/<name>` | Feature branches |
| `fix/<name>` | Bug fix branches |
| `docs/<name>` | Documentation branches |

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add Scenario Outline support to builder API
fix: correct pipe alignment in data tables with Unicode
docs: add DocC guide for multi-language export
test: add parser tests for French keywords
chore: update swift-format configuration
refactor: extract table alignment into dedicated formatter
perf: optimize streaming export for large features
```

### Code Quality Pipeline

Before submitting a pull request, run the full pipeline:

```bash
# 1. Lint
swiftlint lint --quiet

# 2. Format
swift-format lint -r Sources/ Tests/

# 3. Build
swift build

# 4. Test
swift test
```

All four steps must pass with zero errors.

## Coding Standards

### Swift 6.2 Strict Concurrency

- All public types must be `Sendable`
- Use `async/await` for I/O operations
- Use `AsyncStream` / `AsyncSequence` for streaming
- Use structured concurrency (`TaskGroup`) for batch operations
- No `@unchecked Sendable` without justification

### Style

- **Max line length:** 120 characters
- **Indentation:** spaces (configured in `.swift-format`)
- **Prefer value types** (structs) over classes
- **Explicit access control** on all declarations (`public`, `internal`, `private`)
- No force unwrapping (`!`) in production code
- No `try!` or `as!` in production code
- Use `guard` for early exits

### Naming

- Types: `UpperCamelCase`
- Properties/methods: `lowerCamelCase`
- Protocols: adjective or noun (`Validatable`, `Exportable`)
- Enum cases: `lowerCamelCase`
- Files: match primary type name

### Error Handling

- All errors use the `GherkinError` enum conforming to `LocalizedError`
- Provide context in error messages (line number, scenario name)
- Validation errors are collectible (report all issues, not just the first)

### Documentation

- Every `public` symbol must have a DocC comment
- Use `- Parameters:`, `- Returns:`, `- Throws:` format

## Testing Standards

- **Framework:** Swift Testing only (`@Test`, `@Suite`, `#expect`, `#require`)
- **Coverage target:** > 96%
- Test both success and failure paths
- Test edge cases (empty inputs, special characters, large inputs)
- Use parameterized tests (`@Test(arguments:)`) where appropriate

### Test Organization

```
Tests/GherkinGeneratorTests/
    Model/           # Model type tests
    Builder/         # Builder API tests
    Parser/          # Parser tests (one per format)
    Validator/       # Validation rule tests
    Formatter/       # Formatter output tests
    Exporter/        # Export format tests
    Language/        # Language keyword tests
    Integration/     # End-to-end workflow tests
    Fixtures/        # Test .feature files, CSVs, JSONs
```

## Architecture

```
Sources/GherkinGenerator/
    Model/        # Value types: Feature, Scenario, Step, Tag, ...
    Builder/      # Fluent chainable API
    Parser/       # Import from .feature, CSV, JSON, plain text
    Validator/    # Validation engine with extensible rules
    Formatter/    # Pretty-print with configurable indentation
    Exporter/     # Export to .feature, JSON, Markdown
    Language/     # 70+ language support
```

### Key Principles

- **No third-party dependencies** -- only Apple/Swift official packages
- **Protocol-oriented design** -- `ValidationRule`, `Sendable`, `Codable`
- **Immutable builders** -- every method returns a new copy
- **No singletons** -- use dependency injection
- **No global mutable state**
- **No `print()`** in library code

## Submitting a Pull Request

1. Fork the repository
2. Create your branch from `main` (`git checkout -b feat/my-feature`)
3. Make your changes following the coding standards above
4. Ensure the full pipeline passes (lint, format, build, test)
5. Commit with a conventional commit message
6. Push to your fork and open a pull request
7. Describe your changes and link any related issues

## Reporting Issues

Please report bugs and feature requests via [GitHub Issues](https://github.com/atelier-socle/swift-gherkin-generator/issues).

## License

By contributing to this project, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).

## Contact

[Atelier Socle](https://www.atelier-socle.com/en/contact)
