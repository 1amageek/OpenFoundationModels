// OpenFoundationModelsMacros - Macro definitions for Foundation Models
// TODO: Implement macros when Swift syntax is stable

/// Constraints for guide properties
public enum GuideConstraint {
    case range(ClosedRange<Int>)
    case count(Int)
    case enumValues([String])
    case pattern(String)
}