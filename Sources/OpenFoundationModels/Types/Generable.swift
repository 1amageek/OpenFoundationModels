// Generable.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Based on Apple Foundation Models API specification

import Foundation

/// A type that the model uses when responding to prompts.
/// 
/// **Apple Foundation Models Documentation:**
/// Annotate your Swift structure or enumeration with the `@Generable` macro to allow the model 
/// to respond to prompts by generating an instance of your type. Use the `@Guide` macro to provide 
/// natural language descriptions of your properties, and programmatically control the values that 
/// the model can generate.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/generable
/// 
/// **Apple Official API:** `protocol Generable : ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Inheritance:**
/// - ConvertibleFromGeneratedContent
/// - ConvertibleToGeneratedContent
/// - InstructionsRepresentable
/// - PromptRepresentable
/// - SendableMetatype
/// 
/// **Usage Example:**
/// ```swift
/// @Generable
/// struct SearchSuggestions {
///     @Guide(description: "A list of suggested search terms", .count(4))
///     var searchTerms: [SearchTerm]
///     
///     @Generable
///     struct SearchTerm {
///         // Use a generation identifier for types the framework generates.
///         var id: GenerationID
///         
///         @Guide(description: "A 2 or 3 word search term, like 'Beautiful sunsets'")
///         var searchTerm: String
///     }
/// }
/// ```
public protocol Generable: ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent, InstructionsRepresentable, PromptRepresentable, SendableMetatype, Sendable {
    /// An instance of the generation schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An instance of the generation schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generable/generationschema
    /// 
    /// **Apple Official API:** `static var generationSchema: GenerationSchema`
    /// 
    /// **Required**
    static var generationSchema: GenerationSchema { get }
    
    /// A representation of partially generated content
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A representation of partially generated content
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generable/partiallygenerated
    /// 
    /// **Apple Official API:** `associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self`
    /// 
    /// **Required** - Default implementation provided.
    associatedtype PartiallyGenerated: ConvertibleFromGeneratedContent = Self
    
    /// The partially generated type of this struct.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// The partially generated type of this struct.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generable/aspartiallygenerated
    /// 
    /// **Apple Official API:** `func asPartiallyGenerated() -> Self.PartiallyGenerated`
    /// 
    /// - Returns: The partially generated representation of this instance
    func asPartiallyGenerated() -> Self.PartiallyGenerated
}

// MARK: - Protocol Implementation
// All required methods are provided by the @Generable macro:
// - init(_:) for ConvertibleFromGeneratedContent.from(generatedContent:)
// - generatedContent for ConvertibleToGeneratedContent.toGeneratedContent()
// - generationSchema static property
// - asPartiallyGenerated() method

// MARK: - Legacy JSONSchema (INCOMPATIBLE - TO BE REMOVED)
// 🚨 WARNING: Apple does NOT use JSONSchema
// The following types are incompatible with Apple's API and will be removed:

/// ⚠️ DEPRECATED: Apple uses GenerationSchema, not JSONSchema
/// This type will be removed in favor of Apple's GenerationSchema
public struct JSONSchema: Sendable {
    public let type: SchemaType
    public let properties: [String: JSONSchema]?
    public let required: [String]?
    public let items: Box<JSONSchema>?
    public let description: String?
    public let constraints: SchemaConstraints?
    
    public init(
        type: SchemaType,
        properties: [String: JSONSchema]? = nil,
        required: [String]? = nil,
        items: JSONSchema? = nil,
        description: String? = nil,
        constraints: SchemaConstraints? = nil
    ) {
        self.type = type
        self.properties = properties
        self.required = required
        self.items = items.map(Box.init)
        self.description = description
        self.constraints = constraints
    }
}

/// ⚠️ DEPRECATED: Used only by legacy JSONSchema
public final class Box<T>: @unchecked Sendable {
    public let value: T
    public init(_ value: T) { self.value = value }
}

/// ⚠️ DEPRECATED: Apple schema types are different
public enum SchemaType: String, Sendable {
    case object, array, string, number, integer, boolean, null
}

/// ⚠️ DEPRECATED: Apple constraint system is different
public struct SchemaConstraints: Sendable {
    public let minimum: Double?
    public let maximum: Double?
    public let pattern: String?
    public let minLength: Int?
    public let maxLength: Int?
    public let enumValues: [String]?
    
    public init(minimum: Double? = nil, maximum: Double? = nil, pattern: String? = nil,
                minLength: Int? = nil, maxLength: Int? = nil, enumValues: [String]? = nil) {
        self.minimum = minimum; self.maximum = maximum; self.pattern = pattern
        self.minLength = minLength; self.maxLength = maxLength; self.enumValues = enumValues
    }
}