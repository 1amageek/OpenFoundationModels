import Foundation
import Testing
@testable import OpenFoundationModels

@Suite("Streaming Transcript Aggregation Tests")
struct StreamingTranscriptAggregationTests {

    final class ChunkedResponseModel: LanguageModel, @unchecked Sendable {
        var isAvailable: Bool { true }

        func supports(locale: Locale) -> Bool { true }

        func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
            return .response(
                Transcript.Response(
                    id: UUID().uuidString,
                    assetIDs: [],
                    segments: [
                        .text(Transcript.TextSegment(id: UUID().uuidString, content: "unused"))
                    ]
                )
            )
        }

        func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
            return AsyncThrowingStream { continuation in
                continuation.yield(
                    .response(
                        Transcript.Response(
                            id: UUID().uuidString,
                            assetIDs: [],
                            segments: [
                                .text(Transcript.TextSegment(id: UUID().uuidString, content: "Hel"))
                            ]
                        )
                    )
                )
                continuation.yield(
                    .response(
                        Transcript.Response(
                            id: UUID().uuidString,
                            assetIDs: [],
                            segments: [
                                .text(Transcript.TextSegment(id: UUID().uuidString, content: "lo"))
                            ]
                        )
                    )
                )
                continuation.finish()
            }
        }
    }

    @Generable
    struct StructuredPayload {
        let message: String
    }

    final class ChunkedJSONResponseModel: LanguageModel, @unchecked Sendable {
        var isAvailable: Bool { true }

        func supports(locale: Locale) -> Bool { true }

        func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
            return .response(
                Transcript.Response(
                    id: UUID().uuidString,
                    assetIDs: [],
                    segments: [
                        .text(Transcript.TextSegment(id: UUID().uuidString, content: "{\"message\":\"hello\"}"))
                    ]
                )
            )
        }

        func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
            return AsyncThrowingStream { continuation in
                continuation.yield(
                    .response(
                        Transcript.Response(
                            id: UUID().uuidString,
                            assetIDs: [],
                            segments: [
                                .text(Transcript.TextSegment(id: UUID().uuidString, content: "{\"message\":\"hel"))
                            ]
                        )
                    )
                )
                continuation.yield(
                    .response(
                        Transcript.Response(
                            id: UUID().uuidString,
                            assetIDs: [],
                            segments: [
                                .text(Transcript.TextSegment(id: UUID().uuidString, content: "lo\"}"))
                            ]
                        )
                    )
                )
                continuation.finish()
            }
        }
    }

    @Test("streamResponse persists full accumulated response in transcript")
    func streamResponsePersistsFullAccumulation() async throws {
        let model = ChunkedResponseModel()
        let session = LanguageModelSession(model: model, instructions: "You are a helper.")

        let stream = session.streamResponse(to: "Say hello")
        var finalSnapshot = ""
        for try await snapshot in stream {
            finalSnapshot = snapshot.content
        }

        #expect(finalSnapshot == "Hello")

        let lastEntry = try #require(session.transcript.entries.last)
        guard case .response(let response) = lastEntry else {
            Issue.record("Expected last transcript entry to be response")
            return
        }

        let persistedText = response.segments.reduce(into: "") { partial, segment in
            if case .text(let textSegment) = segment {
                partial += textSegment.content
            }
        }

        #expect(persistedText == "Hello")
    }

    @Test("streamResponse(schema:) persists aggregated structured content in transcript")
    func streamResponseSchemaPersistsAggregatedStructuredContent() async throws {
        let model = ChunkedJSONResponseModel()
        let session = LanguageModelSession(model: model, instructions: "You are a helper.")

        let stream = session.streamResponse(
            to: "Return JSON",
            schema: StructuredPayload.generationSchema
        )

        var finalRawContent: GeneratedContent?
        for try await snapshot in stream {
            finalRawContent = snapshot.rawContent
        }

        let rawContent = try #require(finalRawContent)
        let payload = try StructuredPayload(rawContent)
        #expect(payload.message == "hello")

        let lastEntry = try #require(session.transcript.entries.last)
        guard case .response(let response) = lastEntry else {
            Issue.record("Expected last transcript entry to be response")
            return
        }

        let structuredSegment = response.segments.first { segment in
            if case .structure = segment { return true }
            return false
        }
        #expect(structuredSegment != nil)
    }

    @Test("streamResponse(generating:) persists aggregated structured content in transcript")
    func streamResponseGeneratingPersistsAggregatedStructuredContent() async throws {
        let model = ChunkedJSONResponseModel()
        let session = LanguageModelSession(model: model, instructions: "You are a helper.")

        let stream = session.streamResponse(
            to: "Return payload",
            generating: StructuredPayload.self
        )

        var finalRawContent: GeneratedContent?
        for try await snapshot in stream {
            finalRawContent = snapshot.rawContent
        }

        let rawContent = try #require(finalRawContent)
        let payload = try StructuredPayload(rawContent)
        #expect(payload.message == "hello")

        let lastEntry = try #require(session.transcript.entries.last)
        guard case .response(let response) = lastEntry else {
            Issue.record("Expected last transcript entry to be response")
            return
        }

        let structuredSegment = response.segments.first { segment in
            if case .structure = segment { return true }
            return false
        }
        #expect(structuredSegment != nil)
    }
}
