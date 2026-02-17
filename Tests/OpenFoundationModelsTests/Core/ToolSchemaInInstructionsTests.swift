import Foundation
import Testing
@testable import OpenFoundationModels
import OpenFoundationModelsMacros

@Suite("Tool Schema in Instructions Tests")
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

        var includesSchemaInInstructions: Bool {
            return false
        }

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

    // MARK: - Helper

    private func extractInstructionsContent(from model: MockLanguageModel) throws -> String {
        let transcript = try #require(model.capturedTranscript)

        let instructionsEntry = transcript.entries.first { entry in
            if case .instructions = entry { return true }
            return false
        }

        let entry = try #require(instructionsEntry)

        guard case .instructions(let data) = entry,
              case .text(let text) = data.segments.first else {
            Issue.record("Expected text segment in instructions")
            return ""
        }

        return text.content
    }

    // MARK: - Tests

    @Test("Tool schema is included in instructions when includesSchemaInInstructions is true")
    func toolSchemaIncludedInInstructions() async throws {
        let model = MockLanguageModel()

        let session = LanguageModelSession(
            model: model,
            tools: [WeatherTool()],
            instructions: "You are a helpful assistant."
        )

        _ = try await session.respond(to: "What's the weather?")

        let content = try extractInstructionsContent(from: model)

        // Base text present
        #expect(content.contains("You are a helpful assistant."))

        // Preamble declares tool access
        #expect(content.contains("In this environment you have access to a set of tools"))

        // Markdown header with tool name
        #expect(content.contains("## Weather"))

        // Description present
        #expect(content.contains("Get weather information for a city"))

        // JSON schema in code block
        #expect(content.contains("```json"))
        #expect(content.contains("\"city\""))
        #expect(content.contains("\"units\""))
    }

    @Test("Tool schema is not included when includesSchemaInInstructions is false")
    func toolSchemaNotIncludedWhenFlagIsFalse() async throws {
        let model = MockLanguageModel()

        let session = LanguageModelSession(
            model: model,
            tools: [CalculatorTool()],
            instructions: "You are a helpful assistant."
        )

        _ = try await session.respond(to: "Calculate 2+2")

        let content = try extractInstructionsContent(from: model)

        // Tool listed with markdown header
        #expect(content.contains("## Calculator"))
        #expect(content.contains("Perform mathematical calculations"))

        // Schema NOT included
        #expect(!content.contains("```json"))
        #expect(!content.contains("\"expression\""))
    }

    @Test("Multiple tools are correctly formatted in instructions")
    func multipleToolsInInstructions() async throws {
        let model = MockLanguageModel()

        let session = LanguageModelSession(
            model: model,
            tools: [WeatherTool(), CalculatorTool()],
            instructions: "You are a helpful assistant."
        )

        _ = try await session.respond(to: "Test")

        let content = try extractInstructionsContent(from: model)

        // Both tools listed with markdown headers
        #expect(content.contains("## Weather"))
        #expect(content.contains("## Calculator"))

        // Weather has schema
        #expect(content.contains("\"city\""))

        // Calculator does not have schema
        #expect(!content.contains("\"expression\""))
    }

    @Test("No tools section when no tools are provided")
    func noToolsSectionWhenNoTools() async throws {
        let model = MockLanguageModel()

        let session = LanguageModelSession(
            model: model,
            tools: [],
            instructions: "You are a helpful assistant."
        )

        _ = try await session.respond(to: "Test")

        let content = try extractInstructionsContent(from: model)

        // Only base text
        #expect(content == "You are a helpful assistant.")

        // No tool preamble
        #expect(!content.contains("In this environment you have access to a set of tools"))
    }
}
