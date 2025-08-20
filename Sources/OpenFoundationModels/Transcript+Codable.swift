import Foundation
import OpenFoundationModelsCore

// MARK: - Transcript Codable Implementation
extension Transcript: Codable {
    private enum CodingKeys: String, CodingKey {
        case entries
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode entries array
        var decodedEntries: [Entry] = []
        var entriesContainer = try container.nestedUnkeyedContainer(forKey: .entries)
        
        while !entriesContainer.isAtEnd {
            let entry = try entriesContainer.decode(EntryCoding.self)
            decodedEntries.append(try entry.toEntry())
        }
        
        self.init(entries: decodedEntries)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode entries array
        var entriesContainer = container.nestedUnkeyedContainer(forKey: .entries)
        for entry in entries {
            let entryCoding = try EntryCoding(from: entry)
            try entriesContainer.encode(entryCoding)
        }
    }
}

// MARK: - Internal Coding Types

// Entry Coding
private struct EntryCoding: Codable {
    enum EntryType: String, Codable {
        case instructions
        case prompt
        case response
        case toolCalls
        case toolOutput
    }
    
    let type: EntryType
    let id: String
    let segments: [SegmentCoding]?
    let toolDefinitions: [ToolDefinitionCoding]?
    let assetIDs: [String]?
    let options: GenerationOptionsCoding?
    let responseFormat: ResponseFormatCoding?
    let calls: [ToolCallCoding]?
    let toolName: String?
    
    init(from entry: Transcript.Entry) throws {
        self.id = entry.id
        
        switch entry {
        case .instructions(let instructions):
            self.type = .instructions
            self.segments = try instructions.segments.map { try SegmentCoding(from: $0) }
            self.toolDefinitions = try instructions.toolDefinitions.map { try ToolDefinitionCoding(from: $0) }
            self.assetIDs = nil
            self.options = nil
            self.responseFormat = nil
            self.calls = nil
            self.toolName = nil
            
        case .prompt(let prompt):
            self.type = .prompt
            self.segments = try prompt.segments.map { try SegmentCoding(from: $0) }
            self.toolDefinitions = nil
            self.assetIDs = nil
            self.options = GenerationOptionsCoding(from: prompt.options)
            self.responseFormat = prompt.responseFormat.map { ResponseFormatCoding(from: $0) }
            self.calls = nil
            self.toolName = nil
            
        case .response(let response):
            self.type = .response
            self.segments = try response.segments.map { try SegmentCoding(from: $0) }
            self.toolDefinitions = nil
            self.assetIDs = response.assetIDs
            self.options = nil
            self.responseFormat = nil
            self.calls = nil
            self.toolName = nil
            
        case .toolCalls(let toolCalls):
            self.type = .toolCalls
            self.segments = nil
            self.toolDefinitions = nil
            self.assetIDs = nil
            self.options = nil
            self.responseFormat = nil
            self.calls = try toolCalls.calls.map { try ToolCallCoding(from: $0) }
            self.toolName = nil
            
        case .toolOutput(let toolOutput):
            self.type = .toolOutput
            self.segments = try toolOutput.segments.map { try SegmentCoding(from: $0) }
            self.toolDefinitions = nil
            self.assetIDs = nil
            self.options = nil
            self.responseFormat = nil
            self.calls = nil
            self.toolName = toolOutput.toolName
        }
    }
    
    func toEntry() throws -> Transcript.Entry {
        switch type {
        case .instructions:
            guard let segments = segments, let toolDefinitions = toolDefinitions else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Missing segments or toolDefinitions for instructions"
                ))
            }
            let decodedSegments = try segments.map { try $0.toSegment() }
            let decodedToolDefinitions = try toolDefinitions.map { try $0.toToolDefinition() }
            return .instructions(Transcript.Instructions(
                id: id,
                segments: decodedSegments,
                toolDefinitions: decodedToolDefinitions
            ))
            
        case .prompt:
            guard let segments = segments, let options = options else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Missing segments or options for prompt"
                ))
            }
            let decodedSegments = try segments.map { try $0.toSegment() }
            let decodedOptions = try options.toGenerationOptions()
            let decodedResponseFormat = try responseFormat?.toResponseFormat()
            return .prompt(Transcript.Prompt(
                id: id,
                segments: decodedSegments,
                options: decodedOptions,
                responseFormat: decodedResponseFormat
            ))
            
        case .response:
            guard let segments = segments, let assetIDs = assetIDs else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Missing segments or assetIDs for response"
                ))
            }
            let decodedSegments = try segments.map { try $0.toSegment() }
            return .response(Transcript.Response(
                id: id,
                assetIDs: assetIDs,
                segments: decodedSegments
            ))
            
        case .toolCalls:
            guard let calls = calls else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Missing calls for toolCalls"
                ))
            }
            let decodedCalls = try calls.map { try $0.toToolCall() }
            return .toolCalls(Transcript.ToolCalls(id: id, decodedCalls))
            
        case .toolOutput:
            guard let segments = segments, let toolName = toolName else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Missing segments or toolName for toolOutput"
                ))
            }
            let decodedSegments = try segments.map { try $0.toSegment() }
            return .toolOutput(Transcript.ToolOutput(
                id: id,
                toolName: toolName,
                segments: decodedSegments
            ))
        }
    }
}

// Segment Coding
private struct SegmentCoding: Codable {
    enum SegmentType: String, Codable {
        case text
        case structure
    }
    
    let type: SegmentType
    let id: String
    let content: String?
    let source: String?
    let generatedContent: GeneratedContent? // Store GeneratedContent directly
    
