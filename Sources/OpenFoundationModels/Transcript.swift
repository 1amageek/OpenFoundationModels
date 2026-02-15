import Foundation
import OpenFoundationModelsCore

/// A record of the conversation between the user and the language model.
///
/// Transcript maintains the complete history of interactions including instructions,
/// prompts, responses, tool calls, and tool outputs.
public struct Transcript: Sendable,
                          Copyable,
                          Equatable,
                          SendableMetatype,
                          BidirectionalCollection,
                          RandomAccessCollection {

    package private(set) var entries: [Entry]

    /// Creates a transcript with the given entries.
    public init<S: Sequence<Entry>>(entries: S = []) {
        self.entries = Array(entries)
    }

    // MARK: - RandomAccessCollection

    public typealias Index = Int
    public typealias Element = Transcript.Entry
    public typealias Indices = Range<Transcript.Index>
    public typealias Iterator = IndexingIterator<Transcript>
    public typealias SubSequence = Slice<Transcript>

    public var startIndex: Int {
        entries.startIndex
    }

    public var endIndex: Int {
        entries.endIndex
    }

    public subscript(index: Transcript.Index) -> Transcript.Entry {
        entries[index]
    }

    public func index(before i: Int) -> Int {
        entries.index(before: i)
    }

    public func index(after i: Int) -> Int {
        entries.index(after: i)
    }

    // MARK: - Equatable

    public static func ==(lhs: Transcript, rhs: Transcript) -> Bool {
        return lhs.entries == rhs.entries
    }
}

extension Transcript {
    public enum Entry: Sendable, SendableMetatype, Identifiable, Equatable, CustomStringConvertible {
        public typealias ID = String
        
        case instructions(Transcript.Instructions)
        case prompt(Transcript.Prompt)
        case response(Transcript.Response)
        case toolCalls(Transcript.ToolCalls)
        case toolOutput(Transcript.ToolOutput)
        
        public var id: String {
            switch self {
            case .instructions(let instructions):
                return instructions.id
            case .prompt(let prompt):
                return prompt.id
            case .response(let response):
                return response.id
            case .toolCalls(let toolCalls):
                return toolCalls.id
            case .toolOutput(let toolOutput):
                return toolOutput.id
            }
        }
        
        public var description: String {
            switch self {
            case .instructions(let instructions):
                return "Instructions: \(instructions.id)"
            case .prompt(let prompt):
                return "Prompt: \(prompt.id)"
            case .response(let response):
                return "Response: \(response.id)"
            case .toolCalls(let toolCalls):
                return "Tool Calls: \(toolCalls.id)"
            case .toolOutput(let toolOutput):
                return "Tool Output: \(toolOutput.id)"
            }
        }
    }
}

extension Transcript {
    public enum Segment: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        case text(TextSegment)
        case structure(StructuredSegment)
        case image(ImageSegment)

        public var id: String {
            switch self {
            case .text(let textSegment):
                return textSegment.id
            case .structure(let structuredSegment):
                return structuredSegment.id
            case .image(let imageSegment):
                return imageSegment.id
            }
        }
    }
    
    public struct TextSegment: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        public var id: String
        public var content: String
        
        public init(id: String = UUID().uuidString, content: String) {
            self.id = id
            self.content = content
        }
    }
    
    public struct StructuredSegment: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        public var id: String
        public var source: String
        public var content: GeneratedContent

        public init(id: String = UUID().uuidString, source: String, content: GeneratedContent) {
            self.id = id
            self.source = source
            self.content = content
        }
    }

    public struct ImageSegment: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        public var id: String
        public var source: ImageSource

        public enum ImageSource: Sendable {
            case base64(data: String, mediaType: String)
            case url(URL)
        }

        public init(id: String = UUID().uuidString, source: ImageSource) {
            self.id = id
            self.source = source
        }
    }
}

extension Transcript {
    public struct Prompt: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        public var id: String
        public var segments: [Transcript.Segment]
        public var options: GenerationOptions
        public var responseFormat: Transcript.ResponseFormat?
        
