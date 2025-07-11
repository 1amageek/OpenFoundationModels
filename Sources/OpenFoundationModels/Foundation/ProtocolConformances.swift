// ProtocolConformances.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Additional protocols required by Apple Foundation Models API

import Foundation

/// Protocol for types that can represent instructions
/// 
/// ✅ CONFIRMED: Referenced in Apple documentation for:
/// - Generable protocol inheritance
/// - Instructions conformance requirement
public protocol InstructionsRepresentable {
    /// Convert to instructions representation
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

/// Result builder for declarative instructions
/// 
/// ✅ CONFIRMED: Referenced in Apple documentation for:
/// - LanguageModelSession.init(@InstructionsBuilder instructions: () -> String)
@resultBuilder
public struct InstructionsBuilder {
    // ❌ IMPLEMENTATION NEEDED: Result builder methods not documented
    
    /// Build instructions from string components
    public static func buildBlock(_ components: String...) -> String {
        // Implementation needed
        return components.joined(separator: "\n")
    }
}