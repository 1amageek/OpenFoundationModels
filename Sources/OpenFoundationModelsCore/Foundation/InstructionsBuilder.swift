// InstructionsBuilder.swift  
// OpenFoundationModelsCore
//
// ✅ APPLE OFFICIAL: Based on Apple Foundation Models API specification

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
    
    /// Creates a builder with a block.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with a block.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock(_:)
    /// 
    /// **Apple Official API:** `static func buildBlock<each I>(_ components: repeat each I) -> Instructions where repeat each I : InstructionsRepresentable`
    public static func buildBlock<each I>(_ components: repeat each I) -> Instructions where repeat each I: InstructionsRepresentable {
        // Combine all instructions into a single Instructions instance
        var parts: [String] = []
        repeat parts.append((each components).instructionsRepresentation.description)
        let combinedText = parts.joined(separator: "\n")
        return Instructions(combinedText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Creates a builder with an array of instructions.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with an array of instructions.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray(_:)
    /// 
    /// **Apple Official API:** `static func buildArray(_ instructions: [some InstructionsRepresentable]) -> Instructions`
    public static func buildArray(_ instructions: [some InstructionsRepresentable]) -> Instructions {
        let combinedText = instructions.map { 
            $0.instructionsRepresentation.description 
        }.joined(separator: "\n")
        return Instructions(combinedText)
    }
    
    /// Creates a builder with the first component.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with the first component.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildeither(first:)
    /// 
    /// **Apple Official API:** `static func buildEither(first component: some InstructionsRepresentable) -> Instructions`
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
    /// **Apple Official API:** `static func buildEither(second component: some InstructionsRepresentable) -> Instructions`
    public static func buildEither(second component: some InstructionsRepresentable) -> Instructions {
        return component.instructionsRepresentation
    }
    
    /// Creates a builder with an optional component.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with an optional component.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildoptional(_:)
    /// 
    /// **Apple Official API:** `static func buildOptional(_ instructions: Instructions?) -> Instructions`
    public static func buildOptional(_ instructions: Instructions?) -> Instructions {
        return instructions ?? Instructions("")
    }
    
    /// Creates a builder with a limited availability instruction.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with a limited availability instruction.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildlimitedavailability(_:)
    /// 
    /// **Apple Official API:** `static func buildLimitedAvailability(_ instructions: some InstructionsRepresentable) -> Instructions`
    public static func buildLimitedAvailability(_ instructions: some InstructionsRepresentable) -> Instructions {
        return instructions.instructionsRepresentation
    }
    
    /// Creates a builder with an expression.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with an expression.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildexpression(_:)
    /// 
    /// **Apple Official API:** `static func buildExpression<I>(_ expression: I) -> I where I : InstructionsRepresentable`
    public static func buildExpression<I>(_ expression: I) -> I where I: InstructionsRepresentable {
        return expression
    }
    
    /// Creates a builder with an Instructions expression.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a builder with an Instructions expression.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildexpression(_:)
    /// 
    /// **Apple Official API:** `static func buildExpression(_ expression: Instructions) -> Instructions`
    public static func buildExpression(_ expression: Instructions) -> Instructions {
        return expression
    }
}

// MARK: - String InstructionsRepresentable Extension
// String conformance is provided in ProtocolConformances.swift

// MARK: - Array InstructionsRepresentable Extension
// Array conformance is provided in ProtocolConformances.swift

// Instructions CustomStringConvertible is defined in Types/Instructions.swift