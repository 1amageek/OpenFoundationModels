import Foundation
import OpenFoundationModelsCore

// MARK: - Transcript: Codable

extension Transcript: Codable {

    private enum TopLevelKeys: String, CodingKey {
        case type, version, transcript
    }

    private enum TranscriptKeys: String, CodingKey {
        case entries
    }

    public init(from decoder: any Decoder) throws {
        let top = try decoder.container(keyedBy: TopLevelKeys.self)
        let inner = try top.nestedContainer(keyedBy: TranscriptKeys.self, forKey: .transcript)
        var unkeyedEntries = try inner.nestedUnkeyedContainer(forKey: .entries)
        var decoded: [Entry] = []
        while !unkeyedEntries.isAtEnd {
            let coding = try unkeyedEntries.decode(EntryCoding.self)
            decoded.append(try coding.toEntry())
        }
        self.init(entries: decoded)
    }

    public func encode(to encoder: any Encoder) throws {
        var top = encoder.container(keyedBy: TopLevelKeys.self)
        try top.encode("FoundationModels.Transcript", forKey: .type)
        try top.encode(1, forKey: .version)
        var inner = top.nestedContainer(keyedBy: TranscriptKeys.self, forKey: .transcript)
        var unkeyedEntries = inner.nestedUnkeyedContainer(forKey: .entries)
        for entry in entries {
            try unkeyedEntries.encode(EntryCoding(entry))
        }
    }
}

// MARK: - Entry

private struct EntryCoding: Codable {

    private enum Role: String, Codable {
        case instructions
        case user
        case response
        case tool
    }

    private enum CodingKeys: String, CodingKey {
        case id, role
        case contents, options, responseFormat
        case tools
        case toolCalls
        case assets
        case toolName, toolCallID
    }

    // Shared
    let id: String
    private let role: Role

    // instructions / user / tool / response(model)
    let contents: [SegmentCoding]?

    // user (prompt)
    let options: GenerationOptionsCoding?
    let responseFormat: ResponseFormatCoding?

    // instructions
    let tools: [ToolDefinitionCoding]?

    // response(toolCalls)
    let toolCalls: [ToolCallCoding]?

    // response(model)
    let assets: [String]?

    // tool (toolOutput)
    let toolName: String?
    let toolCallID: String?

    // MARK: Encode

    init(_ entry: Transcript.Entry) throws {
        id = entry.id
        switch entry {
        case .instructions(let instr):
            role = .instructions
            contents = try instr.segments.map(SegmentCoding.init)
            tools = instr.toolDefinitions.isEmpty ? nil : instr.toolDefinitions.map(ToolDefinitionCoding.init)
            options = nil; responseFormat = nil; toolCalls = nil; assets = nil; toolName = nil; toolCallID = nil

        case .prompt(let p):
            role = .user
            contents = try p.segments.map(SegmentCoding.init)
            options = GenerationOptionsCoding(p.options)
            responseFormat = p.responseFormat.map(ResponseFormatCoding.init)
            tools = nil; toolCalls = nil; assets = nil; toolName = nil; toolCallID = nil

        case .toolCalls(let tc):
            role = .response
            toolCalls = try tc.calls.map(ToolCallCoding.init)
            contents = nil; options = nil; responseFormat = nil; tools = nil; assets = nil; toolName = nil; toolCallID = nil

        case .toolOutput(let to):
            role = .tool
            toolName = to.toolName
            toolCallID = to.id
            contents = try to.segments.map(SegmentCoding.init)
            options = nil; responseFormat = nil; tools = nil; toolCalls = nil; assets = nil

        case .response(let r):
            role = .response
            assets = r.assetIDs
            contents = try r.segments.map(SegmentCoding.init)
            options = nil; responseFormat = nil; tools = nil; toolCalls = nil; toolName = nil; toolCallID = nil
        }
    }

