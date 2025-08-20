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
    
    // MARK: - Basic Entry Tests
    
    @Test("Instructions entry round-trip")
    func instructionsEntryRoundTrip() throws {
        let textSegment = Transcript.TextSegment(id: "seg1", content: "System instructions")
        let structSegment = Transcript.StructuredSegment(
            id: "seg2",
            source: "test",
            content: GeneratedContent("structured content")
        )
        
        let toolDef = Transcript.ToolDefinition(
            name: "testTool",
            description: "A test tool",
            parameters: TestTranscriptSearchResult.generationSchema
        )
        
        let instructions = Transcript.Instructions(
            id: "inst1",
            segments: [.text(textSegment), .structure(structSegment)],
            toolDefinitions: [toolDef]
        )
        
        let entry = Transcript.Entry.instructions(instructions)
        let transcript = Transcript(entries: [entry])
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(transcript)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedTranscript = try decoder.decode(Transcript.self, from: jsonData)
        
        // Verify
        #expect(decodedTranscript.entries.count == 1)
        
        if case .instructions(let decodedInst) = decodedTranscript.entries[0] {
            #expect(decodedInst.id == "inst1")
            #expect(decodedInst.segments.count == 2)
            #expect(decodedInst.toolDefinitions.count == 1)
            #expect(decodedInst.toolDefinitions[0].name == "testTool")
        } else {
            #expect(Bool(false), "Expected instructions entry")
        }
    }
    
    @Test("Prompt entry with ResponseFormat round-trip")
    func promptWithResponseFormatRoundTrip() throws {
        // Test with schema-based ResponseFormat
        let schema = TestTranscriptUserProfile.generationSchema
        
        let responseFormat = Transcript.ResponseFormat(schema: schema)
        
        let prompt = Transcript.Prompt(
            id: "prompt1",
            segments: [.text(Transcript.TextSegment(id: "seg1", content: "Generate a user profile"))],
            options: GenerationOptions(),
            responseFormat: responseFormat
        )
        
        let entry = Transcript.Entry.prompt(prompt)
        let transcript = Transcript(entries: [entry])
        
        // Encode to JSON
        let jsonData = try JSONEncoder().encode(transcript)
        
        // Decode from JSON
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        
        // Verify
        #expect(decodedTranscript.entries.count == 1)
        
        if case .prompt(let decodedPrompt) = decodedTranscript.entries[0] {
            #expect(decodedPrompt.id == "prompt1")
            #expect(decodedPrompt.responseFormat != nil)
            #expect(decodedPrompt.responseFormat?.name == "schema-based")
            
            // Verify schema is preserved
            let decodedSchema = decodedPrompt.responseFormat?.schema
            #expect(decodedSchema != nil)
        } else {
            #expect(Bool(false), "Expected prompt entry")
        }
    }
    
    @Test("Prompt with Generable type ResponseFormat")
    func promptWithGenerableTypeResponseFormat() throws {
        // Test with type-based ResponseFormat
        let responseFormat = Transcript.ResponseFormat(type: TestTranscriptSearchResult.self)
        
        let prompt = Transcript.Prompt(
            id: "prompt2",
            segments: [.text(Transcript.TextSegment(id: "seg1", content: "Search for something"))],
            options: GenerationOptions(temperature: 0.7),
            responseFormat: responseFormat
        )
        
        let entry = Transcript.Entry.prompt(prompt)
        let transcript = Transcript(entries: [entry])
        
        // Encode to JSON
        let jsonData = try JSONEncoder().encode(transcript)
        
        // Decode from JSON
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        
        // Verify
        if case .prompt(let decodedPrompt) = decodedTranscript.entries[0] {
            #expect(decodedPrompt.responseFormat != nil)
            #expect(decodedPrompt.responseFormat?.name == String(describing: TestTranscriptSearchResult.self))
            #expect(decodedPrompt.responseFormat?.type == String(describing: TestTranscriptSearchResult.self))
            #expect(decodedPrompt.responseFormat?.schema != nil)
        } else {
            #expect(Bool(false), "Expected prompt entry")
        }
    }
    
    @Test("Response entry round-trip")
    func responseEntryRoundTrip() throws {
        let response = Transcript.Response(
            id: "resp1",
            assetIDs: ["asset1", "asset2"],
            segments: [
                .text(Transcript.TextSegment(id: "seg1", content: "Response text")),
                .structure(Transcript.StructuredSegment(
                    id: "seg2",
                    source: "model",
                    content: try GeneratedContent(json: #"{"key": "value"}"#)
                ))
            ]
        )
        
        let entry = Transcript.Entry.response(response)
        let transcript = Transcript(entries: [entry])
        
        // Encode and decode
        let jsonData = try JSONEncoder().encode(transcript)
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        
        // Verify
        if case .response(let decodedResp) = decodedTranscript.entries[0] {
            #expect(decodedResp.id == "resp1")
            #expect(decodedResp.assetIDs == ["asset1", "asset2"])
            #expect(decodedResp.segments.count == 2)
        } else {
            #expect(Bool(false), "Expected response entry")
        }
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
        let entry = Transcript.Entry.toolCalls(toolCalls)
        let transcript = Transcript(entries: [entry])
        
        // Encode and decode
        let jsonData = try JSONEncoder().encode(transcript)
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        
        // Verify
        if case .toolCalls(let decodedCalls) = decodedTranscript.entries[0] {
            #expect(decodedCalls.id == "calls1")
            #expect(decodedCalls.calls.count == 2)
            #expect(decodedCalls.calls[0].toolName == "searchTool")
            #expect(decodedCalls.calls[1].toolName == "calculateTool")
        } else {
            #expect(Bool(false), "Expected toolCalls entry")
        }
    }
    
    @Test("ToolOutput entry round-trip")
    func toolOutputEntryRoundTrip() throws {
        let toolOutput = Transcript.ToolOutput(
            id: "output1",
            toolName: "searchTool",
            segments: [
                .text(Transcript.TextSegment(id: "seg1", content: "Search results found"))
            ]
        )
        
        let entry = Transcript.Entry.toolOutput(toolOutput)
        let transcript = Transcript(entries: [entry])
        
        // Encode and decode
        let jsonData = try JSONEncoder().encode(transcript)
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        
        // Verify
        if case .toolOutput(let decodedOutput) = decodedTranscript.entries[0] {
            #expect(decodedOutput.id == "output1")
            #expect(decodedOutput.toolName == "searchTool")
            #expect(decodedOutput.segments.count == 1)
        } else {
            #expect(Bool(false), "Expected toolOutput entry")
        }
    }
    
    // MARK: - Complex Transcript Tests
    
    @Test("Complex transcript with multiple entries")
    func complexTranscriptRoundTrip() throws {
        // Build a complex transcript with all entry types
        let instructions = Transcript.Instructions(
            id: "inst1",
            segments: [.text(Transcript.TextSegment(id: "seg1", content: "System prompt"))],
            toolDefinitions: []
        )
        
        let prompt1 = Transcript.Prompt(
            id: "prompt1",
            segments: [.text(Transcript.TextSegment(id: "seg2", content: "User question"))],
            options: GenerationOptions(temperature: 0.5),
            responseFormat: nil
        )
        
        let response1 = Transcript.Response(
            id: "resp1",
            assetIDs: [],
            segments: [.text(Transcript.TextSegment(id: "seg3", content: "Model response"))]
        )
        
        let toolCall = Transcript.ToolCall(
            id: "call1",
            toolName: "tool1",
            arguments: GeneratedContent("args")
        )
        
        let toolCalls = Transcript.ToolCalls(id: "calls1", [toolCall])
        
        let toolOutput = Transcript.ToolOutput(
            id: "output1",
            toolName: "tool1",
            segments: [.text(Transcript.TextSegment(id: "seg4", content: "Tool result"))]
        )
        
        let prompt2 = Transcript.Prompt(
            id: "prompt2",
            segments: [.text(Transcript.TextSegment(id: "seg5", content: "Follow-up"))],
            options: GenerationOptions(),
            responseFormat: Transcript.ResponseFormat(type: TestTranscriptUserProfile.self)
        )
        
        let response2 = Transcript.Response(
            id: "resp2",
            assetIDs: ["asset1"],
            segments: [.structure(Transcript.StructuredSegment(
                id: "seg6",
                source: "model",
                content: try GeneratedContent(json: #"{"name": "John", "age": 30, "isActive": true}"#)
            ))]
        )
        
        let entries: [Transcript.Entry] = [
            .instructions(instructions),
            .prompt(prompt1),
            .response(response1),
            .toolCalls(toolCalls),
            .toolOutput(toolOutput),
            .prompt(prompt2),
            .response(response2)
        ]
        
        let transcript = Transcript(entries: entries)
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(transcript)
        
        // Decode from JSON
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        
        // Verify structure
        #expect(decodedTranscript.entries.count == 7)
        
        // Verify each entry type
        var hasInstructions = false
        var promptCount = 0
        var responseCount = 0
        var hasToolCalls = false
        var hasToolOutput = false
        
        for entry in decodedTranscript.entries {
            switch entry {
            case .instructions:
                hasInstructions = true
            case .prompt:
                promptCount += 1
            case .response:
                responseCount += 1
            case .toolCalls:
                hasToolCalls = true
            case .toolOutput:
                hasToolOutput = true
            }
        }
        
        #expect(hasInstructions)
        #expect(promptCount == 2)
        #expect(responseCount == 2)
        #expect(hasToolCalls)
        #expect(hasToolOutput)
        
        // Verify ResponseFormat preservation
        if case .prompt(let lastPrompt) = decodedTranscript.entries[5] {
            #expect(lastPrompt.responseFormat != nil)
            #expect(lastPrompt.responseFormat?.name == String(describing: TestTranscriptUserProfile.self))
        }
    }
    
    @Test("Empty transcript round-trip")
    func emptyTranscriptRoundTrip() throws {
        let transcript = Transcript(entries: [])
        
        let jsonData = try JSONEncoder().encode(transcript)
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        
        #expect(decodedTranscript.entries.isEmpty)
    }
    
    // MARK: - ResponseFormat Extraction Tests
    
    @Test("Extract ResponseFormat from serialized Transcript")
    func extractResponseFormatFromJSON() throws {
        // Create transcript with ResponseFormat
        let responseFormat = Transcript.ResponseFormat(type: TestTranscriptSearchResult.self)
        let prompt = Transcript.Prompt(
            id: "prompt1",
            segments: [.text(Transcript.TextSegment(id: "seg1", content: "Search"))],
            options: GenerationOptions(),
            responseFormat: responseFormat
        )
        
        let transcript = Transcript(entries: [.prompt(prompt)])
        
        // Serialize to JSON
        let jsonData = try JSONEncoder().encode(transcript)
        
        // Parse JSON to extract ResponseFormat
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        let entries = jsonObject?["entries"] as? [[String: Any]]
        let firstEntry = entries?.first
        let responseFormatData = firstEntry?["responseFormat"] as? [String: Any]
        
        #expect(responseFormatData != nil)
        #expect(responseFormatData?["name"] as? String == String(describing: TestTranscriptSearchResult.self))
        #expect(responseFormatData?["type"] as? String == String(describing: TestTranscriptSearchResult.self))
        #expect(responseFormatData?["schema"] != nil)
    }
    
    @Test("Multiple prompts with different ResponseFormats")
    func multiplePromptsWithResponseFormats() throws {
        let responseFormat1 = Transcript.ResponseFormat(type: TestTranscriptSearchResult.self)
        let prompt1 = Transcript.Prompt(
            id: "prompt1",
            segments: [.text(Transcript.TextSegment(id: "seg1", content: "Search"))],
            options: GenerationOptions(),
            responseFormat: responseFormat1
        )
        
        let schema = TestTranscriptUserProfile.generationSchema
        let responseFormat2 = Transcript.ResponseFormat(schema: schema)
        let prompt2 = Transcript.Prompt(
            id: "prompt2",
            segments: [.text(Transcript.TextSegment(id: "seg2", content: "Profile"))],
            options: GenerationOptions(),
            responseFormat: responseFormat2
        )
        
        let prompt3 = Transcript.Prompt(
            id: "prompt3",
            segments: [.text(Transcript.TextSegment(id: "seg3", content: "No format"))],
            options: GenerationOptions(),
            responseFormat: nil
        )
        
        let transcript = Transcript(entries: [
            .prompt(prompt1),
            .prompt(prompt2),
            .prompt(prompt3)
        ])
        
        // Encode and decode
        let jsonData = try JSONEncoder().encode(transcript)
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        
        // Verify each prompt's ResponseFormat
        #expect(decodedTranscript.entries.count == 3)
        
        if case .prompt(let p1) = decodedTranscript.entries[0] {
            #expect(p1.responseFormat?.name == String(describing: TestTranscriptSearchResult.self))
            #expect(p1.responseFormat?.type == String(describing: TestTranscriptSearchResult.self))
        }
        
        if case .prompt(let p2) = decodedTranscript.entries[1] {
            #expect(p2.responseFormat?.name == "schema-based")
            #expect(p2.responseFormat?.schema != nil)
        }
        
        if case .prompt(let p3) = decodedTranscript.entries[2] {
            #expect(p3.responseFormat == nil)
        }
    }
    
    // MARK: - GenerationOptions Tests
    
    @Test("GenerationOptions with different sampling modes")
    func generationOptionsRoundTrip() throws {
        // Test greedy sampling
        let options1 = GenerationOptions(
            sampling: .greedy,
            temperature: 0.0,
            maximumResponseTokens: 100
        )
        
        let prompt1 = Transcript.Prompt(
            id: "prompt1",
            segments: [.text(Transcript.TextSegment(id: "seg1", content: "Test"))],
            options: options1,
            responseFormat: nil
        )
        
        // Test random sampling with topK
        let options2 = GenerationOptions(
            sampling: .random(top: 50, seed: 42),
            temperature: 0.8,
            maximumResponseTokens: 200
        )
        
        let prompt2 = Transcript.Prompt(
            id: "prompt2",
            segments: [.text(Transcript.TextSegment(id: "seg2", content: "Test"))],
            options: options2,
            responseFormat: nil
        )
        
        // Test random sampling with topP
        let options3 = GenerationOptions(
            sampling: .random(probabilityThreshold: 0.95, seed: 123),
            temperature: 1.0,
            maximumResponseTokens: 300
        )
        
        let prompt3 = Transcript.Prompt(
            id: "prompt3",
            segments: [.text(Transcript.TextSegment(id: "seg3", content: "Test"))],
            options: options3,
            responseFormat: nil
        )
        
        let transcript = Transcript(entries: [
            .prompt(prompt1),
            .prompt(prompt2),
            .prompt(prompt3)
        ])
        
        // Encode and decode
        let jsonData = try JSONEncoder().encode(transcript)
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        
        // Verify options are preserved (at least temperature and max tokens)
        if case .prompt(let p1) = decodedTranscript.entries[0] {
            #expect(p1.options.temperature == 0.0)
            #expect(p1.options.maximumResponseTokens == 100)
        }
        
        if case .prompt(let p2) = decodedTranscript.entries[1] {
            #expect(p2.options.temperature == 0.8)
            #expect(p2.options.maximumResponseTokens == 200)
        }
        
        if case .prompt(let p3) = decodedTranscript.entries[2] {
            #expect(p3.options.temperature == 1.0)
            #expect(p3.options.maximumResponseTokens == 300)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Large transcript serialization performance")
    func largeTranscriptPerformance() throws {
        var entries: [Transcript.Entry] = []
        
        // Create a large transcript with many entries
        for i in 0..<100 {
            let prompt = Transcript.Prompt(
                id: "prompt\(i)",
                segments: [.text(Transcript.TextSegment(id: "seg\(i)", content: "Question \(i)"))],
                options: GenerationOptions(),
                responseFormat: i % 2 == 0 ? Transcript.ResponseFormat(type: TestTranscriptSearchResult.self) : nil
            )
            
            let response = Transcript.Response(
                id: "resp\(i)",
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(id: "rseg\(i)", content: "Answer \(i)"))]
            )
            
            entries.append(.prompt(prompt))
            entries.append(.response(response))
        }
        
        let transcript = Transcript(entries: entries)
        
        // Measure encoding time
        let startEncode = Date()
        let jsonData = try JSONEncoder().encode(transcript)
        let encodeTime = Date().timeIntervalSince(startEncode)
        
        // Measure decoding time
        let startDecode = Date()
        let decodedTranscript = try JSONDecoder().decode(Transcript.self, from: jsonData)
        let decodeTime = Date().timeIntervalSince(startDecode)
        
        // Verify
        #expect(decodedTranscript.entries.count == 200)
        #expect(encodeTime < 1.0) // Should encode in less than 1 second
        #expect(decodeTime < 1.0) // Should decode in less than 1 second
        
        print("Large transcript (200 entries) - Encode: \(encodeTime)s, Decode: \(decodeTime)s")
    }
}