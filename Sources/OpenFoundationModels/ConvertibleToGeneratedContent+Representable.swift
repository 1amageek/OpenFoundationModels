import Foundation
import OpenFoundationModelsCore

// MARK: - ConvertibleToGeneratedContent default implementations for Prompt/Instructions

extension ConvertibleToGeneratedContent {
    public var promptRepresentation: Prompt {
        return Prompt(generatedContent.jsonString)
    }

    public var instructionsRepresentation: Instructions {
        return Instructions(generatedContent.jsonString)
    }
}

// MARK: - Optional

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

// MARK: - Dictionary

extension Dictionary: InstructionsRepresentable where Key == String, Value: ConvertibleToGeneratedContent {
    public var instructionsRepresentation: Instructions {
        let jsonData = try? JSONSerialization.data(withJSONObject: self.mapValues { $0.generatedContent.text })
        let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return Instructions(jsonString)
    }
}

extension Dictionary: PromptRepresentable where Key == String, Value: ConvertibleToGeneratedContent {
    public var promptRepresentation: Prompt {
        let jsonData = try? JSONSerialization.data(withJSONObject: self.mapValues { $0.generatedContent.text })
        let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return Prompt(jsonString)
    }
}
