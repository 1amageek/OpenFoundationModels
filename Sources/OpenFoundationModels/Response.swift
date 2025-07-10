import Foundation

/// A response from a language model
public struct Response: Sendable {
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