import Foundation

public struct Prompt: Sendable, Copyable, SendableMetatype, PromptRepresentable {

    public let content: String

    public init(_ content: String) {
        self.content = content
    }

    public init(@PromptBuilder _ content: () throws -> Prompt) rethrows {
        let builtPrompt = try content()
        self.content = builtPrompt.content
    }

    public var promptRepresentation: Prompt {
        return self
    }
}
