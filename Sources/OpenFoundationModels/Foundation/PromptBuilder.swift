
import Foundation

@resultBuilder
public struct PromptBuilder {

    public static func buildArray(_ prompts: [some PromptRepresentable]) -> Prompt {
        let components = prompts.flatMap { $0.promptRepresentation.components }
        return Prompt(components: components)
    }

    public static func buildBlock<each P>(_ components: repeat each P) -> Prompt where repeat each P: PromptRepresentable {
        var allComponents: [Prompt.Component] = []
        repeat allComponents.append(contentsOf: (each components).promptRepresentation.components)
        return Prompt(components: allComponents)
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
        return component ?? Prompt(components: [])
    }
}
