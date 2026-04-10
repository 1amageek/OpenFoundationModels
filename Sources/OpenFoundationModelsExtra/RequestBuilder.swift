import OpenFoundationModels
import OpenFoundationModels

/// A type that builds a backend-specific API request from a `Transcript`.
///
/// Conform to this protocol to implement a request builder for any language model backend.
/// The associated `BuildResult` carries the constructed request and any backend-specific
/// metadata needed by the `LanguageModel` to dispatch the call.
///
/// ```swift
/// struct MyBackendRequestBuilder: RequestBuilder {
///     struct BuildResult: Sendable { let request: MyRequest }
///
///     func build(transcript: Transcript, options: GenerationOptions?, stream: Bool) throws -> BuildResult {
///         let resolved = transcript.resolved()
///         let messages = buildMessages(from: resolved)
///         // ...
///     }
/// }
/// ```
public protocol RequestBuilder: Sendable {
    /// The result produced by `build(transcript:options:stream:)`.
    associatedtype BuildResult: Sendable

    /// Build a backend-specific request from the given transcript.
    ///
    /// - Parameters:
    ///   - transcript: The conversation history to convert.
    ///   - options: Generation options that override any options stored in the transcript.
    ///   - stream: `true` for a streaming request, `false` for a single-shot request.
    /// - Returns: A `BuildResult` containing the constructed request.
    func build(
        transcript: Transcript,
        options: GenerationOptions?,
        stream: Bool
    ) throws -> BuildResult
}

// MARK: - Default Implementations

extension RequestBuilder {

    /// Converts a sequence of `Transcript.Segment` values into a plain `String`.
    ///
    /// - `.text` segments contribute their raw content.
    /// - `.structure` segments are JSON-encoded via `jsonString`.
    /// - `.image` segments are replaced with `"[Image #N]"` placeholders.
    ///
    /// This default implementation is shared by all backends.
    public func segmentsToText(_ segments: [Transcript.Segment]) -> String {
        var texts: [String] = []
        var imageIndex = 1
        for segment in segments {
            switch segment {
            case .text(let t):
                texts.append(t.content)
            case .reasoning:
                continue
            case .structure(let s):
                texts.append(s.content.jsonString)
            case .image:
                texts.append("[Image #\(imageIndex)]")
                imageIndex += 1
            }
        }
        return texts.joined(separator: " ")
    }
}
