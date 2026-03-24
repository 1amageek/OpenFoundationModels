import Foundation

public struct Instructions: Sendable, Copyable, SendableMetatype, InstructionsRepresentable {

    package struct Text: Sendable, Equatable {
        package let value: String

        package init(value: String) {
            self.value = value
        }
    }

    package struct Image: Sendable, Equatable {
        package enum Source: Sendable, Equatable {
            case base64(data: String, mediaType: String)
            case url(URL)
        }
        package let source: Source

        package init(source: Source) {
            self.source = source
        }
    }

    package enum Component: Sendable, Equatable {
        case text(Text)
        case image(Image)
    }

    package let components: [Component]

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