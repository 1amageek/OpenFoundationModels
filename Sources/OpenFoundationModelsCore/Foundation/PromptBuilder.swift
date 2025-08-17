
import Foundation

@resultBuilder
public struct PromptBuilder {
    
    public static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt {
        let combinedText = prompts.map { 
            $0.promptRepresentation.description 
        }.joined(separator: "\n")
        return Prompt(combinedText)
    }
    
    public static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P: PromptRepresentable {
        var parts: [String] = []
        repeat parts.append((each components).promptRepresentation.description)
        let combinedText = parts.joined(separator: "\n")
        return Prompt(combinedText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    public static func buildEither(first component: some PromptRepresentable) -> Prompt {
        return component.promptRepresentation
    }
    
    public static func buildEither(second component: some PromptRepresentable) -> Prompt {
        return component.promptRepresentation
    }
    
    public static func buildExpression<P>(_ expression: P) -> P where P: PromptRepresentable {
        return expression
    }
    
    public static func buildExpression(_ expression: Prompt) -> Prompt {
        return expression
    }
    
    public static func buildLimitedAvailability(_ prompt: some PromptRepresentable) -> Prompt {
        return prompt.promptRepresentation
    }
    
    public static func buildOptional(_ component: Prompt?) -> Prompt {
        return component ?? Prompt("")
    }
}