    // MARK: Decode

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        role = try c.decode(Role.self, forKey: .role)
        contents = try c.decodeIfPresent([SegmentCoding].self, forKey: .contents)
        options = try c.decodeIfPresent(GenerationOptionsCoding.self, forKey: .options)
        responseFormat = try c.decodeIfPresent(ResponseFormatCoding.self, forKey: .responseFormat)
        tools = try c.decodeIfPresent([ToolDefinitionCoding].self, forKey: .tools)
        toolCalls = try c.decodeIfPresent([ToolCallCoding].self, forKey: .toolCalls)
        assets = try c.decodeIfPresent([String].self, forKey: .assets)
        toolName = try c.decodeIfPresent(String.self, forKey: .toolName)
        toolCallID = try c.decodeIfPresent(String.self, forKey: .toolCallID)
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(role, forKey: .role)
        try c.encodeIfPresent(contents, forKey: .contents)
        try c.encodeIfPresent(options, forKey: .options)
        try c.encodeIfPresent(responseFormat, forKey: .responseFormat)
        try c.encodeIfPresent(tools, forKey: .tools)
        try c.encodeIfPresent(toolCalls, forKey: .toolCalls)
        try c.encodeIfPresent(assets, forKey: .assets)
        try c.encodeIfPresent(toolName, forKey: .toolName)
        try c.encodeIfPresent(toolCallID, forKey: .toolCallID)
    }

    func toEntry() throws -> Transcript.Entry {
        switch role {
        case .instructions:
            let segs = try (contents ?? []).map { try $0.toSegment() }
            let toolDefs = (tools ?? []).map { $0.toToolDefinition() }
            return .instructions(Transcript.Instructions(id: id, segments: segs, toolDefinitions: toolDefs))

        case .user:
            let segs = try (contents ?? []).map { try $0.toSegment() }
            let opts = try options?.toGenerationOptions() ?? GenerationOptions()
            let fmt = try responseFormat?.toResponseFormat()
            return .prompt(Transcript.Prompt(id: id, segments: segs, options: opts, responseFormat: fmt))

        case .response:
            if let calls = toolCalls {
                let decoded = try calls.map { try $0.toToolCall() }
                return .toolCalls(Transcript.ToolCalls(id: id, decoded))
            } else {
                let segs = try (contents ?? []).map { try $0.toSegment() }
                return .response(Transcript.Response(id: id, assetIDs: assets ?? [], segments: segs))
            }

        case .tool:
            guard let name = toolName else {
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "toolOutput missing toolName"))
            }
            let segs = try (contents ?? []).map { try $0.toSegment() }
            return .toolOutput(Transcript.ToolOutput(id: id, toolName: name, segments: segs))
        }
    }
}

// MARK: - Segment

private struct SegmentCoding: Codable {

    private enum SegmentType: String, Codable {
        case text, reasoning, structure, image
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, text, structure, image
    }

    private enum StructureKeys: String, CodingKey {
        case content, source
    }

    private enum ImageKeys: String, CodingKey {
        case sourceType, data, mediaType, url
    }

    let segment: Transcript.Segment

    init(_ segment: Transcript.Segment) throws {
        self.segment = segment
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = try c.decode(String.self, forKey: .id)
        let type = try c.decode(SegmentType.self, forKey: .type)
        switch type {
        case .text:
            let text = try c.decode(String.self, forKey: .text)
            segment = .text(Transcript.TextSegment(id: id, content: text))

        case .reasoning:
            let text = try c.decode(String.self, forKey: .text)
            segment = .reasoning(Transcript.TextSegment(id: id, content: text))

        case .structure:
            let nested = try c.nestedContainer(keyedBy: StructureKeys.self, forKey: .structure)
            let source = try nested.decode(String.self, forKey: .source)
            let content = try nested.decode(GeneratedContent.self, forKey: .content)
            segment = .structure(Transcript.StructuredSegment(id: id, source: source, content: content))

        case .image:
            let nested = try c.nestedContainer(keyedBy: ImageKeys.self, forKey: .image)
            let sourceType = try nested.decode(String.self, forKey: .sourceType)
            if sourceType == "base64" {
                let data = try nested.decode(String.self, forKey: .data)
                let mediaType = try nested.decode(String.self, forKey: .mediaType)
                segment = .image(Transcript.ImageSegment(id: id, source: .base64(data: data, mediaType: mediaType)))
            } else {
                let url = try nested.decode(URL.self, forKey: .url)
                segment = .image(Transcript.ImageSegment(id: id, source: .url(url)))
            }
        }
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(segment.id, forKey: .id)
        switch segment {
        case .text(let t):
            try c.encode(SegmentType.text, forKey: .type)
            try c.encode(t.content, forKey: .text)

        case .reasoning(let t):
            try c.encode(SegmentType.reasoning, forKey: .type)
            try c.encode(t.content, forKey: .text)

        case .structure(let s):
            try c.encode(SegmentType.structure, forKey: .type)
            var nested = c.nestedContainer(keyedBy: StructureKeys.self, forKey: .structure)
            try nested.encode(s.source, forKey: .source)
            try nested.encode(s.content, forKey: .content)

        case .image(let img):
            try c.encode(SegmentType.image, forKey: .type)
            var nested = c.nestedContainer(keyedBy: ImageKeys.self, forKey: .image)
            switch img.source {
            case .base64(let data, let mediaType):
                try nested.encode("base64", forKey: .sourceType)
                try nested.encode(data, forKey: .data)
                try nested.encode(mediaType, forKey: .mediaType)
            case .url(let url):
                try nested.encode("url", forKey: .sourceType)
                try nested.encode(url, forKey: .url)
            }
        }
    }

