import Foundation
import OpenFoundationModels
@_spi(Internal) import Generation

/// A public image type for use in `PromptBuilder`.
///
/// Conforms to `PromptRepresentable` so it can be composed with text
/// and other content inside a `Prompt { }` builder block.
///
/// ```swift
/// let prompt = Prompt {
///     "What is in this image?"
///     PromptImage(source: .base64(data: base64String, mediaType: "image/png"))
/// }
/// ```
public struct PromptImage: Sendable, PromptRepresentable {

    /// The source of the image data.
    public enum Source: Sendable {
        /// Base64-encoded image data with its MIME type.
        case base64(data: String, mediaType: String)
        /// A URL pointing to the image.
        case url(URL)
    }

    public let source: Source

    public init(source: Source) {
        self.source = source
    }

    public var promptRepresentation: Prompt {
        let imageSource: Prompt.Image.Source = switch source {
        case .base64(let data, let mediaType): .base64(data: data, mediaType: mediaType)
        case .url(let url): .url(url)
        }
        return Prompt(components: [.image(Prompt.Image(source: imageSource))])
    }
}
