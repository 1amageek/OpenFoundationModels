
import Foundation

public struct Instructions: Sendable {
    
    internal let content: String
    
    public init(_ content: String) {
        self.content = content
    }
    
    public init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows {
        let builtInstructions = try content()
        self.content = builtInstructions.content
    }
}


extension Instructions: CustomStringConvertible {
    public var description: String {
        return content
    }
}


extension Instructions: InstructionsRepresentable {
    public var instructionsRepresentation: Instructions {
        return self
    }
}


extension Instructions: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}