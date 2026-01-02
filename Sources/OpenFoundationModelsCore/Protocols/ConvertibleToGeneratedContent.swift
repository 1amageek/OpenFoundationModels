import Foundation

public protocol ConvertibleToGeneratedContent: InstructionsRepresentable, PromptRepresentable {
    var generatedContent: GeneratedContent { get }
}

// Default implementations for types conforming to ConvertibleToGeneratedContent
extension ConvertibleToGeneratedContent {
    public var promptRepresentation: Prompt {
        return Prompt(generatedContent.jsonString)
    }

    public var instructionsRepresentation: Instructions {
        return Instructions(generatedContent.jsonString)
    }
}