        public init(id: String = UUID().uuidString, segments: [Transcript.Segment], options: GenerationOptions = GenerationOptions(), responseFormat: Transcript.ResponseFormat? = nil) {
            self.id = id
            self.segments = segments
            self.options = options
            self.responseFormat = responseFormat
        }
    }
    
    public struct Response: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        public var id: String
        public var assetIDs: [String]
        public var segments: [Transcript.Segment]
        
        public init(id: String = UUID().uuidString, assetIDs: [String], segments: [Transcript.Segment]) {
            self.id = id
            self.assetIDs = assetIDs
            self.segments = segments
        }
    }
    
    public struct Instructions: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        public var id: String
        public var segments: [Transcript.Segment]
        public var toolDefinitions: [Transcript.ToolDefinition]
        
        public init(id: String = UUID().uuidString, segments: [Transcript.Segment], toolDefinitions: [Transcript.ToolDefinition]) {
            self.id = id
            self.segments = segments
            self.toolDefinitions = toolDefinitions
        }
    }
    
    public struct ToolCall: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        public var id: String
        public var toolName: String
        public var arguments: GeneratedContent
        
        public init(id: String, toolName: String, arguments: GeneratedContent) {
            self.id = id
            self.toolName = toolName
            self.arguments = arguments
        }
    }
    
    public struct ToolCalls: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        public var id: String
        package var calls: [ToolCall]
        
        public init<S>(id: String = UUID().uuidString, _ calls: S) where S: Sequence, S.Element == ToolCall {
            self.id = id
            self.calls = Array(calls)
        }
    }
    
    public struct ToolDefinition: Sendable, SendableMetatype {
        public var name: String

        public var description: String

        public var parameters: GenerationSchema
        
        public init(name: String, description: String, parameters: GenerationSchema) {
            self.name = name
            self.description = description
            self.parameters = parameters
        }
        
        public init(tool: any Tool) {
            self.name = tool.name
            self.description = tool.description
            self.parameters = tool.parameters
        }
    }
    
    public struct ToolOutput: Sendable, SendableMetatype, Identifiable {
        public typealias ID = String

        public var id: String
        public var toolName: String
        public var segments: [Transcript.Segment]
        
        public init(id: String, toolName: String, segments: [Transcript.Segment]) {
            self.id = id
            self.toolName = toolName
            self.segments = segments
        }
    }
    
    public struct ResponseFormat: Sendable, SendableMetatype {
        public var name: String

        package var type: String?

        package var schema: GenerationSchema?
        
        public init(schema: GenerationSchema) {
            self.name = "schema-based"
            self.type = nil
            self.schema = schema
        }
        
        public init<Content>(type: Content.Type) where Content: Generable {
            self.name = String(describing: type)
            self.type = String(describing: type)
            self.schema = Content.generationSchema
        }
    }
}


// MARK: - Equatable Implementations
extension Transcript.Entry {
    public static func ==(lhs: Transcript.Entry, rhs: Transcript.Entry) -> Bool {
        switch (lhs, rhs) {
        case (.instructions(let l), .instructions(let r)):
            return l == r
        case (.prompt(let l), .prompt(let r)):
            return l == r
        case (.response(let l), .response(let r)):
            return l == r
        case (.toolCalls(let l), .toolCalls(let r)):
            return l == r
        case (.toolOutput(let l), .toolOutput(let r)):
            return l == r
        default:
            return false
        }
    }
}

extension Transcript.Segment: Equatable {
    public static func ==(lhs: Transcript.Segment, rhs: Transcript.Segment) -> Bool {
        switch (lhs, rhs) {
        case (.text(let l), .text(let r)):
            return l == r
        case (.structure(let l), .structure(let r)):
            return l == r
        case (.image(let l), .image(let r)):
            return l == r
        default:
            return false
        }
    }
}

extension Transcript.ImageSegment: Equatable {
    public static func ==(lhs: Transcript.ImageSegment, rhs: Transcript.ImageSegment) -> Bool {
        return lhs.id == rhs.id && lhs.source == rhs.source
    }
}

extension Transcript.ImageSegment.ImageSource: Equatable {
    public static func ==(lhs: Transcript.ImageSegment.ImageSource, rhs: Transcript.ImageSegment.ImageSource) -> Bool {
        switch (lhs, rhs) {
        case (.base64(let lData, let lType), .base64(let rData, let rType)):
            return lData == rData && lType == rType
        case (.url(let l), .url(let r)):
            return l == r
        default:
            return false
        }
    }
}

extension Transcript.TextSegment: Equatable {
    public static func ==(lhs: Transcript.TextSegment, rhs: Transcript.TextSegment) -> Bool {
        return lhs.id == rhs.id && lhs.content == rhs.content
    }
}

extension Transcript.StructuredSegment: Equatable {
    public static func ==(lhs: Transcript.StructuredSegment, rhs: Transcript.StructuredSegment) -> Bool {
        return lhs.id == rhs.id && lhs.source == rhs.source && lhs.content == rhs.content
    }
}

extension Transcript.Instructions: Equatable {
    public static func ==(lhs: Transcript.Instructions, rhs: Transcript.Instructions) -> Bool {
        return lhs.id == rhs.id && lhs.segments == rhs.segments && lhs.toolDefinitions == rhs.toolDefinitions
    }
}

extension Transcript.Prompt: Equatable {
    public static func ==(lhs: Transcript.Prompt, rhs: Transcript.Prompt) -> Bool {
        return lhs.id == rhs.id && lhs.segments == rhs.segments && lhs.options == rhs.options && lhs.responseFormat == rhs.responseFormat
    }
}

