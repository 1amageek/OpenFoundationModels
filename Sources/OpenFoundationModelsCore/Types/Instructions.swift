// Instructions.swift
// OpenFoundationModelsCore
//
// ✅ APPLE OFFICIAL: Placeholder for builder usage in Core module

import Foundation

/// Placeholder Instructions type for Core module builders
/// The actual Instructions implementation is in the main module
public struct Instructions: Sendable {
    internal let content: String
    
    public init(_ content: String) {
        self.content = content
    }
}

extension Instructions: CustomStringConvertible {
    public var description: String {
        return content
    }
}

extension Instructions: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return self
    }
}