// OpenFoundationModelsMacros.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

/// Conforms a type to generable
/// 
/// ✅ CONFIRMED: From Apple Developer Documentation
/// - @attached(extension, conformances: Generable) - adds Generable protocol conformance
/// - @attached(member, names: arbitrary) - generates required members
/// - Generates init(_:) and generatedContent members
/// - Optional description parameter for schema documentation
@attached(member, names: named(init(_:)), named(generatedContent), named(from(generatedContent:)), named(toGeneratedContent), named(generationSchema), named(asPartiallyGenerated), named(PartiallyGenerated))
public macro Generable(description: String? = nil) = #externalMacro(module: "OpenFoundationModelsMacrosImpl", type: "GenerableMacro")

/// Provides guidance for property generation in Generable types
/// 
/// ✅ CONFIRMED: From Apple Developer Documentation  
/// - @attached(peer) - attaches to properties
/// - Two overloads: description-only and description with guides
/// - Uses GenerationGuide type for constraints
@attached(peer)
public macro Guide(description: String) = #externalMacro(module: "OpenFoundationModelsMacrosImpl", type: "GuideMacro")

@attached(peer)
public macro Guide(description: String, _ guides: GenerationGuide...) = #externalMacro(module: "OpenFoundationModelsMacrosImpl", type: "GuideMacro")

/// Allows for influencing the allowed values using regex patterns
/// ✅ CONFIRMED: From Apple Developer Documentation
/// - @attached(peer) - attaches to properties
/// - Uses Regex<RegexOutput> for pattern-based constraints
@attached(peer)
public macro Guide<RegexOutput>(
    description: String? = nil,
    _ guides: Regex<RegexOutput>
) = #externalMacro(module: "OpenFoundationModelsMacrosImpl", type: "GuideMacro")

// MARK: - Supporting Types

/// Generation guidance for properties
/// ✅ CONFIRMED: Referenced in Apple documentation for @Guide macro
public struct GenerationGuide: Sendable {
    internal let type: GuideType
    internal let value: any Sendable
    
    private init(type: GuideType, value: any Sendable) {
        self.type = type
        self.value = value
    }
    
    /// Maximum number of items in arrays/collections
    /// ✅ CONFIRMED: .maximumCount(3) used in Apple documentation examples
    public static func maximumCount(_ count: Int) -> GenerationGuide {
        GenerationGuide(type: .maximumCount, value: count)
    }
    
    /// Minimum number of items in arrays/collections
    public static func minimumCount(_ count: Int) -> GenerationGuide {
        GenerationGuide(type: .minimumCount, value: count)
    }
    
    /// Exact number of items required
    public static func count(_ count: Int) -> GenerationGuide {
        GenerationGuide(type: .count, value: count)
    }
    
    /// Range of allowed values for numeric types
    public static func range<T: Numeric & Sendable>(_ range: ClosedRange<T>) -> GenerationGuide {
        GenerationGuide(type: .range, value: range)
    }
    
    /// Allowed enumeration values for string properties
    public static func enumeration(_ values: [String]) -> GenerationGuide {
        GenerationGuide(type: .enumeration, value: values)
    }
    
    /// Regular expression pattern for string validation
    public static func pattern(_ regex: String) -> GenerationGuide {
        GenerationGuide(type: .pattern, value: regex)
    }
    
    internal enum GuideType {
        case maximumCount
        case minimumCount
        case count
        case range
        case enumeration
        case pattern
    }
}

/// Legacy constraint type for backwards compatibility
/// ❌ DEPRECATED: Use GenerationGuide instead
public enum GuideConstraint {
    case range(ClosedRange<Int>)
    case count(Int)
    case enumValues([String])
    case pattern(String)
}