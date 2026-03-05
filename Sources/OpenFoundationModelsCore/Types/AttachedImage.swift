import Foundation

/// An image attachment that can be included in a multimodal ``Prompt`` or ``Instructions``.
///
/// Use ``AttachedImage`` inside a ``PromptBuilder`` or ``InstructionsBuilder`` closure
/// to attach images alongside text when sending prompts to a visual language model.
///
/// ```swift
/// let response = try await session.respond {
///     "Describe what you see in this image."
///     AttachedImage(jpeg: imageData)
/// }
/// ```
public struct AttachedImage: PromptRepresentable, InstructionsRepresentable, Sendable {

    private enum Source: Sendable {
        case base64(data: String, mediaType: String)
        case url(URL)
    }

    private let source: Source

    /// Creates an image attachment from JPEG-encoded data.
    public init(jpeg data: Data) {
        self.source = .base64(data: data.base64EncodedString(), mediaType: "image/jpeg")
    }

    /// Creates an image attachment from a URL.
    public init(url: URL) {
        self.source = .url(url)
    }

    public var promptRepresentation: Prompt {
        switch source {
        case .base64(let data, let mediaType):
            return Prompt(components: [.image(Prompt.Image(source: .base64(data: data, mediaType: mediaType)))])
        case .url(let url):
            return Prompt(components: [.image(Prompt.Image(source: .url(url)))])
        }
    }

    public var instructionsRepresentation: Instructions {
        switch source {
        case .base64(let data, let mediaType):
            return Instructions(components: [.image(Instructions.Image(source: .base64(data: data, mediaType: mediaType)))])
        case .url(let url):
            return Instructions(components: [.image(Instructions.Image(source: .url(url)))])
        }
    }
}
