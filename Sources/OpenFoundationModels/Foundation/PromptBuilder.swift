// PromptBuilder.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// Result builder for prompt construction
/// 
/// ✅ CONFIRMED: From Apple Developer Documentation
/// - Full result builder implementation for prompt construction
/// - Works with PromptRepresentable types
/// - Complete set of builder methods
@resultBuilder
public struct PromptBuilder {
    
    /// Build prompt from array of representable elements
    /// ✅ CONFIRMED: buildArray method from Apple docs
    public static func buildArray(_ components: [some PromptRepresentable]) -> Prompt {
        let segments = components.map { component in
            let prompt = component.promptRepresentation
            return PromptSegment(content: prompt.text)
        }
        return Prompt(segments: segments)
    }
    
    /// Build prompt from variadic representable elements
    /// ✅ CONFIRMED: buildBlock method from Apple docs
    public static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P: PromptRepresentable {
        var segments: [PromptSegment] = []
        for component in repeat each components {
            let prompt = component.promptRepresentation
            segments.append(PromptSegment(content: prompt.text))
        }
        return Prompt(segments: segments)
    }
    
    /// Build prompt from first branch of conditional
    /// ✅ CONFIRMED: buildEither(first:) method from Apple docs
    public static func buildEither(first component: some PromptRepresentable) -> Prompt {
        // Implementation needed - handle first conditional branch
        return component.promptRepresentation
    }
    
    /// Build prompt from second branch of conditional
    /// ✅ CONFIRMED: buildEither(second:) method from Apple docs
    public static func buildEither(second component: some PromptRepresentable) -> Prompt {
        // Implementation needed - handle second conditional branch
        return component.promptRepresentation
    }
    
    /// Build prompt from expression
    /// ✅ CONFIRMED: buildExpression method from Apple docs
    public static func buildExpression(_ expression: some PromptRepresentable) -> Prompt {
        // Implementation needed - convert expression to Prompt
        return expression.promptRepresentation
    }
    
    /// Build prompt with limited availability
    /// ✅ CONFIRMED: buildLimitedAvailability method from Apple docs
    public static func buildLimitedAvailability(_ component: some PromptRepresentable) -> Prompt {
        // Implementation needed - handle limited availability context
        return component.promptRepresentation
    }
    
    /// Build prompt from optional component
    /// ✅ CONFIRMED: buildOptional method from Apple docs
    public static func buildOptional(_ component: Prompt?) -> Prompt {
        // Implementation needed - handle optional component
        return component ?? Prompt(segments: [])
    }
}

// MARK: - Supporting Types

/// Core prompt type used by PromptBuilder
/// ❌ STRUCTURE UNKNOWN: Referenced but not yet documented
// NOTE: Core Prompt type is defined in Sources/OpenFoundationModels/Prompt.swift
// This avoids type ambiguity - removed duplicate definition

/// Individual prompt segment
/// ❌ STRUCTURE UNKNOWN: Inferred from usage
/// Individual prompt segment for building prompts
/// ❌ STRUCTURE UNKNOWN: Inferred from usage
public struct PromptSegment: Sendable {
    /// Segment content
    public let content: String
    
    /// Initialize segment with content
    public init(content: String) {
        self.content = content
    }
}

// MARK: - Prompt extension for PromptBuilder compatibility
extension Prompt {
    /// Initialize prompt with segments (for PromptBuilder compatibility)
    /// - Parameter segments: Array of prompt segments
    public init(segments: [PromptSegment]) {
        // Convert segments to text format
        let text = segments.map(\.content).joined(separator: " ")
        self.init(text)
    }
}