extension Transcript.ResponseFormat: Equatable {
    public static func ==(lhs: Transcript.ResponseFormat, rhs: Transcript.ResponseFormat) -> Bool {
        // Can only compare name and type since GenerationSchema is not Equatable
        return lhs.name == rhs.name && lhs.type == rhs.type
    }
}

extension Transcript.ToolCalls: Equatable {
    public static func ==(lhs: Transcript.ToolCalls, rhs: Transcript.ToolCalls) -> Bool {
        guard lhs.id == rhs.id else { return false }
        guard lhs.calls.count == rhs.calls.count else { return false }
        for i in 0..<lhs.calls.count {
            if lhs.calls[i] != rhs.calls[i] { return false }
        }
        return true
    }
}

extension Transcript.ToolCall: Equatable {
    public static func ==(lhs: Transcript.ToolCall, rhs: Transcript.ToolCall) -> Bool {
        return lhs.id == rhs.id && lhs.toolName == rhs.toolName && lhs.arguments == rhs.arguments
    }
}

extension Transcript.ToolDefinition: Equatable {
    public static func ==(lhs: Transcript.ToolDefinition, rhs: Transcript.ToolDefinition) -> Bool {
        // Can only compare name and description since GenerationSchema is not Equatable
        return lhs.name == rhs.name && lhs.description == rhs.description
    }
}

extension Transcript.ToolOutput: Equatable {
    public static func ==(lhs: Transcript.ToolOutput, rhs: Transcript.ToolOutput) -> Bool {
        return lhs.id == rhs.id && lhs.toolName == rhs.toolName && lhs.segments == rhs.segments
    }
}

extension Transcript.Response: Equatable {
    public static func ==(lhs: Transcript.Response, rhs: Transcript.Response) -> Bool {
        return lhs.id == rhs.id && lhs.assetIDs == rhs.assetIDs && lhs.segments == rhs.segments
    }
}

// MARK: - ToolCalls Collection
extension Transcript.ToolCalls: RandomAccessCollection {
    public typealias Element = Transcript.ToolCall
    public typealias Index = Int
    public typealias Indices = Range<Int>
    public typealias Iterator = IndexingIterator<Transcript.ToolCalls>
    public typealias SubSequence = Slice<Transcript.ToolCalls>
    
    public var startIndex: Int { calls.startIndex }
    public var endIndex: Int { calls.endIndex }
    
    public subscript(position: Int) -> Transcript.ToolCall {
        calls[position]
    }
    
    public func index(after i: Int) -> Int {
        calls.index(after: i)
    }
    
    public func index(before i: Int) -> Int {
        calls.index(before: i)
    }
}

// MARK: - CustomStringConvertible Implementations
extension Transcript.Segment: CustomStringConvertible {
    public var description: String {
        switch self {
        case .text(let segment):
            return segment.description
        case .structure(let segment):
            return segment.description
        case .image(let segment):
            return segment.description
        }
    }
}

extension Transcript.ImageSegment: CustomStringConvertible {
    public var description: String {
        switch source {
        case .base64(_, let mediaType):
            return "Image(base64, \(mediaType))"
        case .url(let url):
            return "Image(\(url.absoluteString))"
        }
    }
}

extension Transcript.TextSegment: CustomStringConvertible {
    public var description: String {
        return content
    }
}

extension Transcript.StructuredSegment: CustomStringConvertible {
    public var description: String {
        return "StructuredSegment(source: \(source), content: \(content.debugDescription))"
    }
}

extension Transcript.Instructions: CustomStringConvertible {
    public var description: String {
        let segmentTexts = segments.map { $0.description }.joined(separator: " ")
        let toolCount = toolDefinitions.count
        return "Instructions: \(segmentTexts) (Tools: \(toolCount))"
    }
}

extension Transcript.Prompt: CustomStringConvertible {
    public var description: String {
        let segmentTexts = segments.map { $0.description }.joined(separator: " ")
        return "Prompt: \(segmentTexts)"
    }
}

extension Transcript.ResponseFormat: CustomStringConvertible {
    public var description: String {
        return "ResponseFormat(name: \(name))"
    }
}

extension Transcript.ToolCalls: CustomStringConvertible {
    public var description: String {
        let callDescriptions = calls.map { $0.description }.joined(separator: ", ")
        return "ToolCalls: [\(callDescriptions)]"
    }
}

extension Transcript.ToolCall: CustomStringConvertible {
    public var description: String {
        return "\(toolName)(\(arguments.debugDescription))"
    }
}

extension Transcript.ToolOutput: CustomStringConvertible {
    public var description: String {
        let segmentTexts = segments.map { $0.description }.joined(separator: " ")
        return "ToolOutput(\(toolName)): \(segmentTexts)"
    }
}

extension Transcript.Response: CustomStringConvertible {
    public var description: String {
        let segmentTexts = segments.map { $0.description }.joined(separator: " ")
        return "Response: \(segmentTexts)"
    }
}

