import Foundation

public struct Instructions: Sendable, Copyable, SendableMetatype, InstructionsRepresentable {

    package let content: String

    public init(_ content: String) {
        self.content = content
    }

    public init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows {
        let builtInstructions = try content()
        self.content = builtInstructions.content
    }

    public var instructionsRepresentation: Instructions {
        return self
    }
}