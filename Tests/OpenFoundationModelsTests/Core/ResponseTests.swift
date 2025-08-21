import Testing
import Foundation
@testable import OpenFoundationModels



@Generable
struct TestResponseData {
    let message: String
    let count: Int
}

@Suite("Response Tests", .tags(.core, .unit))
struct ResponseTests {
    
    @Test("Response creation with string content")
    func responseStringCreation() {
        let content = "Hello, world!"
        let textSegment = Transcript.TextSegment(id: UUID().uuidString, content: "test prompt")
        let segment = Transcript.Segment.text(textSegment)
        let prompt = Transcript.Prompt(
            id: UUID().uuidString,
            segments: [segment],
            options: .default,
            responseFormat: nil
        )
        let transcriptEntry = Transcript.Entry.prompt(prompt)
        let transcriptEntries = ArraySlice([transcriptEntry])
        
        let response = Response(
            content: content,
            rawContent: GeneratedContent(content),
            transcriptEntries: transcriptEntries
        )
        
        #expect(response.content == content)
        #expect(response.transcriptEntries.count == 1)
    }
    
    @Test("Response creation with Generable content")
    func responseGenerableCreation() throws {
        let content = try TestResponseData(GeneratedContent(json: #"{"message": "test", "count": 42}"#))
        let transcriptEntries = ArraySlice<Transcript.Entry>()
        
        let response = Response(
            content: content,
            rawContent: content.generatedContent,
            transcriptEntries: transcriptEntries
        )
        
        #expect(response.content.message == "test")   // Parsed from JSON
        #expect(response.content.count == 42)      // Parsed from JSON
        #expect(response.transcriptEntries.isEmpty)
    }
    
    @Test("Response with Generable fallback to defaults")
    func responseGenerableFallback() throws {
        let content = try TestResponseData(GeneratedContent(json: "{}"))
        let transcriptEntries = ArraySlice<Transcript.Entry>()
        
        let response = Response(
            content: content,
            rawContent: content.generatedContent,
            transcriptEntries: transcriptEntries
        )
        
        #expect(response.content.message == "")  // Default fallback
        #expect(response.content.count == 0)    // Default fallback
        #expect(response.transcriptEntries.isEmpty)
    }
    
    @Test("Response with multiple transcript entries")
    func responseMultipleTranscriptEntries() {
        let content = "Response content"
        
        let firstPromptSegment = Transcript.TextSegment(id: UUID().uuidString, content: "First prompt")
        let firstPrompt = Transcript.Prompt(
            id: UUID().uuidString,
            segments: [.text(firstPromptSegment)],
            options: .default,
            responseFormat: nil
        )
        
        let firstResponseSegment = Transcript.TextSegment(id: UUID().uuidString, content: "First response")
        let firstResponse = Transcript.Response(
            id: UUID().uuidString,
            assetIDs: [],
            segments: [.text(firstResponseSegment)]
        )
        
        let secondPromptSegment = Transcript.TextSegment(id: UUID().uuidString, content: "Second prompt")
        let secondPrompt = Transcript.Prompt(
            id: UUID().uuidString,
            segments: [.text(secondPromptSegment)],
            options: .default,
            responseFormat: nil
        )
        
        let entries = [
            Transcript.Entry.prompt(firstPrompt),
            Transcript.Entry.response(firstResponse),
            Transcript.Entry.prompt(secondPrompt)
        ]
        let transcriptEntries = ArraySlice(entries)
        
        let response = Response(
            content: content,
            rawContent: content.generatedContent,
            transcriptEntries: transcriptEntries
        )
        
        #expect(response.content == content)
        #expect(response.transcriptEntries.count == 3)
        
        if case .prompt(let prompt) = response.transcriptEntries.first {
            let firstSegment = prompt.segments.first
            if case .text(let textSegment) = firstSegment {
                #expect(textSegment.content == "First prompt")
            } else {
                #expect(Bool(false), "Expected text segment")
            }
        } else {
            #expect(Bool(false), "Expected prompt entry")
        }
    }
    
}
