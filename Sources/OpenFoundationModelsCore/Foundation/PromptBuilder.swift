// PromptBuilder.swift
// OpenFoundationModelsCore
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// A type that represents a prompt builder.
/// 
/// **Apple Foundation Models Documentation:**
/// A type that represents a prompt builder.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/promptbuilder
/// 
/// **Apple Official API:** `@resultBuilder struct PromptBuilder`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
@resultBuilder
public struct PromptBuilder {
    
    /// Creates a builder with an array of prompts.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with an array of prompts.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildarray(_:)
    /// 
    /// **Apple Official API:** `static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt`
    public static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt {
        let combinedText = prompts.map { 
            $0.promptRepresentation.description 
        }.joined(separator: "\n")
        return Prompt(combinedText)
    }
    
    /// Creates a builder with a block.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with a block.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildblock(_:)
    /// 
    /// **Apple Official API:** `static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P : PromptRepresentable`
    public static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P: PromptRepresentable {
        var parts: [String] = []
        repeat parts.append((each components).promptRepresentation.description)
        let combinedText = parts.joined(separator: "\n")
        return Prompt(combinedText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Creates a builder with the first component.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with the first component.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither(first:)
    /// 
    /// **Apple Official API:** `static func buildEither(first component: some PromptRepresentable) -> Prompt`
    public static func buildEither(first component: some PromptRepresentable) -> Prompt {
        return component.promptRepresentation
    }
    
    /// Creates a builder with the second component.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with the second component.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither(second:)
    /// 
    /// **Apple Official API:** `static func buildEither(second component: some PromptRepresentable) -> Prompt`
    public static func buildEither(second component: some PromptRepresentable) -> Prompt {
        return component.promptRepresentation
    }
    
    /// Creates a builder with an expression.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with an expression.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildexpression(_:)
    /// 
    /// **Apple Official API:** `static func buildExpression<P>(_ expression: P) -> P where P : PromptRepresentable`
    public static func buildExpression<P>(_ expression: P) -> P where P: PromptRepresentable {
        return expression
    }
    
    /// Creates a builder with a prompt expression.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with a prompt expression.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildexpression(_:)
    /// 
    /// **Apple Official API:** `static func buildExpression(_ expression: Prompt) -> Prompt`
    public static func buildExpression(_ expression: Prompt) -> Prompt {
        return expression
    }
    
    /// Creates a builder with a limited availability prompt.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with a limited availability prompt.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildlimitedavailability(_:)
    /// 
    /// **Apple Official API:** `static func buildLimitedAvailability(_ prompt: some PromptRepresentable) -> Prompt`
    public static func buildLimitedAvailability(_ prompt: some PromptRepresentable) -> Prompt {
        return prompt.promptRepresentation
    }
    
    /// Creates a builder with an optional component.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with an optional component.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildoptional(_:)
    /// 
    /// **Apple Official API:** `static func buildOptional(_ component: Prompt?) -> Prompt`
    public static func buildOptional(_ component: Prompt?) -> Prompt {
        return component ?? Prompt("")
    }
}