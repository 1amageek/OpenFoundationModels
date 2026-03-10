import Foundation
import Testing
@testable import OpenFoundationModels

@Suite("streamResponse Method Tests")
struct StreamResponseTests {

    // MARK: - Mock Models

    /// A model that streams text chunks as separate response entries.
    final class TextChunkModel: LanguageModel, @unchecked Sendable {
        let chunks: [String]

        init(chunks: [String] = ["Hel", "lo", " World"]) {
            self.chunks = chunks
        }

        var isAvailable: Bool { true }
        func supports(locale: Locale) -> Bool { true }

        func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
            return .response(Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: chunks.joined()))]
            ))
        }

        func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
            let chunks = self.chunks
            return AsyncThrowingStream { continuation in
                for chunk in chunks {
                    continuation.yield(.response(Transcript.Response(
                        id: UUID().uuidString,
                        assetIDs: [],
                        segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: chunk))]
                    )))
                }
                continuation.finish()
            }
        }
    }

    /// A model that streams JSON chunks for structured content.
    final class JSONChunkModel: LanguageModel, @unchecked Sendable {
        let jsonChunks: [String]
        let fullJSON: String

        init(jsonChunks: [String] = [#"{"name":"Al"#, #"ice","age":30}"#]) {
            self.jsonChunks = jsonChunks
            self.fullJSON = jsonChunks.joined()
        }

        var isAvailable: Bool { true }
        func supports(locale: Locale) -> Bool { true }

        func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
            return .response(Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: fullJSON))]
            ))
        }

        func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
            let chunks = self.jsonChunks
            return AsyncThrowingStream { continuation in
                for chunk in chunks {
                    continuation.yield(.response(Transcript.Response(
                        id: UUID().uuidString,
                        assetIDs: [],
                        segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: chunk))]
                    )))
                }
                continuation.finish()
            }
        }
    }

    /// A model that emits a tool call followed by a final response.
    final class ToolCallStreamModel: LanguageModel, @unchecked Sendable {
        private var callCount = 0

        var isAvailable: Bool { true }
        func supports(locale: Locale) -> Bool { true }

        func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
            defer { callCount += 1 }
            if callCount == 0 {
                return .toolCalls(Transcript.ToolCalls(
                    id: UUID().uuidString,
                    [Transcript.ToolCall(
                        id: UUID().uuidString,
                        toolName: "EchoTool",
                        arguments: GeneratedContent(properties: ["text": "ping"])
                    )]
                ))
            }
            return .response(Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: "Done after tool"))]
            ))
        }

        func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
            defer { callCount += 1 }
            let isFirstCall = callCount == 0
            return AsyncThrowingStream { continuation in
                if isFirstCall {
                    continuation.yield(.toolCalls(Transcript.ToolCalls(
                        id: UUID().uuidString,
                        [Transcript.ToolCall(
                            id: UUID().uuidString,
                            toolName: "EchoTool",
                            arguments: GeneratedContent(properties: ["text": "ping"])
                        )]
                    )))
                } else {
                    continuation.yield(.response(Transcript.Response(
                        id: UUID().uuidString,
                        assetIDs: [],
                        segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: "Done after tool"))]
                    )))
                }
                continuation.finish()
            }
        }
    }

    /// A model that throws an error during streaming.
    final class ErrorStreamModel: LanguageModel, @unchecked Sendable {
        var isAvailable: Bool { true }
        func supports(locale: Locale) -> Bool { true }

        func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
            throw LanguageModelSession.GenerationError.rateLimited(
                LanguageModelSession.GenerationError.Context(debugDescription: "Rate limited")
            )
        }

        func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
            return AsyncThrowingStream { continuation in
                continuation.yield(.response(Transcript.Response(
                    id: UUID().uuidString,
                    assetIDs: [],
                    segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: "partial"))]
                )))
                continuation.finish(throwing: LanguageModelSession.GenerationError.rateLimited(
                    LanguageModelSession.GenerationError.Context(debugDescription: "Rate limited")
                ))
            }
        }
    }

    // MARK: - Mock Tool

    struct EchoTool: Tool {
        let description = "Echoes back the input text"

        @Generable
        struct Arguments {
            let text: String
        }

        typealias Output = String

        func call(arguments: Arguments) async throws -> String {
            return "echo: \(arguments.text)"
        }
    }

    // MARK: - Generable Types

    @Generable
    struct Person {
        let name: String
        let age: Int
    }

    // MARK: - streamResponse(to: String) Tests

    @Test("streamResponse(to: String) accumulates text chunks")
    func streamResponseToString() async throws {
        let model = TextChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(to: "Hello")
        var snapshots: [String] = []
        for try await snapshot in stream {
            snapshots.append(snapshot.content)
        }

        #expect(snapshots.count == 3)
        #expect(snapshots.last == "Hello World")
    }

    // MARK: - streamResponse(to: Prompt) Tests

    @Test("streamResponse(to: Prompt, options:) accumulates text chunks")
    func streamResponseToPrompt() async throws {
        let model = TextChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let prompt = Prompt("Hello")
        let stream = session.streamResponse(to: prompt)
        var snapshots: [String] = []
        for try await snapshot in stream {
            snapshots.append(snapshot.content)
        }

        #expect(snapshots.count == 3)
        #expect(snapshots.last == "Hello World")
    }

    // MARK: - streamResponse(@PromptBuilder) Tests

    @Test("streamResponse(options:prompt:) with PromptBuilder accumulates text chunks")
    func streamResponseWithPromptBuilder() async throws {
        let model = TextChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse { "Hello" }
        var snapshots: [String] = []
        for try await snapshot in stream {
            snapshots.append(snapshot.content)
        }

        #expect(snapshots.count == 3)
        #expect(snapshots.last == "Hello World")
    }

    // MARK: - streamResponse with schema Tests

    @Test("streamResponse(to: String, schema:) produces structured content")
    func streamResponseToStringSchema() async throws {
        let model = JSONChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(
            to: "Generate a person",
            schema: Person.generationSchema
        )
        var lastRaw: GeneratedContent?
        for try await snapshot in stream {
            lastRaw = snapshot.rawContent
        }

        let raw = try #require(lastRaw)
        let person = try Person(raw)
        #expect(person.name == "Alice")
        #expect(person.age == 30)
    }

    @Test("streamResponse(to: Prompt, schema:) produces structured content")
    func streamResponseToPromptSchema() async throws {
        let model = JSONChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let prompt = Prompt("Generate a person")
        let stream = session.streamResponse(
            to: prompt,
            schema: Person.generationSchema
        )
        var lastRaw: GeneratedContent?
        for try await snapshot in stream {
            lastRaw = snapshot.rawContent
        }

        let raw = try #require(lastRaw)
        let person = try Person(raw)
        #expect(person.name == "Alice")
        #expect(person.age == 30)
    }

    @Test("streamResponse(schema:prompt:) with PromptBuilder produces structured content")
    func streamResponseSchemaWithPromptBuilder() async throws {
        let model = JSONChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(
            schema: Person.generationSchema
        ) { "Generate a person" }
        var lastRaw: GeneratedContent?
        for try await snapshot in stream {
            lastRaw = snapshot.rawContent
        }

        let raw = try #require(lastRaw)
        let person = try Person(raw)
        #expect(person.name == "Alice")
        #expect(person.age == 30)
    }

    // MARK: - streamResponse with generating Tests

    @Test("streamResponse(to: String, generating:) produces typed content")
    func streamResponseToStringGenerating() async throws {
        let model = JSONChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream: LanguageModelSession.ResponseStream<Person> = session.streamResponse(
            to: "Generate a person",
            generating: Person.self
        )
        var lastRaw: GeneratedContent?
        for try await snapshot in stream {
            lastRaw = snapshot.rawContent
        }

        let raw = try #require(lastRaw)
        let person = try Person(raw)
        #expect(person.name == "Alice")
        #expect(person.age == 30)
    }

    @Test("streamResponse(to: Prompt, generating:) produces typed content")
    func streamResponseToPromptGenerating() async throws {
        let model = JSONChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let prompt = Prompt("Generate a person")
        let stream: LanguageModelSession.ResponseStream<Person> = session.streamResponse(
            to: prompt,
            generating: Person.self
        )
        var lastRaw: GeneratedContent?
        for try await snapshot in stream {
            lastRaw = snapshot.rawContent
        }

        let raw = try #require(lastRaw)
        let person = try Person(raw)
        #expect(person.name == "Alice")
        #expect(person.age == 30)
    }

    @Test("streamResponse(generating:prompt:) with PromptBuilder produces typed content")
    func streamResponseGeneratingWithPromptBuilder() async throws {
        let model = JSONChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream: LanguageModelSession.ResponseStream<Person> = session.streamResponse(
            generating: Person.self
        ) { "Generate a person" }
        var lastRaw: GeneratedContent?
        for try await snapshot in stream {
            lastRaw = snapshot.rawContent
        }

        let raw = try #require(lastRaw)
        let person = try Person(raw)
        #expect(person.name == "Alice")
        #expect(person.age == 30)
    }

    // MARK: - collect() Tests

    @Test("collect() on text stream returns final Response")
    func collectTextStream() async throws {
        let model = TextChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(to: "Hello")
        let response = try await stream.collect()

        #expect(response.content == "Hello World")
    }

    @Test("collect() on schema stream returns final Response")
    func collectSchemaStream() async throws {
        let model = JSONChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(
            to: "Generate",
            schema: Person.generationSchema
        )
        let response = try await stream.collect()

        let person = try Person(response.content)
        #expect(person.name == "Alice")
    }

    @Test("collect() on generating stream returns final typed Response")
    func collectGeneratingStream() async throws {
        let model = JSONChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream: LanguageModelSession.ResponseStream<Person> = session.streamResponse(
            to: "Generate",
            generating: Person.self
        )
        let response = try await stream.collect()

        #expect(response.content.name == "Alice")
        #expect(response.content.age == 30)
    }

    // MARK: - Transcript Persistence Tests

    @Test("streamResponse persists prompt and response in transcript")
    func streamResponsePersistsTranscript() async throws {
        let model = TextChunkModel(chunks: ["Hello"])
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(to: "Say hi")
        for try await _ in stream {}

        let entries = session.transcript.entries
        let hasPrompt = entries.contains { entry in
            if case .prompt = entry { return true }
            return false
        }
        let hasResponse = entries.contains { entry in
            if case .response = entry { return true }
            return false
        }

        #expect(hasPrompt)
        #expect(hasResponse)
    }

    @Test("streamResponse with schema persists structured response segment in transcript")
    func streamResponseSchemaPersistsStructuredSegment() async throws {
        let model = JSONChunkModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(
            to: "Generate",
            schema: Person.generationSchema
        )
        for try await _ in stream {}

        let lastEntry = try #require(session.transcript.entries.last)
        guard case .response(let response) = lastEntry else {
            Issue.record("Expected last entry to be a response")
            return
        }

        let hasStructured = response.segments.contains { segment in
            if case .structure = segment { return true }
            return false
        }
        #expect(hasStructured)
    }

    // MARK: - isResponding State Tests

    @Test("isResponding is false before and after streaming")
    func isRespondingStateBeforeAndAfter() async throws {
        let model = TextChunkModel(chunks: ["A"])
        let session = LanguageModelSession(model: model, instructions: "test")

        #expect(session.isResponding == false)

        let stream = session.streamResponse(to: "Hello")
        for try await _ in stream {}

        // Allow internal Task to complete
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        #expect(session.isResponding == false)
    }

    // MARK: - Tool Calling During Streaming Tests

    @Test("streamResponse handles tool calls during streaming")
    func streamResponseWithToolCalls() async throws {
        let model = ToolCallStreamModel()
        let echoTool = EchoTool()
        let session = LanguageModelSession(model: model, tools: [echoTool], instructions: "test")

        let stream = session.streamResponse(to: "Use the tool")
        var lastContent = ""
        for try await snapshot in stream {
            lastContent = snapshot.content
        }

        #expect(lastContent == "Done after tool")

        // Verify transcript includes tool call and output
        let hasToolCalls = session.transcript.entries.contains { entry in
            if case .toolCalls = entry { return true }
            return false
        }
        let hasToolOutput = session.transcript.entries.contains { entry in
            if case .toolOutput = entry { return true }
            return false
        }
        #expect(hasToolCalls)
        #expect(hasToolOutput)
    }

    // MARK: - Error Handling Tests

    @Test("streamResponse propagates errors from model stream")
    func streamResponsePropagatesErrors() async throws {
        let model = ErrorStreamModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(to: "Hello")

        await #expect(throws: LanguageModelSession.GenerationError.self) {
            for try await _ in stream {}
        }
    }

    // MARK: - includeSchemaInPrompt Tests

    @Test("streamResponse with includeSchemaInPrompt=false does not include schema in prompt")
    func streamResponseSchemaNotIncludedInPrompt() async throws {
        final class CapturingModel: LanguageModel, @unchecked Sendable {
            var capturedTranscript: Transcript?
            var isAvailable: Bool { true }
            func supports(locale: Locale) -> Bool { true }

            func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
                capturedTranscript = transcript
                return .response(Transcript.Response(
                    id: UUID().uuidString,
                    assetIDs: [],
                    segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: #"{"name":"X","age":1}"#))]
                ))
            }

            func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
                capturedTranscript = transcript
                return AsyncThrowingStream { continuation in
                    continuation.yield(.response(Transcript.Response(
                        id: UUID().uuidString,
                        assetIDs: [],
                        segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: #"{"name":"X","age":1}"#))]
                    )))
                    continuation.finish()
                }
            }
        }

        let model = CapturingModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(
            to: "Generate",
            schema: Person.generationSchema,
            includeSchemaInPrompt: false
        )
        for try await _ in stream {}

        let transcript = try #require(model.capturedTranscript)
        let promptEntry = transcript.entries.first { entry in
            if case .prompt = entry { return true }
            return false
        }
        guard case .prompt(let prompt) = promptEntry else {
            Issue.record("Expected prompt entry")
            return
        }
        #expect(prompt.responseFormat == nil)
    }

    @Test("streamResponse with includeSchemaInPrompt=true includes schema in prompt")
    func streamResponseSchemaIncludedInPrompt() async throws {
        final class CapturingModel: LanguageModel, @unchecked Sendable {
            var capturedTranscript: Transcript?
            var isAvailable: Bool { true }
            func supports(locale: Locale) -> Bool { true }

            func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
                capturedTranscript = transcript
                return .response(Transcript.Response(
                    id: UUID().uuidString,
                    assetIDs: [],
                    segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: #"{"name":"X","age":1}"#))]
                ))
            }

            func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
                capturedTranscript = transcript
                return AsyncThrowingStream { continuation in
                    continuation.yield(.response(Transcript.Response(
                        id: UUID().uuidString,
                        assetIDs: [],
                        segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: #"{"name":"X","age":1}"#))]
                    )))
                    continuation.finish()
                }
            }
        }

        let model = CapturingModel()
        let session = LanguageModelSession(model: model, instructions: "test")

        let stream = session.streamResponse(
            to: "Generate",
            schema: Person.generationSchema,
            includeSchemaInPrompt: true
        )
        for try await _ in stream {}

        let transcript = try #require(model.capturedTranscript)
        let promptEntry = transcript.entries.first { entry in
            if case .prompt = entry { return true }
            return false
        }
        guard case .prompt(let prompt) = promptEntry else {
            Issue.record("Expected prompt entry")
            return
        }
        #expect(prompt.responseFormat != nil)
    }
}
