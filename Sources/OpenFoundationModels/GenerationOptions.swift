import Foundation

/// Per-request generation controls.
///
/// The `sampling`, `temperature`, and `maximumResponseTokens` properties mirror
/// Apple's `FoundationModels.GenerationOptions` exactly; code written against the
/// Apple framework continues to compile and behave identically here.
///
/// Additional properties (`topP`, `topK`, `minP`, `repetitionPenalty`,
/// `presencePenalty`, `frequencyPenalty`, `repetitionContextSize`) are
/// **OpenFoundationModels-specific extensions** that have no counterpart in Apple's
/// API. They exist to expose sampling controls of third-party backends that Apple's
/// unified surface does not model. All extension properties default to `nil`; when
/// every extension field is `nil`, behavior is indistinguishable from the
/// Apple-mirrored subset.
public struct GenerationOptions: Sendable, SendableMetatype, Equatable {

    public struct SamplingMode: Sendable, SendableMetatype, Equatable {

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

    // MARK: - Apple-mirrored fields
    //
    // The three properties below match Apple's `FoundationModels.GenerationOptions`
    // signature exactly. Do not change their names, types, or order.

    /// Apple FoundationModels-compatible.
    public var sampling: SamplingMode?

    /// Apple FoundationModels-compatible.
    public var temperature: Double?

    /// Apple FoundationModels-compatible.
    public var maximumResponseTokens: Int?

    // MARK: - Backend-extensible sampling fields
    //
    // ⚠️ NOT PART OF Apple FoundationModels SPECIFICATION.
    //
    // The fields below are OpenFoundationModels-specific extensions and have
    // no counterpart in Apple's `FoundationModels.GenerationOptions`. They
    // exist because OpenFoundationModels bridges to heterogeneous third-party
    // backends (Ollama / Claude / OpenAI Responses / MLX / Metal), each of
    // which exposes sampling controls that Apple's unified surface does not
    // model. Code that targets Apple's framework directly will not see these
    // properties.
    //
    // Compatibility contract:
    //   - All fields are Optional with `nil` meaning "use backend default".
    //   - Leaving every extension field at `nil` reproduces Apple-mirrored
    //     behavior exactly, so existing Apple-compatible call sites are
    //     unaffected.
    //   - Each backend reads only the fields it can interpret; unsupported
    //     fields are silently ignored (documented per-backend below).

    /// **OpenFoundationModels extension — not in Apple FoundationModels.**
    /// Nucleus sampling threshold. Tokens are sampled from the smallest set
    /// whose cumulative probability is at least `topP`.
    /// Interpreted by: Ollama, Claude, MLX, Metal, Response.
    public var topP: Double?

    /// **OpenFoundationModels extension — not in Apple FoundationModels.**
    /// Top-K sampling cutoff. Restricts sampling to the `topK` highest
    /// probability tokens.
    /// Interpreted by: Ollama, Claude, Metal.
    public var topK: Int?

    /// **OpenFoundationModels extension — not in Apple FoundationModels.**
    /// Minimum probability mass relative to the most likely token. Tokens
    /// with probability below `minP * max_prob` are filtered.
    /// Interpreted by: Metal.
    public var minP: Double?

    /// **OpenFoundationModels extension — not in Apple FoundationModels.**
    /// Multiplicative penalty applied to tokens that have already appeared
    /// in the recent context. `1.0` disables the penalty.
    /// Interpreted by: Ollama, MLX, Metal.
    public var repetitionPenalty: Double?

    /// **OpenFoundationModels extension — not in Apple FoundationModels.**
    /// Additive penalty applied once per token that has appeared in the
    /// generated context. `0.0` disables the penalty.
    /// Interpreted by: Ollama, Metal.
    public var presencePenalty: Double?

    /// **OpenFoundationModels extension — not in Apple FoundationModels.**
    /// Additive penalty applied proportionally to a token's frequency in
    /// the generated context. `0.0` disables the penalty.
    /// Interpreted by: Response (OpenAI).
    public var frequencyPenalty: Double?

    /// **OpenFoundationModels extension — not in Apple FoundationModels.**
    /// Number of recent tokens considered when applying repetition or
    /// presence penalties.
    /// Interpreted by: MLX, Metal.
    public var repetitionContextSize: Int?

