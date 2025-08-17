import Foundation

public struct GenerationOptions: Sendable, Equatable {
    
    public struct SamplingMode: Sendable, Equatable {
        
        private enum Kind: Equatable {
            case greedy
            case topK(Int, seed: UInt64?)
            case topP(Double, seed: UInt64?)
        }
        
        private let kind: Kind
        
        private init(kind: Kind) {
            self.kind = kind
        }
        
        public static var greedy: SamplingMode {
            return SamplingMode(kind: .greedy)
        }
        
        public static func random(top k: Int, seed: UInt64? = nil) -> SamplingMode {
            return SamplingMode(kind: .topK(k, seed: seed))
        }
        
        public static func random(probabilityThreshold: Double, seed: UInt64? = nil) -> SamplingMode {
            return SamplingMode(kind: .topP(probabilityThreshold, seed: seed))
        }
        
        public static func == (a: SamplingMode, b: SamplingMode) -> Bool {
            return a.kind == b.kind
        }
    }
    
    public var sampling: SamplingMode?
    
    public var temperature: Double?
    
    public var maximumResponseTokens: Int?
    
    public init(
        sampling: SamplingMode? = nil,
        temperature: Double? = nil,
        maximumResponseTokens: Int? = nil
    ) {
        self.sampling = sampling
        self.temperature = temperature
        self.maximumResponseTokens = maximumResponseTokens
    }
    
    public static var `default`: GenerationOptions {
        return GenerationOptions()
    }
    
    public static func == (a: GenerationOptions, b: GenerationOptions) -> Bool {
        return a.sampling == b.sampling &&
               a.temperature == b.temperature &&
               a.maximumResponseTokens == b.maximumResponseTokens
    }
}