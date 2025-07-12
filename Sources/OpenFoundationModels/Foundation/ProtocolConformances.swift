// ProtocolConformances.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Additional protocols required by Apple Foundation Models API

import Foundation

/// Conforming types represent instructions.
/// 
/// **Apple Foundation Models Documentation:**
/// Conforming types represent instructions.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable
/// 
/// **Apple Official API:** `protocol InstructionsRepresentable`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Inherited By:**
/// - ConvertibleToGeneratedContent
/// - Generable
/// 
/// **Conforming Types:**
/// - GeneratedContent
/// - Instructions
public protocol InstructionsRepresentable {
    /// An instance that represents the instructions.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An instance that represents the instructions.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable/instructionsrepresentation
    /// 
    /// **Apple Official API:** `var instructionsRepresentation: Instructions`
    /// **Required** Default implementation provided.
    var instructionsRepresentation: Instructions { get }
}

/// Protocol for types that can represent prompts
/// 
/// ✅ CONFIRMED: Referenced in Apple documentation for:
/// - Generable protocol inheritance
public protocol PromptRepresentable {
    /// Required property with default implementation
    /// ✅ CONFIRMED: promptRepresentation property from Apple docs
    var promptRepresentation: Prompt { get }
}

/// Protocol for sendable metatypes
/// 
/// ✅ CONFIRMED: Referenced in Apple documentation for:
/// - Generable protocol inheritance
public protocol SendableMetatype {
    // ❌ IMPLEMENTATION NEEDED: Protocol requirements not documented
}

/// A type that represents an instructions builder.
/// 
/// **Apple Foundation Models Documentation:**
/// A type that represents an instructions builder.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder
/// 
/// **Apple Official API:** `@resultBuilder struct InstructionsBuilder`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
@resultBuilder
public struct InstructionsBuilder {
    /// Creates a builder with the an array of prompts.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with the an array of prompts.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray(_:)
    /// 
    /// **Apple Official API:** `static func buildArray([some InstructionsRepresentable]) -> Instructions`
    public static func buildArray(_ components: [some InstructionsRepresentable]) -> Instructions {
        let text = components.map { $0.instructionsRepresentation.text }.joined(separator: "\n")
        return Instructions(text)
    }
    
    /// Creates a builder with the a block.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with the a block.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock(_:)
    /// 
    /// **Apple Official API:** `static func buildBlock<each I>(repeat each I) -> Instructions`
    public static func buildBlock<each I: InstructionsRepresentable>(_ components: repeat each I) -> Instructions {
        var texts: [String] = []
        repeat texts.append((each components).instructionsRepresentation.text)
        return Instructions(texts.joined(separator: "\n"))
    }
    
    /// Creates a builder with the first component.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with the first component.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildeither(first:)
    /// 
    /// **Apple Official API:** `static func buildEither(first: some InstructionsRepresentable) -> Instructions`
    public static func buildEither(first component: some InstructionsRepresentable) -> Instructions {
        return component.instructionsRepresentation
    }
    
    /// Creates a builder with the second component.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with the second component.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildeither(second:)
    /// 
    /// **Apple Official API:** `static func buildEither(second: some InstructionsRepresentable) -> Instructions`
    public static func buildEither(second component: some InstructionsRepresentable) -> Instructions {
        return component.instructionsRepresentation
    }
    
    /// Creates a builder with a prompt expression.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with a prompt expression.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildexpression(_:)
    /// 
    /// **Apple Official API:** `static buildExpression(_:)`
    public static func buildExpression(_ expression: some InstructionsRepresentable) -> Instructions {
        return expression.instructionsRepresentation
    }
    
    /// Creates a builder with a limited availability prompt.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with a limited availability prompt.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildlimitedavailability(_:)
    /// 
    /// **Apple Official API:** `static func buildLimitedAvailability(some InstructionsRepresentable) -> Instructions`
    public static func buildLimitedAvailability(_ component: some InstructionsRepresentable) -> Instructions {
        return component.instructionsRepresentation
    }
    
    /// Creates a builder with an optional component.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with an optional component.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildoptional(_:)
    /// 
    /// **Apple Official API:** `static func buildOptional(Instructions?) -> Instructions`
    public static func buildOptional(_ component: Instructions?) -> Instructions {
        return component ?? Instructions("")
    }
}

// MARK: - Standard Type Conformances

/// String conformance to Generable
/// 
/// **Apple Foundation Models Documentation:**
/// String is a fundamental type that can be generated by language models.
/// This conformance allows String to be used directly in generation methods.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/generable
extension String: InstructionsRepresentable, PromptRepresentable {
    /// Convert to instructions representation
    public var instructionsRepresentation: Instructions {
        return Instructions(self)
    }
    
    /// Convert to prompt representation
    public var promptRepresentation: Prompt {
        return Prompt(self)
    }
}

extension String: Generable {
    /// Partially generated string content
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Represents string content that is being generated incrementally.
    public typealias PartiallyGenerated = GeneratedContent
    
    /// The generation schema for String content
    /// 
    /// **Apple Foundation Models Documentation:**
    /// String content uses a simple text schema for generation.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: "string",
            description: "Text content",
            anyOf: []
        )
    }
    
    /// Create String from generated content
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Extracts string content from generated output.
    public static func from(generatedContent: GeneratedContent) throws -> String {
        return generatedContent.text
    }
    
    /// Convert String to generated content
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Converts string to generated content format.
    public func toGeneratedContent() -> GeneratedContent {
        return GeneratedContent(self)
    }
    
    /// Convert to partially generated representation
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Converts string to partially generated content for streaming.
    public func toPartiallyGenerated() -> PartiallyGenerated {
        return GeneratedContent(self)
    }
    
    /// Convert to partially generated representation (instance method)
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Instance method for converting to partially generated content.
    public func asPartiallyGenerated() -> PartiallyGenerated {
        return GeneratedContent(self)
    }
}

/// GeneratedContent conformance to Generable
/// 
/// **Apple Foundation Models Documentation:**
/// GeneratedContent is the base type for all generated content.
/// This conformance enables structured generation workflows.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/generatedcontent
extension GeneratedContent: InstructionsRepresentable {
    /// Convert to instructions representation
    public var instructionsRepresentation: Instructions {
        return Instructions(self.stringValue)
    }
}

extension GeneratedContent: Generable {
    /// Partially generated content representation
    /// 
    /// **Apple Foundation Models Documentation:**
    /// GeneratedContent can represent partially generated content.
    public typealias PartiallyGenerated = GeneratedContent
    
    /// The generation schema for GeneratedContent
    /// 
    /// **Apple Foundation Models Documentation:**
    /// GeneratedContent uses a flexible schema that can represent various content types.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: "object",
            description: "Generated content with flexible structure"
        )
    }
    
    /// Create GeneratedContent from generated content (identity function)
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Identity transformation for GeneratedContent.
    public static func from(generatedContent: GeneratedContent) throws -> GeneratedContent {
        return generatedContent
    }
    
    /// Convert GeneratedContent to generated content (identity function)
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Identity transformation for GeneratedContent.
    public func toGeneratedContent() -> GeneratedContent {
        return self
    }
    
    /// Convert to partially generated representation (identity function)
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Identity transformation for GeneratedContent.
    public func toPartiallyGenerated() -> PartiallyGenerated {
        return self
    }
    
    /// Convert to partially generated representation (instance method)
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Instance method for converting to partially generated content.
    public func asPartiallyGenerated() -> PartiallyGenerated {
        return self
    }
}