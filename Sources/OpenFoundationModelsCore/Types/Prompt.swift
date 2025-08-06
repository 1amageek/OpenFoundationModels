// Prompt.swift
// OpenFoundationModelsCore
//
// ✅ APPLE OFFICIAL: Placeholder for builder usage in Core module

import Foundation

/// Placeholder Prompt type for Core module builders
/// The actual Prompt implementation is in the main module
public struct Prompt: Sendable {
    internal let content: String
    
    public init(_ content: String) {
        self.content = content
    }
}

extension Prompt: CustomStringConvertible {
    public var description: String {
        return content
    }
}

extension Prompt: PromptRepresentable {
    public var promptRepresentation: Prompt {
        return self
    }
}