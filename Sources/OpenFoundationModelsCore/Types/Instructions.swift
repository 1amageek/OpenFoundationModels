import Foundation

public struct Instructions: Sendable, Copyable, SendableMetatype, InstructionsRepresentable {

    package struct Text: Sendable, Equatable {
        package let value: String

        package init(value: String) {
            self.value = value
        }
    }

    package enum Component: Sendable, Equatable {
        case text(Text)
    }

    package let components: [Component]

    package var content: String {
        components.map { component in
            switch component {
            case .text(let text):
                return text.value
            }
        }.joined(separator: "\n")
    }

    public init(_ content: String) {
        self.components = [.text(Text(value: content))]
    }

    package init(components: [Component]) {
        self.components = components
    }

    public init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows {
        let builtInstructions = try content()
        self.components = builtInstructions.components
    }

    public var instructionsRepresentation: Instructions {
        return self
    }
}