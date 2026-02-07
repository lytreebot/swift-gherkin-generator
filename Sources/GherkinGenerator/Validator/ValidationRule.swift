/// A rule that validates a Gherkin feature.
///
/// Conform to this protocol to create custom validation rules
/// that can be added to a ``GherkinValidator``.
///
/// ```swift
/// struct MaxScenariosRule: ValidationRule {
///     let maxCount: Int
///
///     func validate(_ feature: Feature) -> [GherkinError] {
///         if feature.children.count > maxCount {
///             // Return appropriate errors
///         }
///         return []
///     }
/// }
/// ```
public protocol ValidationRule: Sendable {
    /// Validates a feature and returns any errors found.
    ///
    /// - Parameter feature: The feature to validate.
    /// - Returns: An array of errors (empty if the feature passes this rule).
    func validate(_ feature: Feature) -> [GherkinError]
}
