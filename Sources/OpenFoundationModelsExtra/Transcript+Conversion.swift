import OpenFoundationModels
import OpenFoundationModelsCore

/// A structured representation of a Transcript with tool calls and outputs paired.
///
/// `ResolvedTranscript` normalizes the raw entry sequence of a `Transcript`
/// in a single pass, matching tool calls with their outputs into `ToolInteraction` pairs.
/// Use this as the starting point when converting a `Transcript` to a
/// provider-specific API request.
///
/// ```swift
/// let resolved = transcript.resolved()
/// for entry in resolved {
///     switch entry {
///     case .instructions(let instructions): ...
///     case .prompt(let prompt):             ...
///     case .response(let response):         ...
///     case .tool(let interaction):          ...
///     }
/// }
/// ```
public struct ResolvedTranscript: Sendable, Equatable {

    /// A matched pair of tool calls and their corresponding outputs.
    public struct ToolInteraction: Sendable, Equatable {
        /// The tool calls issued by the model.
        public let calls: Transcript.ToolCalls
        /// The outputs returned for each call, in order.
        /// May be empty if the transcript ends before outputs were recorded.
        public let outputs: [Transcript.ToolOutput]
    }

    /// A single entry in the resolved transcript.
    ///
    /// Mirrors `Transcript.Entry` but replaces the separate `toolCalls` and
    /// `toolOutput` cases with a single `tool` case that pairs them together.
    public enum Entry: Sendable, Equatable {
        /// Developer-provided instructions.
        case instructions(Transcript.Instructions)
        /// User-side input, including generation options and optional response format.
        case prompt(Transcript.Prompt)
        /// Model-generated response.
        case response(Transcript.Response)
        /// A tool use round-trip: calls issued by the model and their results.
        case tool(ToolInteraction)
    }

    private let entries: [Entry]

    /// Tool definitions from the most recent `instructions` entry.
    /// Empty when the transcript contains no instructions with tools.
    public let toolDefinitions: [Transcript.ToolDefinition]

    /// Generation options from the most recent `prompt` entry.
    /// `nil` when the transcript contains no prompt entries.
    public let latestOptions: GenerationOptions?

    /// Response format from the most recent `prompt` entry.
    /// `nil` when the latest prompt does not specify a response format.
    public let latestResponseFormat: Transcript.ResponseFormat?

    init(entries: [Entry], toolDefinitions: [Transcript.ToolDefinition], latestOptions: GenerationOptions?, latestResponseFormat: Transcript.ResponseFormat?) {
        self.entries = entries
        self.toolDefinitions = toolDefinitions
        self.latestOptions = latestOptions
        self.latestResponseFormat = latestResponseFormat
    }
}

// MARK: - RandomAccessCollection

extension ResolvedTranscript: RandomAccessCollection {
    public typealias Element = Entry
    public typealias Index = Int

    public var startIndex: Int { entries.startIndex }
    public var endIndex: Int { entries.endIndex }

    public subscript(position: Int) -> Entry {
        entries[position]
    }

    public func index(after i: Int) -> Int { entries.index(after: i) }
    public func index(before i: Int) -> Int { entries.index(before: i) }
}

// MARK: - Transcript.resolved()

extension Transcript {

    /// Resolves the transcript into a `ResolvedTranscript` in a single pass.
    ///
    /// The resolution:
    /// - Matches `toolCalls` entries with the `toolOutput` entries that follow
    /// - Tracks tool definitions, generation options, and response format from the latest entries
    public func resolved() -> ResolvedTranscript {
        var entries: [ResolvedTranscript.Entry] = []
        var pendingCalls: Transcript.ToolCalls? = nil
        var pendingOutputs: [Transcript.ToolOutput] = []
        var toolDefinitions: [Transcript.ToolDefinition] = []
        var latestOptions: GenerationOptions? = nil
        var latestResponseFormat: Transcript.ResponseFormat? = nil

        func flush() {
            guard let calls = pendingCalls else { return }
            entries.append(.tool(.init(calls: calls, outputs: pendingOutputs)))
            pendingCalls = nil
            pendingOutputs = []
        }

        for entry in self {
            switch entry {
            case .instructions(let i):
                flush()
                entries.append(.instructions(i))
                toolDefinitions = i.toolDefinitions

            case .prompt(let p):
                flush()
                entries.append(.prompt(p))
                latestOptions = p.options
                latestResponseFormat = p.responseFormat

            case .response(let r):
                flush()
                entries.append(.response(r))

            case .toolCalls(let tc):
                flush()
                pendingCalls = tc

            case .toolOutput(let to):
                guard pendingCalls != nil else { break }
                pendingOutputs.append(to)
            }
        }

        flush()

        return ResolvedTranscript(
            entries: entries,
            toolDefinitions: toolDefinitions,
            latestOptions: latestOptions,
            latestResponseFormat: latestResponseFormat
        )
    }
}
