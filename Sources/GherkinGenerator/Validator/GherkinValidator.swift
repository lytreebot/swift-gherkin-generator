/// A stateless validator for Gherkin features.
///
/// `GherkinValidator` checks a ``Feature`` for structural correctness,
/// coherence, and compliance with Gherkin conventions. It reports
/// all issues found, not just the first one.
///
/// ```swift
/// let validator = GherkinValidator()
/// let errors = validator.collectErrors(in: feature)
/// if errors.isEmpty {
///     print("Feature is valid!")
/// }
/// ```
///
/// ## Custom Rules
///
/// Add custom validation rules by conforming to ``ValidationRule``:
///
/// ```swift
/// let validator = GherkinValidator(rules: [
///     StructureRule(),
///     TagFormatRule(),
///     MyCustomRule(),
/// ])
/// ```
public struct GherkinValidator: Sendable {
    /// The validation rules to apply.
    public let rules: [any ValidationRule]

    /// Creates a validator with the default set of rules.
    public init() {
        self.rules = Self.defaultRules
    }

    /// Creates a validator with custom rules.
    ///
    /// - Parameter rules: The validation rules to apply.
    public init(rules: [any ValidationRule]) {
        self.rules = rules
    }

    /// Validates a feature and throws on the first error.
    ///
    /// - Parameter feature: The feature to validate.
    /// - Throws: ``GherkinError`` for the first validation failure.
    public func validate(_ feature: Feature) throws {
        let errors = collectErrors(in: feature)
        if let first = errors.first {
            throw first
        }
    }

    /// Collects all validation errors in a feature.
    ///
    /// Unlike ``validate(_:)``, this method returns all issues found
    /// rather than stopping at the first one.
    ///
    /// - Parameter feature: The feature to validate.
    /// - Returns: An array of validation errors (empty if valid).
    public func collectErrors(in feature: Feature) -> [GherkinError] {
        var errors: [GherkinError] = []
        for rule in rules {
            errors.append(contentsOf: rule.validate(feature))
        }
        return errors
    }

    /// The default set of validation rules.
    public static let defaultRules: [any ValidationRule] = [
        StructureRule(),
        CoherenceRule(),
        TagFormatRule(),
        TableConsistencyRule(),
        OutlinePlaceholderRule(),
    ]
}

// MARK: - Built-in Rules

/// Validates scenario structure (Given/Then requirements).
public struct StructureRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        // TODO: Implement — check each scenario has Given + Then
        []
    }
}

/// Validates coherence (no consecutive duplicate steps).
public struct CoherenceRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        // TODO: Implement
        []
    }
}

/// Validates tag format (must start with @, no spaces).
public struct TagFormatRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        // TODO: Implement
        []
    }
}

/// Validates data table consistency (column counts, no empty cells).
public struct TableConsistencyRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        // TODO: Implement
        []
    }
}

/// Validates Scenario Outline placeholders match Examples columns.
public struct OutlinePlaceholderRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        // TODO: Implement
        []
    }
}
