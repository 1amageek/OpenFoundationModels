// Instructions.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// Instructions define the model's intended behavior on prompts.
/// 
/// From Apple Documentation:
/// - Instructions are typically provided to define the role and behavior of the model
/// - Apple trains the model to obey instructions over any commands in prompts
/// - Should not include untrusted content in instructions
public struct Instructions: Sendable {
    /// Text content of the instructions
    /// ✅ CONFIRMED: Apple specification requires text property
    public let text: String
    
    /// Initialize instructions with text
    /// - Parameter text: The instruction text that defines model behavior
    public init(_ text: String) {
        self.text = text
    }
}

// MARK: - Required Protocol Conformances (from Apple spec)
// Instructions must conform to InstructionsRepresentable
// Implementation pending - protocol not yet defined

// MARK: - Protocol Conformances
extension Instructions: InstructionsRepresentable {
    /// Instructions representation of this instance
    /// ✅ CONFIRMED: InstructionsRepresentable protocol requirement
    public var instructionsRepresentation: Instructions {
        return self
    }
}

// InstructionsRepresentable protocol is defined in Foundation/ProtocolConformances.swift