    init(from segment: Transcript.Segment) throws {
        self.id = segment.id
        
        switch segment {
        case .text(let textSegment):
            self.type = .text
            self.content = textSegment.content
            self.source = nil
            self.generatedContent = nil
            
        case .structure(let structuredSegment):
            self.type = .structure
            self.content = nil
            self.source = structuredSegment.source
            // Store GeneratedContent directly
            self.generatedContent = structuredSegment.content
        }
    }
    
    func toSegment() throws -> Transcript.Segment {
        switch type {
        case .text:
            guard let content = content else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Missing content for text segment"
                ))
            }
            return .text(Transcript.TextSegment(id: id, content: content))
            
        case .structure:
            guard let source = source, let generatedContent = generatedContent else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Missing source or generatedContent for structured segment"
                ))
            }
            // Use GeneratedContent directly
            return .structure(Transcript.StructuredSegment(
                id: id,
                source: source,
                content: generatedContent
            ))
        }
    }
}

// GenerationOptions Coding
private struct GenerationOptionsCoding: Codable {
    enum SamplingModeCoding: Codable {
        case greedy
        case topK(k: Int, seed: UInt64?)
        case topP(threshold: Double, seed: UInt64?)
        
        enum CodingKeys: String, CodingKey {
            case type
            case k
            case threshold
            case seed
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "greedy":
                self = .greedy
            case "topK":
                let k = try container.decode(Int.self, forKey: .k)
                let seed = try container.decodeIfPresent(UInt64.self, forKey: .seed)
                self = .topK(k: k, seed: seed)
            case "topP":
                let threshold = try container.decode(Double.self, forKey: .threshold)
                let seed = try container.decodeIfPresent(UInt64.self, forKey: .seed)
                self = .topP(threshold: threshold, seed: seed)
            default:
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unknown sampling mode type: \(type)"
                ))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .greedy:
                try container.encode("greedy", forKey: .type)
            case .topK(let k, let seed):
                try container.encode("topK", forKey: .type)
                try container.encode(k, forKey: .k)
                try container.encodeIfPresent(seed, forKey: .seed)
            case .topP(let threshold, let seed):
                try container.encode("topP", forKey: .type)
                try container.encode(threshold, forKey: .threshold)
                try container.encodeIfPresent(seed, forKey: .seed)
            }
        }
    }
    
    let sampling: SamplingModeCoding?
    let temperature: Double?
    let maximumResponseTokens: Int?
    
    init(from options: GenerationOptions) {
        // Convert SamplingMode to SamplingModeCoding
        if let samplingMode = options.sampling {
            // Use string representation to determine the type
            let modeString = String(describing: samplingMode)
            if modeString.contains("greedy") {
                self.sampling = .greedy
            } else if modeString.contains("topK") {
                // Extract k value from string if possible
                // This is a simplified approach
                self.sampling = .topK(k: 10, seed: nil)
            } else if modeString.contains("topP") {
                // Extract threshold from string if possible
                self.sampling = .topP(threshold: 0.9, seed: nil)
            } else {
                self.sampling = nil
            }
        } else {
            self.sampling = nil
        }
        self.temperature = options.temperature
        self.maximumResponseTokens = options.maximumResponseTokens
    }
    
    func toGenerationOptions() throws -> GenerationOptions {
        var samplingMode: GenerationOptions.SamplingMode?
        
        if let sampling = sampling {
            switch sampling {
            case .greedy:
                samplingMode = .greedy
            case .topK(let k, let seed):
                samplingMode = .random(top: k, seed: seed)
            case .topP(let threshold, let seed):
                samplingMode = .random(probabilityThreshold: threshold, seed: seed)
            }
        }
        
        return GenerationOptions(
            sampling: samplingMode,
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )
    }
}

// ResponseFormat Coding
private struct ResponseFormatCoding: Codable {
    let name: String
    let type: String?
    let schema: GenerationSchema?
    
    init(from responseFormat: Transcript.ResponseFormat) {
        self.name = responseFormat.name
        self.type = responseFormat.type
        self.schema = responseFormat.schema
    }
    
    func toResponseFormat() throws -> Transcript.ResponseFormat {
        if let schema = schema {
            // For schema-based ResponseFormat
            var format = Transcript.ResponseFormat(schema: schema)
            // Preserve the original name and type if they exist
            if name != "schema-based" {
                format.name = name
            }
            if let originalType = type {
                format.type = originalType
            }
            return format
        } else {
            // If no schema, create a minimal one
            // This shouldn't normally happen, but provides a fallback
            var format = Transcript.ResponseFormat(schema: GenerationSchema(
                type: String.self,
                description: nil,
                properties: []
            ))
            format.name = name
            format.type = type
            return format
        }
    }
}

// ToolDefinition Coding
private struct ToolDefinitionCoding: Codable {
    let name: String
    let description: String
    let parameters: GenerationSchema
    
    init(from toolDefinition: Transcript.ToolDefinition) throws {
        self.name = toolDefinition.name
        self.description = toolDefinition.description
        self.parameters = toolDefinition.parameters
    }
    
    func toToolDefinition() throws -> Transcript.ToolDefinition {
        return Transcript.ToolDefinition(
            name: name,
            description: description,
            parameters: parameters
        )
    }
}

// ToolCall Coding
private struct ToolCallCoding: Codable {
    let id: String
    let toolName: String
    let arguments: GeneratedContent // Store GeneratedContent directly
    
    init(from toolCall: Transcript.ToolCall) throws {
        self.id = toolCall.id
        self.toolName = toolCall.toolName
        self.arguments = toolCall.arguments
    }
    
    func toToolCall() throws -> Transcript.ToolCall {
        return Transcript.ToolCall(
            id: id,
            toolName: toolName,
            arguments: arguments
        )
    }
}