import Testing
import Foundation
@testable import OpenFoundationModels

@Generable
struct TestTranscriptSearchResult {
    let query: String
    let results: [String]
}

@Generable
struct TestTranscriptUserProfile {
    let name: String
    let age: Int
    let isActive: Bool
}

@Suite("Transcript Codable Tests", .tags(.core, .unit))
struct TranscriptCodableTests {

    // MARK: - Apple JSON Format Compatibility

    @Test("Top-level JSON structure matches Apple format")
    func topLevelJSONStructure() throws {
        let transcript = Transcript(entries: [
            .instructions(Transcript.Instructions(
                id: "instr-1",
                segments: [.text(Transcript.TextSegment(id: "seg-1", content: "You are helpful."))],
                toolDefinitions: []
            ))
        ])

        let data = try JSONEncoder().encode(transcript)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["type"] as? String == "FoundationModels.Transcript")
        #expect(json["version"] as? Int == 1)
        #expect(json["transcript"] != nil)

        let inner = json["transcript"] as! [String: Any]
        let entries = inner["entries"] as! [[String: Any]]
        #expect(entries.count == 1)
    }

    @Test("Instructions entry role and contents")
    func instructionsEntryFormat() throws {
        let gc = GeneratedContent("structured value")
        let instructions = Transcript.Instructions(
            id: "instr-1",
            segments: [
                .text(Transcript.TextSegment(id: "seg-text", content: "Hello")),
                .structure(Transcript.StructuredSegment(id: "seg-struct", source: "MyType", content: gc))
            ],
            toolDefinitions: []
        )
        let transcript = Transcript(entries: [.instructions(instructions)])
        let json = try encodeToJSON(transcript)
        let entry = entries(json)[0]

        #expect(entry["role"] as? String == "instructions")
        #expect(entry["id"] as? String == "instr-1")

        let contents = entry["contents"] as! [[String: Any]]
        #expect(contents.count == 2)

        // text segment
        let textSeg = contents[0]
        #expect(textSeg["type"] as? String == "text")
        #expect(textSeg["text"] as? String == "Hello")

        // structure segment — nested {content, source}
        let structSeg = contents[1]
        #expect(structSeg["type"] as? String == "structure")
        let nested = structSeg["structure"] as! [String: Any]
        #expect(nested["source"] as? String == "MyType")
        #expect(nested["content"] as? String == "structured value")
    }

    @Test("Instructions with tool definitions uses {type:function, function:{...}} format")
    func instructionsToolDefinitionFormat() throws {
        let toolDef = Transcript.ToolDefinition(
            name: "webSearch",
            description: "Search the web",
            parameters: GenerationSchema(type: String.self, description: "query", properties: [])
        )
        let instructions = Transcript.Instructions(
            id: "instr-1",
            segments: [],
            toolDefinitions: [toolDef]
        )
        let transcript = Transcript(entries: [.instructions(instructions)])
        let json = try encodeToJSON(transcript)
        let entry = entries(json)[0]

        let tools = entry["tools"] as! [[String: Any]]
        #expect(tools.count == 1)
        #expect(tools[0]["type"] as? String == "function")

        let function = tools[0]["function"] as! [String: Any]
        #expect(function["name"] as? String == "webSearch")
        #expect(function["description"] as? String == "Search the web")
        #expect(function["parameters"] != nil)
    }

    @Test("Prompt entry uses role 'user' and has options")
    func promptEntryFormat() throws {
        let prompt = Transcript.Prompt(
            id: "prompt-1",
            segments: [.text(Transcript.TextSegment(id: "seg-1", content: "What is Swift?"))],
            options: GenerationOptions(),
            responseFormat: nil
        )
        let transcript = Transcript(entries: [.prompt(prompt)])
        let json = try encodeToJSON(transcript)
        let entry = entries(json)[0]

        #expect(entry["role"] as? String == "user")
        #expect(entry["id"] as? String == "prompt-1")
        #expect(entry["options"] != nil)
        #expect(entry["toolCalls"] == nil)
    }

    @Test("ToolCalls entry uses role 'response' with toolCalls array")
    func toolCallsEntryFormat() throws {
        let call = Transcript.ToolCall(
            id: "tc-1",
            toolName: "webSearch",
            arguments: try GeneratedContent(json: #"{"query": "Swift programming"}"#)
        )
        let toolCalls = Transcript.ToolCalls(id: "tcs-1", [call])
        let transcript = Transcript(entries: [.toolCalls(toolCalls)])
        let json = try encodeToJSON(transcript)
        let entry = entries(json)[0]

        #expect(entry["role"] as? String == "response")
        #expect(entry["contents"] == nil)

        let calls = entry["toolCalls"] as! [[String: Any]]
        #expect(calls.count == 1)
        #expect(calls[0]["id"] as? String == "tc-1")
        #expect(calls[0]["name"] as? String == "webSearch")   // "name" not "toolName"

        // Arguments must be a JSON string
        let argsString = calls[0]["arguments"] as! String
        #expect(argsString.contains("Swift programming"))
        let argsData = argsString.data(using: .utf8)!
        let argsJSON = try JSONSerialization.jsonObject(with: argsData) as! [String: Any]
        #expect(argsJSON["query"] as? String == "Swift programming")
    }

    @Test("ToolOutput entry uses role 'tool' with toolCallID")
    func toolOutputEntryFormat() throws {
        let toolOutput = Transcript.ToolOutput(
            id: "to-1",
            toolName: "webSearch",
            segments: [.text(Transcript.TextSegment(id: "seg-1", content: "Result"))]
        )
        let transcript = Transcript(entries: [.toolOutput(toolOutput)])
        let json = try encodeToJSON(transcript)
        let entry = entries(json)[0]

        #expect(entry["role"] as? String == "tool")
        #expect(entry["toolName"] as? String == "webSearch")
        #expect(entry["toolCallID"] != nil)
        #expect(entry["contents"] != nil)
    }

    @Test("Response entry uses role 'response' with assets")
    func responseEntryFormat() throws {
        let response = Transcript.Response(
            id: "resp-1",
            assetIDs: ["asset-abc"],
            segments: [.text(Transcript.TextSegment(id: "seg-1", content: "Answer"))]
        )
        let transcript = Transcript(entries: [.response(response)])
        let json = try encodeToJSON(transcript)
        let entry = entries(json)[0]

        #expect(entry["role"] as? String == "response")
        #expect(entry["assets"] as? [String] == ["asset-abc"])   // "assets" not "assetIDs"
        #expect(entry["toolCalls"] == nil)

        let contents = entry["contents"] as! [[String: Any]]
        #expect(contents.count == 1)
    }

    @Test("Reasoning segment round-trips through transcript codable")
    func reasoningSegmentRoundTrip() throws {
        let transcript = Transcript(entries: [
            .response(
                Transcript.Response(
                    id: "resp-1",
                    assetIDs: [],
                    segments: [
                        .reasoning(.init(id: "reason-1", content: "hidden chain")),
                        .text(.init(id: "text-1", content: "Visible answer")),
                    ]
                )
            )
        ])

        let decoded = try roundTrip(transcript)
        guard case .response(let response) = decoded.entries[0] else {
            Issue.record("Expected response entry")
            return
        }

        guard case .reasoning(let reasoning) = response.segments[0] else {
            Issue.record("Expected reasoning segment")
            return
        }

        #expect(reasoning.content == "hidden chain")
    }

    // MARK: - Round-trip Tests

    @Test("Instructions entry round-trip")
    func instructionsEntryRoundTrip() throws {
        let toolDef = Transcript.ToolDefinition(
            name: "testTool",
            description: "A test tool",
            parameters: TestTranscriptSearchResult.generationSchema
        )
        let instructions = Transcript.Instructions(
            id: "inst1",
            segments: [
                .text(Transcript.TextSegment(id: "seg1", content: "System instructions")),
                .structure(Transcript.StructuredSegment(
                    id: "seg2", source: "test",
                    content: GeneratedContent("structured content")
                ))
            ],
            toolDefinitions: [toolDef]
        )
        let transcript = Transcript(entries: [.instructions(instructions)])
        let decoded = try roundTrip(transcript)

        guard case .instructions(let inst) = decoded.entries[0] else {
            #expect(Bool(false), "Expected instructions entry"); return
        }
        #expect(inst.id == "inst1")
        #expect(inst.segments.count == 2)
        #expect(inst.toolDefinitions.count == 1)
        #expect(inst.toolDefinitions[0].name == "testTool")
    }

    @Test("Prompt entry with ResponseFormat round-trip")
    func promptWithResponseFormatRoundTrip() throws {
        let responseFormat = Transcript.ResponseFormat(schema: TestTranscriptUserProfile.generationSchema)
        let prompt = Transcript.Prompt(
            id: "prompt1",
            segments: [.text(Transcript.TextSegment(id: "seg1", content: "Generate a user profile"))],
            options: GenerationOptions(),
            responseFormat: responseFormat
        )
        let decoded = try roundTrip(Transcript(entries: [.prompt(prompt)]))

        guard case .prompt(let p) = decoded.entries[0] else {
            #expect(Bool(false), "Expected prompt entry"); return
        }
        #expect(p.id == "prompt1")
        #expect(p.responseFormat != nil)
        #expect(p.responseFormat?.name == "TestTranscriptUserProfile")
    }

    @Test("Prompt with temperature round-trip")
    func promptTemperatureRoundTrip() throws {
        let prompt = Transcript.Prompt(
            id: "p1",
            segments: [.text(Transcript.TextSegment(id: "s1", content: "Test"))],
            options: GenerationOptions(temperature: 0.7, maximumResponseTokens: 200),
            responseFormat: nil
        )
        let decoded = try roundTrip(Transcript(entries: [.prompt(prompt)]))

        guard case .prompt(let p) = decoded.entries[0] else {
            #expect(Bool(false)); return
        }
        #expect(p.options.temperature == 0.7)
        #expect(p.options.maximumResponseTokens == 200)
    }

    @Test("ToolCalls entry round-trip")
    func toolCallsEntryRoundTrip() throws {
        let call1 = Transcript.ToolCall(
            id: "call1",
            toolName: "searchTool",
            arguments: try GeneratedContent(json: #"{"query": "swift"}"#)
        )
        let call2 = Transcript.ToolCall(
            id: "call2",
            toolName: "calculateTool",
            arguments: try GeneratedContent(json: #"{"x": 10, "y": 20}"#)
        )
        let toolCalls = Transcript.ToolCalls(id: "calls1", [call1, call2])
        let decoded = try roundTrip(Transcript(entries: [.toolCalls(toolCalls)]))

        guard case .toolCalls(let tc) = decoded.entries[0] else {
            #expect(Bool(false), "Expected toolCalls entry"); return
        }
        #expect(tc.id == "calls1")
        #expect(tc.calls.count == 2)
        #expect(tc.calls[0].toolName == "searchTool")
        #expect(tc.calls[1].toolName == "calculateTool")
    }

    @Test("ToolOutput entry round-trip")
    func toolOutputEntryRoundTrip() throws {
        let toolOutput = Transcript.ToolOutput(
            id: "output1",
            toolName: "searchTool",
            segments: [.text(Transcript.TextSegment(id: "seg1", content: "Search results"))]
        )
        let decoded = try roundTrip(Transcript(entries: [.toolOutput(toolOutput)]))

        guard case .toolOutput(let to) = decoded.entries[0] else {
            #expect(Bool(false), "Expected toolOutput entry"); return
        }
        #expect(to.id == "output1")
        #expect(to.toolName == "searchTool")
        #expect(to.segments.count == 1)
    }

    @Test("Response entry round-trip")
    func responseEntryRoundTrip() throws {
        let response = Transcript.Response(
            id: "resp1",
            assetIDs: ["asset1", "asset2"],
            segments: [
                .text(Transcript.TextSegment(id: "seg1", content: "Response text")),
                .structure(Transcript.StructuredSegment(
                    id: "seg2", source: "model",
                    content: try GeneratedContent(json: #"{"key": "value"}"#)
                ))
            ]
        )
        let decoded = try roundTrip(Transcript(entries: [.response(response)]))

        guard case .response(let r) = decoded.entries[0] else {
            #expect(Bool(false), "Expected response entry"); return
        }
        #expect(r.id == "resp1")
        #expect(r.assetIDs == ["asset1", "asset2"])
        #expect(r.segments.count == 2)
    }

    @Test("Empty transcript round-trip")
    func emptyTranscriptRoundTrip() throws {
        let decoded = try roundTrip(Transcript(entries: []))
        #expect(decoded.entries.isEmpty)
    }

    // MARK: - Full Conversation Round-trip

    @Test("Full conversation transcript round-trip")
    func fullConversationRoundTrip() throws {
        let entries: [Transcript.Entry] = [
            .instructions(Transcript.Instructions(
                id: "inst1",
                segments: [.text(Transcript.TextSegment(id: "s1", content: "System prompt"))],
                toolDefinitions: [
                    Transcript.ToolDefinition(
                        name: "search",
                        description: "Search tool",
                        parameters: TestTranscriptSearchResult.generationSchema
                    )
                ]
            )),
            .prompt(Transcript.Prompt(
                id: "p1",
                segments: [.text(Transcript.TextSegment(id: "s2", content: "User question"))],
                options: GenerationOptions(temperature: 0.5),
                responseFormat: nil
            )),
            .toolCalls(Transcript.ToolCalls(id: "tc1", [
                Transcript.ToolCall(
                    id: "c1",
                    toolName: "search",
                    arguments: try GeneratedContent(json: #"{"query": "test"}"#)
                )
            ])),
            .toolOutput(Transcript.ToolOutput(
                id: "to1",
                toolName: "search",
                segments: [.text(Transcript.TextSegment(id: "s3", content: "Tool result"))]
            )),
            .response(Transcript.Response(
                id: "r1",
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(id: "s4", content: "Model answer"))]
            ))
        ]

        let transcript = Transcript(entries: entries)
        let decoded = try roundTrip(transcript)

        #expect(decoded.entries.count == 5)

        guard case .instructions = decoded.entries[0] else { #expect(Bool(false)); return }
        guard case .prompt = decoded.entries[1] else { #expect(Bool(false)); return }
        guard case .toolCalls = decoded.entries[2] else { #expect(Bool(false)); return }
        guard case .toolOutput = decoded.entries[3] else { #expect(Bool(false)); return }
        guard case .response = decoded.entries[4] else { #expect(Bool(false)); return }
    }

    // MARK: - Helpers

    private func encodeToJSON(_ transcript: Transcript) throws -> [String: Any] {
        let data = try JSONEncoder().encode(transcript)
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    private func entries(_ json: [String: Any]) -> [[String: Any]] {
        let inner = json["transcript"] as! [String: Any]
        return inner["entries"] as! [[String: Any]]
    }

    private func roundTrip(_ transcript: Transcript) throws -> Transcript {
        let data = try JSONEncoder().encode(transcript)
        return try JSONDecoder().decode(Transcript.self, from: data)
    }
}
