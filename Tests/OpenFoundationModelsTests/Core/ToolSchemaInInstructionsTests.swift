import Foundation
import Testing
@testable import OpenFoundationModels

@Suite("Tools in Instructions Tests")
struct ToolSchemaInInstructionsTests {

    // MARK: - Test Tools

    struct WeatherTool: Tool {
        let name = "Weather"
        let description = "Get weather information for a city"

        @Generable
        struct Arguments {
            let city: String
            let units: String?
        }

        typealias Output = String

        func call(arguments: Arguments) async throws -> String {
            return "Weather in \(arguments.city): 22°C"
        }
    }

    struct CalculatorTool: Tool {
        let name = "Calculator"
        let description = "Perform mathematical calculations"

        @Generable
        struct Arguments {
            let expression: String
        }

        typealias Output = String

        func call(arguments: Arguments) async throws -> String {
            return "Result: 42"
        }
    }

    // MARK: - Mock Language Model

    final class MockLanguageModel: LanguageModel, @unchecked Sendable {
        var capturedTranscript: Transcript?

        var isAvailable: Bool { true }

        func supports(locale: Locale) -> Bool { true }

        func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
            capturedTranscript = transcript

            return .response(Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(
                    id: UUID().uuidString,
                    content: "Test response"
                ))]
            ))
        }

        func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
            capturedTranscript = transcript

            return AsyncThrowingStream { continuation in
                continuation.yield(.response(Transcript.Response(
                    id: UUID().uuidString,
                    assetIDs: [],
                    segments: [.text(Transcript.TextSegment(
                        id: UUID().uuidString,
                        content: "Test response"
                    ))]
                )))
                continuation.finish()
            }
        }
    }

    // MARK: - Helpers

    private func extractInstructionsEntry(from model: MockLanguageModel) throws -> Transcript.Instructions {
        let transcript = try #require(model.capturedTranscript)

        let instructionsEntry = transcript.entries.first { entry in
            if case .instructions = entry { return true }
            return false
        }

        let entry = try #require(instructionsEntry)

        guard case .instructions(let data) = entry else {
            Issue.record("Expected instructions entry")
            throw CancellationError()
        }
        return data
    }

    private func segmentsText(_ instructions: Transcript.Instructions) -> String {
        instructions.segments.compactMap { segment -> String? in
            if case .text(let text) = segment { return text.content }
            return nil
        }.joined(separator: "\n")
    }

    // MARK: - Tests

    @Test("Tool definitions are exposed via Instructions.toolDefinitions, not injected into segments")
    func toolsExposedAsStructuredToolDefinitions() async throws {
        let model = MockLanguageModel()

        let session = LanguageModelSession(
            model: model,
            tools: [WeatherTool()],
            instructions: "You are a helpful assistant."
        )

        _ = try await session.respond(to: "What's the weather?")

        let instructions = try extractInstructionsEntry(from: model)

        // Structured path: tool is available via toolDefinitions
        #expect(instructions.toolDefinitions.count == 1)
        #expect(instructions.toolDefinitions.first?.name == "Weather")

        // Segments only contain user-provided instructions — no tool text baked in
        let text = segmentsText(instructions)
        #expect(text == "You are a helpful assistant.")
        #expect(!text.contains("## Weather"))
        #expect(!text.contains("```json"))
        #expect(!text.contains("In this environment you have access to a set of tools"))
    }

    @Test("Multiple tools all appear in toolDefinitions without polluting segments")
    func multipleToolsInToolDefinitions() async throws {
        let model = MockLanguageModel()

        let session = LanguageModelSession(
            model: model,
            tools: [WeatherTool(), CalculatorTool()],
            instructions: "You are a helpful assistant."
        )

        _ = try await session.respond(to: "Test")

        let instructions = try extractInstructionsEntry(from: model)

        #expect(instructions.toolDefinitions.count == 2)
        let names = instructions.toolDefinitions.map(\.name)
        #expect(names.contains("Weather"))
        #expect(names.contains("Calculator"))

        let text = segmentsText(instructions)
        #expect(text == "You are a helpful assistant.")
    }

    @Test("No toolDefinitions when no tools are provided")
    func noToolDefinitionsWhenNoTools() async throws {
        let model = MockLanguageModel()

        let session = LanguageModelSession(
            model: model,
            tools: [],
            instructions: "You are a helpful assistant."
        )

        _ = try await session.respond(to: "Test")

        let instructions = try extractInstructionsEntry(from: model)

        #expect(instructions.toolDefinitions.isEmpty)
        #expect(segmentsText(instructions) == "You are a helpful assistant.")
    }
}
