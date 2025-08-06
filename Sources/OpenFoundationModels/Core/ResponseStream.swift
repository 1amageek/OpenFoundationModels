import Foundation

/// A structure that stores the output of a response stream.
/// 
/// **Apple Foundation Models Documentation:**
/// A response stream that provides streaming access to generated content
/// as it becomes available from the language model.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream
/// 
/// **Apple Official API:** `struct ResponseStream<Content> where Content : Generable`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - AsyncSequence
/// - Copyable
/// 
/// **Key Method:**
/// - `collect(isolation:) async throws -> sending Response<Content>`
/// 
/// **Usage:**
/// ```swift
/// let stream = session.streamResponse { Prompt("Hello") }
/// for try await partial in stream {
///     print(partial.content)
/// }
/// ```
public struct ResponseStream<Content>: AsyncSequence, Sendable where Content: Generable & Sendable {
    
    /// The element type yielded by the stream
    /// ✅ APPLE SPEC: Element = Content.PartiallyGenerated
    public typealias Element = Content.PartiallyGenerated
    
    /// The async iterator for the stream
    /// ✅ APPLE SPEC: AsyncIterator implementation
    public typealias AsyncIterator = ResponseStreamIterator<Content>
    
    /// The underlying async stream
    /// ✅ APPLE SPEC: Internal stream implementation
    private let stream: AsyncThrowingStream<Content.PartiallyGenerated, Error>
    
    /// The last partial response received
    /// ✅ APPLE SPEC: Convenience property for UI updates
    public private(set) var last: Content.PartiallyGenerated?
    
    /// Initialize with an async throwing stream
    /// ✅ APPLE SPEC: Standard initializer
    public init(
        stream: AsyncThrowingStream<Content.PartiallyGenerated, Error>
    ) {
        self.stream = stream
        self.last = nil
    }
    
    /// Create an async iterator
    /// ✅ APPLE SPEC: AsyncSequence conformance
    public func makeAsyncIterator() -> AsyncIterator {
        return ResponseStreamIterator(stream: stream)
    }
}

// MARK: - String specialization (handled by main implementation)

// Note: String specialization is handled by the main ResponseStream implementation
// since Response<String>.Partial is already defined for String content

// MARK: - ResponseStreamIterator

/// The async iterator for ResponseStream
/// ✅ APPLE SPEC: AsyncIteratorProtocol implementation
public struct ResponseStreamIterator<Content: Generable & Sendable>: AsyncIteratorProtocol {
    
    /// The element type
    /// ✅ APPLE SPEC: Element type matching parent stream
    public typealias Element = Content.PartiallyGenerated
    
    /// The underlying stream iterator
    /// ✅ APPLE SPEC: Internal iterator implementation
    private var iterator: AsyncThrowingStream<Content.PartiallyGenerated, Error>.AsyncIterator
    
    /// Initialize with a stream
    /// ✅ APPLE SPEC: Standard initializer
    public init(
        stream: AsyncThrowingStream<Content.PartiallyGenerated, Error>
    ) {
        self.iterator = stream.makeAsyncIterator()
    }
    
    /// Get the next element
    /// ✅ APPLE SPEC: AsyncIteratorProtocol conformance
    public mutating func next() async throws -> Element? {
        return try await iterator.next()
    }
}

// MARK: - ResponseStream.Snapshot

extension ResponseStream {
    /// A snapshot of partially generated content.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A snapshot of partially generated content during streaming.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot
    /// 
    /// **Apple Official API:** `struct Snapshot`
    /// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
    /// - Beta Software: Contains preliminary API information
    public struct Snapshot: Sendable {
        /// The content of the response.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// The partially generated content at this point in the stream.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot/content
        public let content: Content.PartiallyGenerated
        
        /// The raw content of the response.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// The raw generated content at this point in the stream.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot/rawcontent
        public let rawContent: GeneratedContent
        
        /// Initialize a snapshot
        /// 
        /// - Parameters:
        ///   - content: The partially generated content
        ///   - rawContent: The raw generated content
        public init(
            content: Content.PartiallyGenerated,
            rawContent: GeneratedContent
        ) {
            self.content = content
            self.rawContent = rawContent
        }
    }
}

// MARK: - Helper Extensions

extension ResponseStream {
    /// The result from a streaming response, after it completes.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Collects all streaming content into a final Response object.
    /// This method waits for the stream to complete and returns the final result.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/collect(isolation:)
    /// 
    /// **Apple Official API:**
    /// `func collect(isolation: isolated (any Actor)?) async throws -> sending Response<Content>`
    /// 
    /// - Parameter isolation: Optional actor isolation context
    /// - Returns: The complete response after streaming finishes
    /// - Throws: Any error encountered during streaming
    public func collect(
        isolation: isolated (any Actor)? = nil
    ) async throws -> Response<Content> {
        var finalPartial: Content.PartiallyGenerated?
        let allEntries: [Transcript.Entry] = []
        
        for try await partial in self {
            finalPartial = partial
            // For types where PartiallyGenerated == Self, check if it has isComplete
            if let partialWithComplete = partial as? PartiallyGeneratedProtocol,
               partialWithComplete.isComplete {
                break
            }
        }
        
        guard let partial = finalPartial else {
            let context = GenerationError.Context(debugDescription: "Stream completed without any content")
            throw GenerationError.decodingFailure(context)
        }
        
        // Convert PartiallyGenerated back to Content
        // For types where PartiallyGenerated == Self, this is straightforward
        let content: Content
        if Content.PartiallyGenerated.self == Content.self {
            content = partial as! Content
        } else {
            // For types with custom PartiallyGenerated, we need to convert
            // This requires the PartiallyGenerated to have the complete data
            // PartiallyGenerated conforms to ConvertibleToGeneratedContent
            if let convertible = partial as? ConvertibleToGeneratedContent {
                guard let convertedContent = try? Content(convertible.generatedContent) else {
                    let context = GenerationError.Context(debugDescription: "Failed to convert partial content to complete content")
                    throw GenerationError.decodingFailure(context)
                }
                content = convertedContent
            } else {
                // Fallback: assume PartiallyGenerated can be cast to Content
                guard let directContent = partial as? Content else {
                    let context = GenerationError.Context(debugDescription: "Cannot convert PartiallyGenerated to Content")
                    throw GenerationError.decodingFailure(context)
                }
                content = directContent
            }
        }
        
        // Create transcript entries from the streaming session
        // In a real implementation, this would come from the session's transcript
        let transcriptSlice = ArraySlice(allEntries)
        
        // Create raw content - for Generable types, convert back to GeneratedContent
        let rawContent: GeneratedContent
        if Content.self == GeneratedContent.self {
            rawContent = content as! GeneratedContent
        } else if Content.self == String.self {
            rawContent = GeneratedContent(content as! String)
        } else {
            // For other Generable types, create GeneratedContent from string representation
            rawContent = GeneratedContent("\(content)")
        }
        
        return Response(
            content: content,
            rawContent: rawContent,
            transcriptEntries: transcriptSlice
        )
    }
    
    /// Collect all partial responses into an array (for testing)
    /// 
    /// **Implementation Note:** This is a convenience method for testing purposes.
    /// Production code should use `collect(isolation:)` instead.
    public func collectPartials() async throws -> [Element] {
        var results: [Element] = []
        for try await partial in self {
            results.append(partial)
        }
        return results
    }
}