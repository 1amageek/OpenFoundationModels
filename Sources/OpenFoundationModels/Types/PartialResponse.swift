import Foundation

/// A partial response during streaming
public struct PartialResponse: Sendable {
    /// The partial content (delta)
    public let delta: String
    
    /// Whether this is the final chunk
    public let isComplete: Bool
    
    /// Cumulative content up to this point
    public let accumulated: String?
    
    public init(
        delta: String,
        isComplete: Bool = false,
        accumulated: String? = nil
    ) {
        self.delta = delta
        self.isComplete = isComplete
        self.accumulated = accumulated
    }
}

