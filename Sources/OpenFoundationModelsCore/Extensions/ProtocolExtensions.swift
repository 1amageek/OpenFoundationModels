
import Foundation


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

extension GeneratedContent {
    public var instructionsRepresentation: Instructions {
        return Instructions(self.text)
    }
    
    public var promptRepresentation: Prompt {
        return Prompt(self.text)
    }
}

extension GenerationID {
    public var instructionsRepresentation: Instructions {
        return Instructions("A unique identifier: \(self.description)")
    }
    
    public var promptRepresentation: Prompt {
        return Prompt(self.description)
    }
}

// MARK: - Standard Type Protocol Conformances

extension Bool: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return Instructions(self ? "true" : "false")
    }
}

extension Bool: PromptRepresentable {
    public var promptRepresentation: Prompt {
        return Prompt(self ? "true" : "false")
    }
}

extension Int: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return Instructions(String(self))
    }
}

extension Int: PromptRepresentable {
    public var promptRepresentation: Prompt {
        return Prompt(String(self))
    }
}

extension Float: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return Instructions(String(self))
    }
}

extension Float: PromptRepresentable {
    public var promptRepresentation: Prompt {
        return Prompt(String(self))
    }
}

extension Double: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return Instructions(String(self))
    }
}

extension Double: PromptRepresentable {
    public var promptRepresentation: Prompt {
        return Prompt(String(self))
    }
}

extension Decimal: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return Instructions(String(describing: self))
    }
}

extension Decimal: PromptRepresentable {
    public var promptRepresentation: Prompt {
        return Prompt(String(describing: self))
    }
}

extension UUID: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return Instructions(self.uuidString)
    }
}

extension UUID: PromptRepresentable {
    public var promptRepresentation: Prompt {
        return Prompt(self.uuidString)
    }
}

extension Date: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return Instructions(formatter.string(from: self))
    }
}

extension Date: PromptRepresentable {
    public var promptRepresentation: Prompt {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return Prompt(formatter.string(from: self))
    }
}

extension URL: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return Instructions(self.absoluteString)
    }
}

extension URL: PromptRepresentable {
    public var promptRepresentation: Prompt {
        return Prompt(self.absoluteString)
    }
}

extension Never: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        fatalError("Never has no instances")
    }
}

extension Never: PromptRepresentable {
    public var promptRepresentation: Prompt {
        fatalError("Never has no instances")
    }
}
