import Foundation

/// Options that control how the model generates its response to a prompt
/// ✅ APPLE SPEC: GenerationOptions structure
/// Referenced in Apple Foundation Models documentation
public struct GenerationOptions: Sendable {
    /// Sampling strategy for generation
    /// ✅ APPLE SPEC: sampling property
    public let sampling: Sampling
    
    /// Maximum number of tokens to generate
    /// ✅ APPLE SPEC: maxTokens property
    public let maxTokens: Int?
    
    /// Temperature for sampling (0.0 to 1.0)
    /// ✅ APPLE SPEC: temperature property (legacy)
    public let temperature: Double?
    
    /// Top-p sampling parameter
    /// ✅ APPLE SPEC: topP property (legacy)
    public let topP: Double?
    
    /// Initialize generation options
    /// ✅ APPLE SPEC: Standard initializer
    public init(
        sampling: Sampling = .greedy,
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil
    ) {
        self.sampling = sampling
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
    }
    
    /// Default generation options
    /// ✅ APPLE SPEC: static let default property
    public static let `default`: GenerationOptions = GenerationOptions(sampling: .greedy)
}

// MARK: - Sampling

extension GenerationOptions {
    /// Sampling strategy for text generation
    /// ✅ APPLE SPEC: Sampling enum
    public enum Sampling: Sendable {
        /// Greedy decoding - always pick the most likely token
        /// ✅ APPLE SPEC: greedy case
        case greedy
        
        /// Random sampling with optional top-p parameter
        /// ✅ APPLE SPEC: random(topP:) case
        case random(topP: Double? = nil)
    }
}

// MARK: - Legacy Support

/// Legacy sampling methods for backward compatibility
/// ✅ DEPRECATED: Use GenerationOptions.Sampling instead
@available(*, deprecated, message: "Use GenerationOptions.Sampling instead")
public enum SamplingMethod: String, Sendable {
    /// Greedy decoding - always pick the most likely token
    case greedy
    
    /// Random sampling with temperature
    case random
}

// MARK: - Conversion Methods

extension GenerationOptions {
    /// Initialize with legacy sampling method
    /// ✅ DEPRECATED: Use init(sampling:) instead
    @available(*, deprecated, message: "Use init(sampling:) instead")
    public init(
        temperature: Double? = nil,
        topP: Double? = nil,
        maxTokens: Int? = nil,
        samplingMethod: SamplingMethod? = nil
    ) {
        self.temperature = temperature
        self.topP = topP
        self.maxTokens = maxTokens
        
        // Convert legacy sampling method to new format
        switch samplingMethod {
        case .greedy:
            self.sampling = .greedy
        case .random:
            self.sampling = .random(topP: topP)
        case .none:
            self.sampling = .greedy
        }
    }
    
    /// Legacy sampling method property
    /// ✅ DEPRECATED: Use sampling property instead
    @available(*, deprecated, message: "Use sampling property instead")
    public var samplingMethod: SamplingMethod? {
        switch sampling {
        case .greedy:
            return .greedy
        case .random:
            return .random
        }
    }
}