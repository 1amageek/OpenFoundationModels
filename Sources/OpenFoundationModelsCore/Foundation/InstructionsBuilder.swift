
import Foundation

@resultBuilder
public struct InstructionsBuilder {

    public static func buildArray(_ instructions: [some InstructionsRepresentable]) -> Instructions {
        let components = instructions.flatMap { $0.instructionsRepresentation.components }
        return Instructions(components: components)
    }

    public static func buildBlock<each I>(_ components: repeat each I) -> Instructions where repeat each I: InstructionsRepresentable {
        var allComponents: [Instructions.Component] = []
        repeat allComponents.append(contentsOf: (each components).instructionsRepresentation.components)
        return Instructions(components: allComponents)
    }

    public static func buildEither(first component: some InstructionsRepresentable) -> Instructions {
        return component.instructionsRepresentation
    }

    public static func buildEither(second component: some InstructionsRepresentable) -> Instructions {
        return component.instructionsRepresentation
    }

    public static func buildExpression<I>(_ expression: I) -> I where I: InstructionsRepresentable {
        return expression
    }

    public static func buildExpression(_ expression: Instructions) -> Instructions {
        return expression
    }

    public static func buildLimitedAvailability(_ instructions: some InstructionsRepresentable) -> Instructions {
        return instructions.instructionsRepresentation
    }

    public static func buildOptional(_ component: Instructions?) -> Instructions {
        return component ?? Instructions(components: [])
    }
}
