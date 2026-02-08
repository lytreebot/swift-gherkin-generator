# Command-Line Interface

Compose, validate, and convert Gherkin `.feature` files from the terminal with `gherkin-gen`.

@Metadata {
    @PageKind(article)
}

## Overview

`gherkin-gen` is a command-line tool that exposes the core capabilities of GherkinGenerator — generation, validation, parsing, export, batch processing, format conversion, and language listing — as shell commands. It is built on top of `swift-argument-parser`.

## Installation

### make install

```bash
make install
```

Builds a release binary and copies it to `/usr/local/bin`. Override the install path with `PREFIX`:

```bash
make install PREFIX=/opt/local/bin
```

### Scripts/install.sh

```bash
./Scripts/install.sh
```

Detects the platform, checks for a Swift toolchain, builds a release binary, and installs it to `/usr/local/bin`.

### Manual Build

```bash
swift build -c release
cp .build/release/gherkin-gen /usr/local/bin/
```

### Homebrew (coming soon)

```bash
brew tap atelier-socle/tools
brew install gherkin-gen
```

## Commands

### generate

Generate a `.feature` file from command-line arguments. Uses ``GherkinFeature`` internally to build the feature.

**Options:**

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--title` | String | Yes | — | Feature title |
| `--scenario` | String | Yes | — | Scenario title |
| `--given` | String | No | — | Given step (repeatable) |
| `--when` | String | No | — | When step (repeatable) |
| `--then` | String | No | — | Then step (repeatable) |
| `--tag` | String | No | — | Feature-level tag (repeatable) |
| `--language` | String | No | `en` | Language code |
| `--output` | String | No | stdout | Output file path |

**Examples:**

```bash
gherkin-gen generate \
    --title "User Authentication" \
    --scenario "Successful login" \
    --given "a valid account" \
    --when "the user logs in" \
    --then "the dashboard is displayed" \
    --output login.feature
```

```bash
gherkin-gen generate \
    --title "Shopping Cart" \
    --scenario "Add items" \
    --given "an empty cart" \
    --when "I add a product" \
    --when "I add another product" \
    --then "the cart contains 2 items" \
    --tag "@cart" --tag "@smoke" \
    --language fr
```

### validate

Validate one or more `.feature` files for structural correctness. Accepts a single file or a directory (validated recursively). Uses ``GherkinValidator`` with all default rules, and ``BatchValidator`` for directories.

**Arguments:**

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `<path>` | String | Yes | Path to a `.feature` file or directory |

**Flags:**

| Flag | Description |
|------|-------------|
| `--strict` | Use all default validation rules (default behavior) |
| `--quiet` | Only show errors, suppress success messages |

**Examples:**

```bash
gherkin-gen validate login.feature
```

```bash
gherkin-gen validate features/ --quiet
```

### parse

Parse a `.feature` file and display its structure. Shows a human-readable summary or JSON output. Uses ``GherkinParser`` for parsing and ``GherkinExporter`` for JSON rendering.

**Arguments:**

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `<path>` | String | Yes | Path to a `.feature` file |

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--format` | `summary` \| `json` | `summary` | Output format |

**Examples:**

```bash
gherkin-gen parse login.feature
```

```bash
gherkin-gen parse login.feature --format json
```

### export

Export a `.feature` file to another format. Uses ``GherkinExporter`` to render the output.

**Arguments:**

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `<path>` | String | Yes | Path to a `.feature` file |

**Options:**

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--format` | `feature` \| `json` \| `markdown` | Yes | — | Export format |
| `--output` | String | No | stdout | Output file path |

**Examples:**

```bash
gherkin-gen export login.feature --format json --output login.json
```

```bash
gherkin-gen export login.feature --format markdown
```

### batch-export

Batch-export all `.feature` files from a source directory to a target directory. Scans recursively, exports in parallel. Uses ``BatchExporter`` internally.

**Arguments:**

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `<directory>` | String | Yes | Source directory containing `.feature` files |

**Options:**

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--output` | String | Yes | — | Output directory |
| `--format` | `feature` \| `json` \| `markdown` | No | `feature` | Export format |

**Examples:**

```bash
gherkin-gen batch-export features/ --output json-output/ --format json
```

```bash
gherkin-gen batch-export features/ --output docs/ --format markdown
```

### convert

Convert a CSV, JSON, TXT, or XLSX file to `.feature` format. The input format is detected from the file extension. Uses ``CSVParser``, ``JSONFeatureParser``, ``PlainTextParser``, or ``ExcelParser`` depending on the input type.

**Arguments:**

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `<path>` | String | Yes | Path to a `.csv`, `.json`, `.txt`, or `.xlsx` file |

**Options:**

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--title` | String | CSV/TXT/XLSX | — | Feature title |
| `--output` | String | No | stdout | Output file path |
| `--delimiter` | String | No | `,` | CSV delimiter character |
| `--scenario-column` | String | No | `Scenario` | CSV/XLSX column for scenarios |
| `--given-column` | String | No | `Given` | CSV/XLSX column for Given steps |
| `--when-column` | String | No | `When` | CSV/XLSX column for When steps |
| `--then-column` | String | No | `Then` | CSV/XLSX column for Then steps |
| `--tag-column` | String | No | — | CSV/XLSX column for tags |
| `--sheet` | Int | No | `0` | Worksheet index for Excel files |

**Examples:**

```bash
gherkin-gen convert tests.csv --title "E-Commerce" --output tests.feature
```

```bash
gherkin-gen convert tests.xlsx \
    --title "Auth" \
    --scenario-column "Test Case" \
    --given-column "Precondition" \
    --when-column "Action" \
    --then-column "Expected" \
    --tag-column "Labels" \
    --sheet 1 \
    --output auth.feature
```

```bash
gherkin-gen convert exported.json --output restored.feature
```

```bash
gherkin-gen convert notes.txt --title "Quick Import" --delimiter ";"
```

### languages

List all supported Gherkin languages or show keywords for a specific language. Data comes from the official `gherkin-languages.json` via ``GherkinLanguage``.

**Options:**

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--code` | String | No | — | Show keywords for a specific language code |

**Examples:**

```bash
gherkin-gen languages
```

```bash
gherkin-gen languages --code fr
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error — validation failures, missing file, unsupported format, invalid arguments |
