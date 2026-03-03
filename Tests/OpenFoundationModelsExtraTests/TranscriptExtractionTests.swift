import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsExtra
import OpenFoundationModelsCore

@Suite("Transcript Extraction Tests")
struct TranscriptExtractionTests {

    // MARK: - extractText

    @Test("extractText: single text segment")
    func extractTextSingle() {
        let segments: [Transcript.Segment] = [.text(.init(content: "Hello"))]
        #expect(Transcript.extractText(from: segments) == "Hello")
    }

    @Test("extractText: multiple text segments joined with space")
    func extractTextMultiple() {
        let segments: [Transcript.Segment] = [
            .text(.init(content: "Hello")),
            .text(.init(content: "world")),
        ]
        #expect(Transcript.extractText(from: segments) == "Hello world")
    }

    @Test("extractText: image placeholder")
    func extractTextImage() {
        let source = Transcript.ImageSegment.ImageSource.url(URL(string: "https://example.com/img.png")!)
        let segments: [Transcript.Segment] = [
            .text(.init(content: "See:")),
            .image(.init(source: source)),
        ]
        #expect(Transcript.extractText(from: segments) == "See: [Image #1]")
    }

    @Test("extractText: multiple images increment counter")
    func extractTextMultipleImages() {
        let source = Transcript.ImageSegment.ImageSource.url(URL(string: "https://example.com/img.png")!)
        let segments: [Transcript.Segment] = [
            .image(.init(source: source)),
            .image(.init(source: source)),
        ]
        let result = Transcript.extractText(from: segments)
        #expect(result == "[Image #1] [Image #2]")
    }

    @Test("extractText: empty segments")
    func extractTextEmpty() {
        #expect(Transcript.extractText(from: []) == "")
    }

    // MARK: - extractOptions

    @Test("extractOptions: returns options from latest prompt")
    func extractOptions() {
        let options = GenerationOptions(temperature: 0.5)
        let prompt = Transcript.Prompt(segments: [.text(.init(content: "hi"))], options: options)
        let transcript = Transcript(entries: [.prompt(prompt)])
        let extracted = Transcript.extractOptions(from: transcript)
        #expect(extracted?.temperature == 0.5)
    }

    @Test("extractOptions: returns nil when no prompt")
    func extractOptionsNil() {
        let instructions = Transcript.Instructions(segments: [], toolDefinitions: [])
        let transcript = Transcript(entries: [.instructions(instructions)])
        #expect(Transcript.extractOptions(from: transcript) == nil)
    }

    @Test("extractOptions: returns most recent prompt options")
    func extractOptionsMostRecent() {
        let p1 = Transcript.Prompt(segments: [], options: GenerationOptions(temperature: 0.1))
        let p2 = Transcript.Prompt(segments: [], options: GenerationOptions(temperature: 0.9))
        let transcript = Transcript(entries: [.prompt(p1), .prompt(p2)])
        #expect(Transcript.extractOptions(from: transcript)?.temperature == 0.9)
    }

    // MARK: - extractToolDefinitions

    @Test("extractToolDefinitions: returns tools from instructions")
    func extractToolDefinitions() {
        let schema = GenerationSchema(type: String.self, description: "arg", properties: [])
        let tool = Transcript.ToolDefinition(name: "myTool", description: "does stuff", parameters: schema)
        let instructions = Transcript.Instructions(segments: [], toolDefinitions: [tool])
        let transcript = Transcript(entries: [.instructions(instructions)])
        let extracted = Transcript.extractToolDefinitions(from: transcript)
        #expect(extracted?.count == 1)
        #expect(extracted?.first?.name == "myTool")
    }

    @Test("extractToolDefinitions: returns nil when no tools")
    func extractToolDefinitionsNil() {
        let instructions = Transcript.Instructions(segments: [], toolDefinitions: [])
        let transcript = Transcript(entries: [.instructions(instructions)])
        #expect(Transcript.extractToolDefinitions(from: transcript) == nil)
    }

    @Test("extractToolDefinitions: returns nil on empty transcript")
    func extractToolDefinitionsEmpty() {
        #expect(Transcript.extractToolDefinitions(from: Transcript()) == nil)
    }

    // MARK: - extractResponseSchema

    @Test("extractResponseSchema: returns schema from prompt responseFormat")
    func extractResponseSchema() {
        let schema = GenerationSchema(type: String.self, description: "resp", properties: [])
        let format = Transcript.ResponseFormat(schema: schema)
        let prompt = Transcript.Prompt(segments: [], responseFormat: format)
        let transcript = Transcript(entries: [.prompt(prompt)])
        #expect(Transcript.extractResponseSchema(from: transcript) != nil)
    }

    @Test("extractResponseSchema: returns nil when no responseFormat")
    func extractResponseSchemaNil() {
        let prompt = Transcript.Prompt(segments: [])
        let transcript = Transcript(entries: [.prompt(prompt)])
        #expect(Transcript.extractResponseSchema(from: transcript) == nil)
    }
}
