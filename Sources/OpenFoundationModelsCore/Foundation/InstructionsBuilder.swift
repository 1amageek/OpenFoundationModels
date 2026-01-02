
import Foundation

@resultBuilder
public struct InstructionsBuilder {
    
    public static func buildBlock<each I>(_ components: repeat each I) -> Instructions where repeat each I: InstructionsRepresentable {
        var parts: [String] = []
        repeat parts.append((each components).instructionsRepresentation.content)
        let combinedText = parts.joined(separator: "\n")
        return Instructions(combinedText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public static func buildArray(_ instructions: [some InstructionsRepresentable]) -> Instructions {
        let combinedText = instructions.map {
            $0.instructionsRepresentation.content
        }.joined(separator: "\n")
        return Instructions(combinedText)
    }
    
    public static func buildEither(first component: some InstructionsRepresentable) -> Instructions {
        return component.instructionsRepresentation
    }
    
    public static func buildEither(second component: some InstructionsRepresentable) -> Instructions {
        return component.instructionsRepresentation
    }
    
    public static func buildOptional(_ instructions: Instructions?) -> Instructions {
        return instructions ?? Instructions("")
    }
    
    public static func buildLimitedAvailability(_ instructions: some InstructionsRepresentable) -> Instructions {
        return instructions.instructionsRepresentation
    }
    
    public static func buildExpression<I>(_ expression: I) -> I where I: InstructionsRepresentable {
        return expression
    }
    
    public static func buildExpression(_ expression: Instructions) -> Instructions {
        return expression
    }
}
