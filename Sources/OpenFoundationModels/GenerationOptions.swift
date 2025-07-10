import Foundation

/// Options for controlling text generation behavior
public struct GenerationOptions: Sendable {
    /// Temperature for sampling (0.0 to 1.0)
    public let temperature: Double?
    
    /// Top-p sampling parameter
    public let topP: Double?
    
    /// Maximum number of tokens to generate
    public let maxTokens: Int?
    
    /// Sampling method
    public let samplingMethod: SamplingMethod?
    
    /// Initialize generation options
    public init(
        temperature: Double? = nil,
        topP: Double? = nil,
        maxTokens: Int? = nil,
        samplingMethod: SamplingMethod? = nil
    ) {
        self.temperature = temperature
        self.topP = topP
        self.maxTokens = maxTokens
        self.samplingMethod = samplingMethod
    }
}

/// Sampling methods for text generation
public enum SamplingMethod: String, Sendable {
    /// Greedy decoding - always pick the most likely token
    case greedy
    
    /// Random sampling with temperature
    case random
}