import Foundation

/// A structure that stores the output of a response call.
/// 
/// **Apple Foundation Models Documentation:**
/// A response from a language model that contains the generated content
/// and associated transcript entries from the interaction.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response
/// 
/// **Apple Official API:** `struct Response<Content>`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Properties:**
/// - `content: Content` - The response content
/// - `transcriptEntries: ArraySlice<Transcript.Entry>` - The list of transcript entries
/// 
/// **Usage:**
/// ```swift
/// let response = try await session.respond { Prompt("Hello") }
/// print(response.content) // Generated content
/// print(response.transcriptEntries) // Transcript entries
/// ```
public struct Response<Content: Sendable>: Sendable {
    /// The response content.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// The generated content from the language model response.
    /// The type depends on the generation method used.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/content
    public let content: Content
    
    /// The list of transcript entries.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// The transcript entries associated with this response,
    /// documenting the interaction history.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/transcriptentries
    public let transcriptEntries: ArraySlice<Transcript.Entry>
    
    /// Initialize a response with Apple-compliant structure
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a response with generated content and transcript entries.
    /// 
    /// - Parameters:
    ///   - content: The generated content
    ///   - transcriptEntries: The associated transcript entries
    public init(
        content: Content,
        transcriptEntries: ArraySlice<Transcript.Entry>
    ) {
        self.content = content
        self.transcriptEntries = transcriptEntries
    }
    
    /// Legacy initializer for backward compatibility
    /// 
    /// **Deprecated:** Use init(content:transcriptEntries:) instead
    /// This initializer is provided for migration from older implementations.
    @available(*, deprecated, message: "Use init(content:transcriptEntries:) instead")
    public init(
        userPrompt: String,
        content: Content,
        duration: TimeInterval
    ) {
        self.content = content
        // Create a minimal transcript entry for compatibility
        let entry = Transcript.Entry(
            prompt: userPrompt,
            response: "",
            timestamp: Date(),
            duration: duration
        )
        self.transcriptEntries = [entry][...]
    }
}

// MARK: - Response.Partial

extension Response {
    /// Partial response during streaming
    /// ✅ APPLE SPEC: Response<Content>.Partial nested type
    public struct Partial: Sendable {
        /// The partial content being generated
        /// ✅ APPLE SPEC: content property (generic for different content types)
        public let content: Content
        
        /// Whether the generation is complete
        /// ✅ APPLE SPEC: isComplete property
        public let isComplete: Bool
        
        /// Initialize a partial response
        /// ✅ APPLE SPEC: Standard initializer
        public init(
            content: Content,
            isComplete: Bool
        ) {
            self.content = content
            self.isComplete = isComplete
        }
    }
}

// MARK: - String specialization (already handled by main Partial type)

// MARK: - Legacy Response (for backward compatibility)

/// Legacy non-generic Response type
/// ✅ DEPRECATED: Use Response<String> instead
@available(*, deprecated, message: "Use Response<String> instead")
public struct LegacyResponse: Sendable {
    /// The generated content
    public let content: String
    
    /// Token usage information
    public let usage: TokenUsage?
    
    /// Metadata about the response
    public let metadata: ResponseMetadata?
    
    /// Initialize a response
    public init(
        content: String,
        usage: TokenUsage? = nil,
        metadata: ResponseMetadata? = nil
    ) {
        self.content = content
        self.usage = usage
        self.metadata = metadata
    }
}

/// Token usage information
public struct TokenUsage: Sendable {
    /// Number of tokens in the prompt
    public let promptTokens: Int
    
    /// Number of tokens in the completion
    public let completionTokens: Int
    
    /// Total tokens used
    public var totalTokens: Int {
        promptTokens + completionTokens
    }
    
    public init(promptTokens: Int, completionTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
    }
}

/// Metadata about a response
public struct ResponseMetadata: Sendable {
    /// The model that generated the response
    public let model: String?
    
    /// Time taken to generate the response
    public let latency: TimeInterval?
    
    /// Additional provider-specific metadata
    public let providerMetadata: [String: String]?
    
    public init(
        model: String? = nil,
        latency: TimeInterval? = nil,
        providerMetadata: [String: String]? = nil
    ) {
        self.model = model
        self.latency = latency
        self.providerMetadata = providerMetadata
    }
}