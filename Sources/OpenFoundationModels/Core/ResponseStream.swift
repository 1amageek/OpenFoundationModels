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
    /// ✅ APPLE SPEC: Element = Response<Content>.Partial
    public typealias Element = Response<Content>.Partial
    
    /// The async iterator for the stream
    /// ✅ APPLE SPEC: AsyncIterator implementation
    public typealias AsyncIterator = ResponseStreamIterator<Content>
    
    /// The underlying async stream
    /// ✅ APPLE SPEC: Internal stream implementation
    private let stream: AsyncThrowingStream<Response<Content>.Partial, Error>
    
    /// The last partial response received
    /// ✅ APPLE SPEC: Convenience property for UI updates
    public private(set) var last: Response<Content>.Partial?
    
    /// Initialize with an async throwing stream
    /// ✅ APPLE SPEC: Standard initializer
    public init(
        stream: AsyncThrowingStream<Response<Content>.Partial, Error>
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
public struct ResponseStreamIterator<Content: Sendable>: AsyncIteratorProtocol {
    
    /// The element type
    /// ✅ APPLE SPEC: Element type matching parent stream
    public typealias Element = Response<Content>.Partial
    
    /// The underlying stream iterator
    /// ✅ APPLE SPEC: Internal iterator implementation
    private var iterator: AsyncThrowingStream<Response<Content>.Partial, Error>.AsyncIterator
    
    /// Initialize with a stream
    /// ✅ APPLE SPEC: Standard initializer
    public init(
        stream: AsyncThrowingStream<Response<Content>.Partial, Error>
    ) {
        self.iterator = stream.makeAsyncIterator()
    }
    
    /// Get the next element
    /// ✅ APPLE SPEC: AsyncIteratorProtocol conformance
    public mutating func next() async throws -> Element? {
        return try await iterator.next()
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
        var finalContent: Content?
        let allEntries: [Transcript.Entry] = []
        
        for try await partial in self {
            if partial.isComplete {
                finalContent = partial.content
                break
            }
        }
        
        guard let content = finalContent else {
            let context = GenerationError.Context(debugDescription: "Stream completed without complete content")
            throw GenerationError.decodingFailure(context)
        }
        
        // Create transcript entries from the streaming session
        // In a real implementation, this would come from the session's transcript
        let transcriptSlice = ArraySlice(allEntries)
        
        return Response(
            content: content,
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