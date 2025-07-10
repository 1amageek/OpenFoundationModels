import Foundation

/// Represents a prompt to be sent to a language model
public struct Prompt: Sendable {
    /// The text content of the prompt
    public let text: String
    
    /// Additional metadata for the prompt
    public let metadata: [String: String]?
    
    /// Initialize a prompt with text content
    /// - Parameters:
    ///   - text: The prompt text
    ///   - metadata: Optional metadata
    public init(_ text: String, metadata: [String: String]? = nil) {
        self.text = text
        self.metadata = metadata
    }
}

// MARK: - ExpressibleByStringLiteral
extension Prompt: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}