    func toSegment() throws -> Transcript.Segment { segment }
}

// MARK: - Tool Definition

private struct ToolDefinitionCoding: Codable {

    private enum CodingKeys: String, CodingKey {
        case type, function
    }

    private enum FunctionKeys: String, CodingKey {
        case name, description, parameters
    }

    let definition: Transcript.ToolDefinition

    init(_ definition: Transcript.ToolDefinition) {
        self.definition = definition
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let nested = try c.nestedContainer(keyedBy: FunctionKeys.self, forKey: .function)
        let name = try nested.decode(String.self, forKey: .name)
        let description = try nested.decode(String.self, forKey: .description)
        let parameters = try nested.decode(GenerationSchema.self, forKey: .parameters)
        definition = Transcript.ToolDefinition(name: name, description: description, parameters: parameters)
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode("function", forKey: .type)
        var nested = c.nestedContainer(keyedBy: FunctionKeys.self, forKey: .function)
        try nested.encode(definition.name, forKey: .name)
        try nested.encode(definition.description, forKey: .description)
        try nested.encode(definition.parameters, forKey: .parameters)
    }

    func toToolDefinition() -> Transcript.ToolDefinition { definition }
}

// MARK: - Tool Call

private struct ToolCallCoding: Codable {

    private enum CodingKeys: String, CodingKey {
        case id, name, arguments
    }

    let call: Transcript.ToolCall

    init(_ call: Transcript.ToolCall) throws {
        self.call = call
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = try c.decode(String.self, forKey: .id)
        let name = try c.decode(String.self, forKey: .name)
        let argumentsJSON = try c.decode(String.self, forKey: .arguments)
        let arguments = try GeneratedContent(json: argumentsJSON)
        call = Transcript.ToolCall(id: id, toolName: name, arguments: arguments)
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(call.id, forKey: .id)
        try c.encode(call.toolName, forKey: .name)
        // Encode arguments as JSON string
        let data = try JSONEncoder().encode(call.arguments)
        let jsonString = String(data: data, encoding: .utf8) ?? "{}"
        try c.encode(jsonString, forKey: .arguments)
    }

    func toToolCall() throws -> Transcript.ToolCall { call }
}

// MARK: - Generation Options

private struct GenerationOptionsCoding: Codable {

    private enum CodingKeys: String, CodingKey {
        case temperature, maximumResponseTokens
    }

    let temperature: Double?
    let maximumResponseTokens: Int?

    init(_ options: GenerationOptions) {
        temperature = options.temperature
        maximumResponseTokens = options.maximumResponseTokens
    }

    func toGenerationOptions() throws -> GenerationOptions {
        GenerationOptions(temperature: temperature, maximumResponseTokens: maximumResponseTokens)
    }
}

// MARK: - Response Format

private struct ResponseFormatCoding: Codable {

    private enum CodingKeys: String, CodingKey {
        case name, type, schema
    }

    let name: String
    let type: String?
    let schema: GenerationSchema?

    init(_ format: Transcript.ResponseFormat) {
        name = format.name
        type = format.type
        schema = format.schema
    }

    func toResponseFormat() throws -> Transcript.ResponseFormat {
        if let schema {
            var fmt = Transcript.ResponseFormat(schema: schema)
            fmt.name = name
            if let t = type { fmt.type = t }
            return fmt
        }
        var fmt = Transcript.ResponseFormat(schema: GenerationSchema(type: String.self, description: nil, properties: []))
        fmt.name = name
        fmt.type = type
        return fmt
    }
}
