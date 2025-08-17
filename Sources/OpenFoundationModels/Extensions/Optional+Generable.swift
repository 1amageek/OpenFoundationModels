import Foundation
import OpenFoundationModelsCore

extension Optional where Wrapped: Generable {
    public typealias PartiallyGenerated = Wrapped.PartiallyGenerated
}

extension Optional: ConvertibleToGeneratedContent where Wrapped: ConvertibleToGeneratedContent {
    public var generatedContent: GeneratedContent {
        switch self {
        case .none:
            return GeneratedContent(kind: .null)
        case .some(let wrapped):
            return wrapped.generatedContent
        }
    }
}

extension Optional: PromptRepresentable where Wrapped: ConvertibleToGeneratedContent {
    public var promptRepresentation: Prompt {
        switch self {
        case .none:
            return Prompt("")
        case .some(let wrapped):
            return wrapped.promptRepresentation
        }
    }
}

extension Optional: InstructionsRepresentable where Wrapped: ConvertibleToGeneratedContent {
    public var instructionsRepresentation: Instructions {
        switch self {
        case .none:
            return Instructions("")
        case .some(let wrapped):
            return wrapped.instructionsRepresentation
        }
    }
}