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
            return Prompt.Segment(text: prompt.segments.map { $0.text }.joined(separator: " "))
        }
        return Prompt(segments: segments)
    }
    
    /// Build prompt from variadic representable elements
    /// ✅ CONFIRMED: buildBlock method from Apple docs
    public static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P: PromptRepresentable {
        var segments: [Prompt.Segment] = []
        for component in repeat each components {
            let prompt = component.promptRepresentation
            segments.append(Prompt.Segment(text: prompt.segments.map { $0.text }.joined(separator: " ")))
        }
        return Prompt(segments: segments)
    }
    
    /// Build prompt from first branch of conditional
    /// ✅ PHASE 4.8: Apple-compliant conditional handling (first branch)
    public static func buildEither(first component: some PromptRepresentable) -> Prompt {
        return component.promptRepresentation
    }
    
    /// Build prompt from second branch of conditional
    /// ✅ PHASE 4.8: Apple-compliant conditional handling (second branch)
    public static func buildEither(second component: some PromptRepresentable) -> Prompt {
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
    /// ✅ PHASE 4.8: Apple-compliant optional handling
    public static func buildOptional(_ component: Prompt?) -> Prompt {
        return component ?? Prompt(segments: [] as [Prompt.Segment])
    }
    
    /// Build prompt from optional PromptRepresentable component
    /// ✅ PHASE 4.8: Apple-compliant optional handling for PromptRepresentable
    public static func buildOptional(_ component: (some PromptRepresentable)?) -> Prompt {
        return component?.promptRepresentation ?? Prompt(segments: [] as [Prompt.Segment])
    }
}

// MARK: - Supporting Types

/// Core prompt type used by PromptBuilder
/// ❌ STRUCTURE UNKNOWN: Referenced but not yet documented
// NOTE: Core Prompt type is defined in Sources/OpenFoundationModels/Prompt.swift
// This avoids type ambiguity - removed duplicate definition

/// Individual prompt segment
