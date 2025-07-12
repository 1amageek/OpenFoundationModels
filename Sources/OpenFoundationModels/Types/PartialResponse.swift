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

/// Legacy generic PartiallyGenerated type - DEPRECATED
/// ✅ PHASE 4.2: Replaced by type-specific nested PartiallyGenerated types
/// Each @Generable type now auto-generates its own nested PartiallyGenerated struct
/// This generic version is kept for backwards compatibility but should not be used
@available(*, deprecated, message: "Use type-specific nested PartiallyGenerated types instead")
public struct PartiallyGenerated<T: Generable>: Sendable {
    /// The partial instance (may have nil fields)
    public let partial: T?
    
    /// Whether generation is complete
    public let isComplete: Bool
    
    /// Raw JSON content generated so far
    public let rawContent: String
    
    public init(
        partial: T? = nil,
        isComplete: Bool = false,
        rawContent: String = ""
    ) {
        self.partial = partial
        self.isComplete = isComplete
        self.rawContent = rawContent
    }
}