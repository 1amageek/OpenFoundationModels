import Foundation
import OpenFoundationModelsCore

public struct Transcript: Sendable {
    public private(set) var entries: [Entry] = []
    
    public init() {
        self.entries = []
    }
    
    public init<S: Sequence<Entry>>(entries: S) {
        self.entries = Array(entries)
    }
    
    
    public mutating func append(_ entry: Entry) {
        entries.append(entry)
    }
    
    public mutating func append(contentsOf newEntries: [Entry]) {
        entries.append(contentsOf: newEntries)
    }
}

extension Transcript {
    public enum Entry: Sendable, Identifiable, CustomStringConvertible {
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
    public enum Segment: Sendable, Identifiable {
        case text(TextSegment)
        
        case structure(StructuredSegment)
        
        public var id: String {
            switch self {
            case .text(let textSegment):
                return textSegment.id
            case .structure(let structuredSegment):
                return structuredSegment.id
            }
        }
    }
    
    public struct TextSegment: Sendable, Identifiable {
        public var id: String
        
        public var content: String
        
        public init(id: String, content: String) {
            self.id = id
            self.content = content
        }
    }
    
    public struct StructuredSegment: Sendable, Identifiable {
        public var id: String
        
        public var source: String
        
        public var content: GeneratedContent
        
        public init(id: String, source: String, content: GeneratedContent) {
            self.id = id
            self.source = source
            self.content = content
        }
    }
}

extension Transcript {
    public struct Prompt: Sendable, Identifiable {
        public var id: String
        
        public var segments: [Transcript.Segment]
        
        public var options: GenerationOptions
        
        public var responseFormat: Transcript.ResponseFormat?
        
        public init(id: String, segments: [Transcript.Segment], options: GenerationOptions, responseFormat: Transcript.ResponseFormat?) {
            self.id = id
            self.segments = segments
            self.options = options
            self.responseFormat = responseFormat
        }
    }
    
    public struct Response: Sendable, Identifiable {
        public var id: String
        
        public var assetIDs: [String]
        
        public var segments: [Transcript.Segment]
        
        public init(id: String, assetIDs: [String], segments: [Transcript.Segment]) {
            self.id = id
            self.assetIDs = assetIDs
            self.segments = segments
        }
    }
    
    public struct Instructions: Sendable, Identifiable {
        public var id: String
        
        public var segments: [Transcript.Segment]
        
        public var toolDefinitions: [Transcript.ToolDefinition]
        
        public init(id: String, segments: [Transcript.Segment], toolDefinitions: [Transcript.ToolDefinition]) {
            self.id = id
            self.segments = segments
            self.toolDefinitions = toolDefinitions
        }
    }
    
    public struct ToolCall: Sendable, Identifiable {
        public var id: String
        
        public var toolName: String
        
        public var arguments: GeneratedContent
        
        public init(id: String, toolName: String, arguments: GeneratedContent) {
            self.id = id
            self.toolName = toolName
            self.arguments = arguments
        }
    }
    
    public struct ToolCalls: Sendable, Identifiable {
        public var id: String
        
        private var calls: [ToolCall]
        
        public init<S>(id: String, _ calls: S) where S: Sequence, S.Element == ToolCall {
            self.id = id
            self.calls = Array(calls)
        }
        
        internal var toolCalls: [ToolCall] {
            calls
        }
    }
    
    public struct ToolDefinition: Sendable {
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
    
    public struct ToolOutput: Sendable, Identifiable {
        public var id: String
        
        public var toolName: String
        
        public var segments: [Transcript.Segment]
        
        public init(id: String, toolName: String, segments: [Transcript.Segment]) {
            self.id = id
            self.toolName = toolName
            self.segments = segments
        }
    }
    
    public struct ResponseFormat: Sendable {
        public var name: String
        
        private var type: String?
        
        private var schema: GenerationSchema?
        
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


extension Transcript: Equatable {
    public static func ==(lhs: Transcript, rhs: Transcript) -> Bool {
        return lhs.entries == rhs.entries
    }
}

extension Transcript.Entry: Equatable {
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
        return lhs.id == rhs.id && lhs.toolCalls == rhs.toolCalls
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

extension Transcript.ToolCalls: Collection, BidirectionalCollection, RandomAccessCollection {
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

extension Transcript: BidirectionalCollection, RandomAccessCollection {
    public var startIndex: Int { 
        entries.startIndex 
    }
    
    public var endIndex: Int { 
        entries.endIndex 
    }
    
    public subscript(position: Int) -> Entry {
        entries[position]
    }
    
    public func index(after i: Int) -> Int {
        entries.index(after: i)
    }
    
    public func index(before i: Int) -> Int {
        entries.index(before: i)
    }
    
    public var count: Int {
        entries.count
    }
    
    public var isEmpty: Bool {
        entries.isEmpty
    }
}
