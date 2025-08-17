
import Foundation

public struct Prompt: Sendable {
    
    internal let content: String
    
    public init(_ content: String) {
        self.content = content
    }
    
    public init(@PromptBuilder _ content: () throws -> Prompt) rethrows {
        let builtPrompt = try content()
        self.content = builtPrompt.content
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


extension Prompt: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
