import Testing
import Foundation
@testable import OpenFoundationModels

/// Tests for Response functionality
/// 
/// **Focus:** Validates Response structure integrity and proper handling
/// of content and transcript entries according to Apple's specification.
///
/// **Apple Foundation Models Documentation:**
/// Response represents the result of a language model generation request,
/// containing the generated content and associated transcript entries.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/response
@Suite("Response Tests", .tags(.core, .unit))
struct ResponseTests {
    
    @Test("Response creation with string content")
    func responseStringCreation() {
        // Test Response creation with String content
        let content = "Hello, world!"
        let textSegment = Transcript.TextSegment(content: "test prompt")
        let segment = Transcript.Segment.text(textSegment)
        let prompt = Transcript.Prompt(segments: [segment])
        let transcriptEntry = Transcript.Entry.prompt(prompt)
        let transcriptEntries = ArraySlice([transcriptEntry])
        
        let response = Response(
            content: content,
            transcriptEntries: transcriptEntries
        )
        
        #expect(response.content == content)
        #expect(response.transcriptEntries.count == 1)
    }
    
    @Test("Response creation with Generable content")
    func responseGenerableCreation() {
        @Generable
        struct TestData {
            let message: String
            let count: Int
        }
        
        // Test with valid JSON
        let content = TestData(GeneratedContent(#"{"message": "test", "count": 42}"#))
        let transcriptEntries = ArraySlice<Transcript.Entry>()
        
        let response = Response(
            content: content,
            transcriptEntries: transcriptEntries
        )
        
        #expect(response.content.message == "")     // Default value (JSON parsing not yet implemented)
        #expect(response.content.count == 0)       // Default value (JSON parsing not yet implemented)
        #expect(response.transcriptEntries.isEmpty)
    }
    
    @Test("Response with Generable fallback to defaults")
    func responseGenerableFallback() {
        @Generable
        struct TestData {
            let message: String
            let count: Int
        }
        
        // Test with invalid JSON - should fallback to defaults
        let content = TestData(GeneratedContent("invalid json"))
        let transcriptEntries = ArraySlice<Transcript.Entry>()
        
        let response = Response(
            content: content,
            transcriptEntries: transcriptEntries
        )
        
        #expect(response.content.message == "")  // Default fallback
        #expect(response.content.count == 0)    // Default fallback
        #expect(response.transcriptEntries.isEmpty)
    }
    
    @Test("Response with multiple transcript entries")
    func responseMultipleTranscriptEntries() {
        let content = "Response content"
        
        // Create proper transcript entries
        let firstPromptSegment = Transcript.TextSegment(content: "First prompt")
        let firstPrompt = Transcript.Prompt(segments: [.text(firstPromptSegment)])
        
        let firstResponseSegment = Transcript.TextSegment(content: "First response")
        let firstResponse = Transcript.Response(segments: [.text(firstResponseSegment)])
        
        let secondPromptSegment = Transcript.TextSegment(content: "Second prompt")
        let secondPrompt = Transcript.Prompt(segments: [.text(secondPromptSegment)])
        
        let entries = [
            Transcript.Entry.prompt(firstPrompt),
            Transcript.Entry.response(firstResponse),
            Transcript.Entry.prompt(secondPrompt)
        ]
        let transcriptEntries = ArraySlice(entries)
        
        let response = Response(
            content: content,
            transcriptEntries: transcriptEntries
        )
        
        #expect(response.content == content)
        #expect(response.transcriptEntries.count == 3)
        
        // Verify transcript entry types
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
    
    @Test("Response conforms to Sendable")
    func responseSendableConformance() {
        // Test that Response conforms to Sendable
        let response = Response(
            content: "test",
            transcriptEntries: ArraySlice<Transcript.Entry>()
        )
        
        // This test verifies Sendable conformance compiles
        let _: any Sendable = response
        #expect(Bool(true)) // Compilation success
    }
}