    // MARK: - Initializers
    //
    // Two initializers are provided to make the Apple-compatibility boundary
    // explicit at construction:
    //
    //   1. `init(sampling:temperature:maximumResponseTokens:)` — Apple
    //      FoundationModels-compatible. Mirrors Apple's signature exactly.
    //   2. `init(sampling:temperature:maximumResponseTokens:extensions:)` —
    //      OpenFoundationModels-extended. Takes the Apple-mirrored fields plus
    //      a required `Extensions` value carrying the non-Apple sampling
    //      controls. The `extensions:` label disambiguates the two overloads
    //      and signals at the call site that backend-specific fields are in
    //      play.
    //
    // Direct property access (`opts.repetitionPenalty = 1.1`) remains available
    // for both ergonomic mutation and Codable round-tripping; the separated
    // initializers exist to make the API boundary readable, not to gate access.

    /// **OpenFoundationModels extension — not in Apple FoundationModels.**
    /// Bundled value type for the non-Apple sampling fields. Pass to
    /// ``GenerationOptions/init(sampling:temperature:maximumResponseTokens:extensions:)``
    /// to construct a `GenerationOptions` whose call site explicitly opts into
    /// the OpenFoundationModels extension surface.
    public struct Extensions: Sendable, SendableMetatype, Equatable {
        public var topP: Double?
        public var topK: Int?
        public var minP: Double?
        public var repetitionPenalty: Double?
        public var presencePenalty: Double?
        public var frequencyPenalty: Double?
        public var repetitionContextSize: Int?

        public init(
            topP: Double? = nil,
            topK: Int? = nil,
            minP: Double? = nil,
            repetitionPenalty: Double? = nil,
            presencePenalty: Double? = nil,
            frequencyPenalty: Double? = nil,
            repetitionContextSize: Int? = nil
        ) {
            self.topP = topP
            self.topK = topK
            self.minP = minP
            self.repetitionPenalty = repetitionPenalty
            self.presencePenalty = presencePenalty
            self.frequencyPenalty = frequencyPenalty
            self.repetitionContextSize = repetitionContextSize
        }
    }

    /// Apple FoundationModels-compatible initializer.
    ///
    /// Constructs a `GenerationOptions` populated only with the Apple-mirrored
    /// fields. Every OpenFoundationModels extension field is left at `nil`,
    /// reproducing Apple's behavior exactly. Use this overload from code that
    /// targets the Apple FoundationModels API surface.
    public init(
        sampling: SamplingMode? = nil,
        temperature: Double? = nil,
        maximumResponseTokens: Int? = nil
    ) {
        self.sampling = sampling
        self.temperature = temperature
        self.maximumResponseTokens = maximumResponseTokens
    }

    /// **OpenFoundationModels extension — not in Apple FoundationModels.**
    /// Extended initializer that takes Apple-mirrored fields plus a bundle
    /// of OpenFoundationModels extension fields.
    ///
    /// The required `extensions:` argument distinguishes this overload from
    /// the Apple-compatible initializer above and marks the call site as
    /// relying on backend-specific sampling controls.
    public init(
        sampling: SamplingMode? = nil,
        temperature: Double? = nil,
        maximumResponseTokens: Int? = nil,
        extensions: Extensions
    ) {
        self.sampling = sampling
        self.temperature = temperature
        self.maximumResponseTokens = maximumResponseTokens
        self.topP = extensions.topP
        self.topK = extensions.topK
        self.minP = extensions.minP
        self.repetitionPenalty = extensions.repetitionPenalty
        self.presencePenalty = extensions.presencePenalty
        self.frequencyPenalty = extensions.frequencyPenalty
        self.repetitionContextSize = extensions.repetitionContextSize
    }

    /// Apple FoundationModels-compatible.
    public static var `default`: GenerationOptions {
        return GenerationOptions()
    }

    public static func == (a: GenerationOptions, b: GenerationOptions) -> Bool {
        return a.sampling == b.sampling
            && a.temperature == b.temperature
            && a.maximumResponseTokens == b.maximumResponseTokens
            && a.topP == b.topP
            && a.topK == b.topK
            && a.minP == b.minP
            && a.repetitionPenalty == b.repetitionPenalty
            && a.presencePenalty == b.presencePenalty
            && a.frequencyPenalty == b.frequencyPenalty
            && a.repetitionContextSize == b.repetitionContextSize
    }
}
