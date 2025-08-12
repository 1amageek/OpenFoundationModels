// ProtocolExtensions.swift
// OpenFoundationModelsCore
//
// ✅ APPLE OFFICIAL: Protocol conformances

import Foundation

// MARK: - String Conformances

extension String: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return Instructions(self)
    }
}

extension String: PromptRepresentable {
    public var promptRepresentation: Prompt {
        return Prompt(self)
    }
}

// MARK: - Array Conformances

extension Array: InstructionsRepresentable where Element: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        let parts = self.map { $0.instructionsRepresentation }
        let combinedText = parts.map { $0.description }.joined(separator: "\n")
        return Instructions(combinedText)
    }
}

extension Array: PromptRepresentable where Element: PromptRepresentable {
    public var promptRepresentation: Prompt {
        let parts = self.map { $0.promptRepresentation }
        let combinedText = parts.map { $0.description }.joined(separator: "\n")
        return Prompt(combinedText)
    }
}

// MARK: - GeneratedContent Conformances

extension GeneratedContent {
    public var instructionsRepresentation: Instructions {
        return Instructions(self.text)
    }
    
    public var promptRepresentation: Prompt {
        return Prompt(self.text)
    }
}

// MARK: - GenerationID Conformances

extension GenerationID {
    public var instructionsRepresentation: Instructions {
        return Instructions("A unique identifier: \(self.description)")
    }
    
    public var promptRepresentation: Prompt {
        return Prompt(self.description)
    }
}