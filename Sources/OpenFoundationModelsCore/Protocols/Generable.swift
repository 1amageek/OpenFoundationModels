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
public protocol Generable: ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent {
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
    associatedtype PartiallyGenerated: ConvertibleFromGeneratedContent & Sendable = Self
    
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

// MARK: - Default Implementations

extension Generable {
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
    public func asPartiallyGenerated() -> Self.PartiallyGenerated {
        // Default implementation when PartiallyGenerated == Self
        return self as! Self.PartiallyGenerated
    }
}

extension Generable {
    /// A representation of partially generated content
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Default type alias when not overridden
    public typealias PartiallyGenerated = Self
}

// MARK: - Protocol Implementation Notes
// Most required methods are provided by the @Generable macro:
// - init(_:) for ConvertibleFromGeneratedContent
// - generatedContent for ConvertibleToGeneratedContent
// - generationSchema static property

