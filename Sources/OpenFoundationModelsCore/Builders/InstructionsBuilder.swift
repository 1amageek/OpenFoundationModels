// InstructionsBuilder.swift
// OpenFoundationModelsCore
//
// ✅ CONFIRMED: Required by Apple Foundation Models API

import Foundation

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