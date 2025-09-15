import Foundation
import Testing
@testable import OpenFoundationModels
import OpenFoundationModelsMacros

@Suite("Tool Execution Loop Tests")
struct ToolExecutionLoopTests {
    
    // MARK: - Mock Tools
    
    struct WeatherTool: Tool {
        let description = "Get weather information for a city"
        
        @Generable
        struct Arguments {
            let city: String
        }
        
        typealias Output = String
        
        func call(arguments: Arguments) async throws -> String {
            return "Weather in \(arguments.city): 22°C, sunny"
        }
    }
    
    struct CalculatorTool: Tool {
        let description = "Perform mathematical calculations"
        
        @Generable
        struct Arguments {
            let expression: String
        }
        
        typealias Output = String
        
        func call(arguments: Arguments) async throws -> String {
            if arguments.expression == "2+2" {
                return "4"
            }
            return "42"
        }
    }
    
    struct FailingTool: Tool {
        let description = "A tool that always fails"
        
        @Generable
        struct Arguments {
            // Empty arguments for failing tool
        }
        
        typealias Output = String
        
        func call(arguments: Arguments) async throws -> String {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tool failed"])
        }
    }
    
    // MARK: - Mock Language Model
    
    final class MockLanguageModel: LanguageModel, @unchecked Sendable {
        private let responses: [Transcript.Entry]
        private var currentIndex = 0
        
        init(responses: [Transcript.Entry]) {
            self.responses = responses
        }
        
        var isAvailable: Bool { true }
        
        func supports(locale: Locale) -> Bool { true }
        
        func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry {
            defer { currentIndex += 1 }
            
            if currentIndex < responses.count {
                return responses[currentIndex]
            }
            
            // Default final response if we run out of scripted responses
            return .response(Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(
                    id: UUID().uuidString,
                    content: "Final response"
                ))]
            ))
        }
        
        func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error> {
            return AsyncThrowingStream { continuation in
                Task {
                    for response in responses[currentIndex...] {
                        continuation.yield(response)
                    }
                    continuation.finish()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createToolCall(toolName: String, arguments: String) -> Transcript.ToolCall {
        // For @Generable structs with properties, we need dictionary format
        let argsContent: GeneratedContent
        if toolName == "WeatherTool" {
            argsContent = GeneratedContent(properties: ["city": arguments])
        } else if toolName == "CalculatorTool" {
            argsContent = GeneratedContent(properties: ["expression": arguments])
        } else if toolName == "FailingTool" {
            argsContent = GeneratedContent(properties: [:])
        } else {
            argsContent = GeneratedContent(arguments)
        }
        
        return Transcript.ToolCall(
            id: UUID().uuidString,
            toolName: toolName,
            arguments: argsContent
        )
    }
    
    private func createToolCallsEntry(calls: [Transcript.ToolCall]) -> Transcript.Entry {
        return .toolCalls(Transcript.ToolCalls(
            id: UUID().uuidString,
            calls
        ))
    }
    
    private func createResponseEntry(content: String) -> Transcript.Entry {
        return .response(Transcript.Response(
            id: UUID().uuidString,
            assetIDs: [],
            segments: [.text(Transcript.TextSegment(
                id: UUID().uuidString,
                content: content
            ))]
        ))
    }
    
    // MARK: - Basic Tool Execution Tests
    
    @Test("Basic tool execution loop")
    func basicToolExecutionLoop() async throws {
        let weatherCall = createToolCall(toolName: "WeatherTool", arguments: "Tokyo")
        let toolCallsEntry = createToolCallsEntry(calls: [weatherCall])
        let responseEntry = createResponseEntry(content: "The weather in Tokyo is 22°C and sunny!")
        
        let mockModel = MockLanguageModel(responses: [toolCallsEntry, responseEntry])
        let session = LanguageModelSession(
            model: mockModel,
            tools: [WeatherTool()],
            instructions: "You are a helpful assistant"
        )
        
        let response = try await session.respond(to: "What's the weather in Tokyo?")
        
        #expect(response.content == "The weather in Tokyo is 22°C and sunny!")
        
        // Verify transcript contains tool call and tool output
        let entries = session.transcript.entries
        #expect(entries.count >= 4) // prompt, toolCalls, toolOutput, response
        
        // Check for tool output entry
        let toolOutputExists = entries.contains { entry in
            if case .toolOutput(let output) = entry {
                return output.toolName == "WeatherTool"
            }
            return false
        }
        #expect(toolOutputExists)
    }
    
    @Test("Multiple tool execution steps")
    func multipleToolExecutionSteps() async throws {
        let weatherCall = createToolCall(toolName: "WeatherTool", arguments: "Tokyo")
        let calcCall = createToolCall(toolName: "CalculatorTool", arguments: "2+2")
        
        let firstToolCallsEntry = createToolCallsEntry(calls: [weatherCall])
        let secondToolCallsEntry = createToolCallsEntry(calls: [calcCall])
        let responseEntry = createResponseEntry(content: "Weather is good and 2+2=4!")
        
        let mockModel = MockLanguageModel(responses: [firstToolCallsEntry, secondToolCallsEntry, responseEntry])
        let session = LanguageModelSession(
            model: mockModel,
            tools: [WeatherTool(), CalculatorTool()],
            instructions: "You are a helpful assistant"
        )
        
        let response = try await session.respond(to: "Get weather and calculate 2+2")
        
        #expect(response.content == "Weather is good and 2+2=4!")
        
        // Verify multiple tool outputs in transcript
        let entries = session.transcript.entries
        let toolOutputs = entries.compactMap { entry -> Transcript.ToolOutput? in
            if case .toolOutput(let output) = entry {
                return output
            }
            return nil
        }
        
        #expect(toolOutputs.count == 2)
        #expect(toolOutputs.contains { $0.toolName == "WeatherTool" })
        #expect(toolOutputs.contains { $0.toolName == "CalculatorTool" })
    }
    
    @Test("Multiple tools in single call")
    func multipleToolsInSingleCall() async throws {
        let weatherCall = createToolCall(toolName: "WeatherTool", arguments: "Tokyo")
        let calcCall = createToolCall(toolName: "CalculatorTool", arguments: "2+2")
        
        let toolCallsEntry = createToolCallsEntry(calls: [weatherCall, calcCall])
        let responseEntry = createResponseEntry(content: "Both tasks completed!")
        
        let mockModel = MockLanguageModel(responses: [toolCallsEntry, responseEntry])
        let session = LanguageModelSession(
            model: mockModel,
            tools: [WeatherTool(), CalculatorTool()],
            instructions: "You are a helpful assistant"
        )
        
        let response = try await session.respond(to: "Do both tasks")
        
        #expect(response.content == "Both tasks completed!")
        
        // Verify both tools were executed
        let entries = session.transcript.entries
        let toolOutputs = entries.compactMap { entry -> Transcript.ToolOutput? in
            if case .toolOutput(let output) = entry {
                return output
            }
            return nil
        }
        
        #expect(toolOutputs.count == 2)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Tool not found error")
    func toolNotFoundError() async throws {
        let unknownCall = createToolCall(toolName: "UnknownTool", arguments: "test")
        let toolCallsEntry = createToolCallsEntry(calls: [unknownCall])
        
        let mockModel = MockLanguageModel(responses: [toolCallsEntry])
        let session = LanguageModelSession(
            model: mockModel,
            tools: [WeatherTool()], // UnknownTool is not included
            instructions: "You are a helpful assistant"
        )
        
        do {
            let _ = try await session.respond(to: "Use unknown tool")
            Issue.record("Expected error to be thrown")
        } catch let error as LanguageModelSession.GenerationError {
            if case .toolNotFound(let toolName, _) = error {
                #expect(toolName == "UnknownTool")
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("Tool execution failure error")
    func toolExecutionFailureError() async throws {
        let failingCall = createToolCall(toolName: "FailingTool", arguments: "test")
        let toolCallsEntry = createToolCallsEntry(calls: [failingCall])
        
        let mockModel = MockLanguageModel(responses: [toolCallsEntry])
        let session = LanguageModelSession(
            model: mockModel,
            tools: [FailingTool()],
            instructions: "You are a helpful assistant"
        )
        
        do {
            let _ = try await session.respond(to: "Use failing tool")
            Issue.record("Expected error to be thrown")
        } catch let error as LanguageModelSession.GenerationError {
            if case .toolExecutionFailed(let toolName, _, _) = error {
                #expect(toolName == "FailingTool")
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("Unexpected entry type error")
    func unexpectedEntryTypeError() async throws {
        let instructionsEntry = Transcript.Entry.instructions(
            Transcript.Instructions(
                id: UUID().uuidString,
                segments: [],
                toolDefinitions: []
            )
        )
        
        let mockModel = MockLanguageModel(responses: [instructionsEntry])
        let session = LanguageModelSession(
            model: mockModel,
            tools: [],
            instructions: "You are a helpful assistant"
        )
        
        do {
            let _ = try await session.respond(to: "Test prompt")
            Issue.record("Expected error to be thrown")
        } catch let error as LanguageModelSession.GenerationError {
            if case .unexpectedEntryType(_) = error {
                // Expected error
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Structured Generation Tests
    
    // Move WeatherResult outside of test function
    @Generable
    struct WeatherResult {
        let city: String
        let temperature: Int
        let condition: String
    }
    
    @Test("Tool execution with schema generation")
    func toolExecutionWithSchemaGeneration() async throws {
        let weatherCall = createToolCall(toolName: "WeatherTool", arguments: "Tokyo")
        let toolCallsEntry = createToolCallsEntry(calls: [weatherCall])
        
        // Create a structured response
        let responseEntry = Transcript.Entry.response(
            Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.structure(Transcript.StructuredSegment(
                    id: UUID().uuidString,
                    source: "model",
                    content: try GeneratedContent(json: #"{"city":"Tokyo","temperature":22,"condition":"sunny"}"#)
                ))]
            )
        )
        
        let mockModel = MockLanguageModel(responses: [toolCallsEntry, responseEntry])
        let session = LanguageModelSession(
            model: mockModel,
            tools: [WeatherTool()],
            instructions: "You are a helpful assistant"
        )
        
        let response = try await session.respond(
            to: "Get weather for Tokyo",
            generating: WeatherResult.self
        )
        
        #expect(response.content.city == "Tokyo")
        #expect(response.content.temperature == 22)
        #expect(response.content.condition == "sunny")
    }
    
    // MARK: - Concurrent Execution Tests
    
    @Test("Concurrent tool execution loops")
    func concurrentToolExecutionLoops() async throws {
        let weatherCall = createToolCall(toolName: "WeatherTool", arguments: "Tokyo")
        let toolCallsEntry = createToolCallsEntry(calls: [weatherCall])
        let responseEntry = createResponseEntry(content: "Weather retrieved!")
        
        let createSession = {
            let mockModel = MockLanguageModel(responses: [toolCallsEntry, responseEntry])
            return LanguageModelSession(
                model: mockModel,
                tools: [WeatherTool()],
                instructions: "You are a helpful assistant"
            )
        }
        
        let session1 = createSession()
        let session2 = createSession()
        let session3 = createSession()
        
        async let response1 = session1.respond(to: "Weather 1")
        async let response2 = session2.respond(to: "Weather 2")
        async let response3 = session3.respond(to: "Weather 3")
        
        let responses = try await [response1, response2, response3]
        
        #expect(responses.count == 3)
        #expect(responses.allSatisfy { $0.content == "Weather retrieved!" })
    }
    
    // MARK: - Integration Tests
    
    @Test("Tool execution preserves transcript order")
    func toolExecutionPreservesTranscriptOrder() async throws {
        let weatherCall = createToolCall(toolName: "WeatherTool", arguments: "Tokyo")
        let toolCallsEntry = createToolCallsEntry(calls: [weatherCall])
        let responseEntry = createResponseEntry(content: "Final response")
        
        let mockModel = MockLanguageModel(responses: [toolCallsEntry, responseEntry])
        let session = LanguageModelSession(
            model: mockModel,
            tools: [WeatherTool()],
            instructions: "You are a helpful assistant"
        )
        
        let _ = try await session.respond(to: "Test prompt")
        
        let entries = session.transcript.entries
        
        // Verify the order: instructions, prompt, toolCalls, toolOutput, response
        var index = 0
        
        // Skip instructions entry if present
        if case .instructions = entries[index] {
            index += 1
        }
        
        // Verify prompt
        if case .prompt = entries[index] {
            index += 1
        } else {
            Issue.record("Expected prompt entry at index \(index)")
        }
        
        // Verify toolCalls
        if case .toolCalls = entries[index] {
            index += 1
        } else {
            Issue.record("Expected toolCalls entry at index \(index)")
        }
        
        // Verify toolOutput
        if case .toolOutput = entries[index] {
            index += 1
        } else {
            Issue.record("Expected toolOutput entry at index \(index)")
        }
        
        // Verify response
        if case .response = entries[index] {
            // Success
        } else {
            Issue.record("Expected response entry at index \(index)")
        }
    }
    
    @Test("Tool execution with existing transcript")
    func toolExecutionWithExistingTranscript() async throws {
        // Create a transcript with existing entries
        let existingEntries = [
            Transcript.Entry.instructions(
                Transcript.Instructions(
                    id: UUID().uuidString,
                    segments: [.text(Transcript.TextSegment(
                        id: UUID().uuidString,
                        content: "You are a helpful assistant"
                    ))],
                    toolDefinitions: [Transcript.ToolDefinition(tool: WeatherTool())]
                )
            ),
            Transcript.Entry.prompt(
                Transcript.Prompt(
                    id: UUID().uuidString,
                    segments: [.text(Transcript.TextSegment(
                        id: UUID().uuidString,
                        content: "Previous prompt"
                    ))],
                    options: GenerationOptions()
                )
            ),
            createResponseEntry(content: "Previous response")
        ]
        
        let existingTranscript = Transcript(entries: existingEntries)
        
        let weatherCall = createToolCall(toolName: "WeatherTool", arguments: "Tokyo")
        let toolCallsEntry = createToolCallsEntry(calls: [weatherCall])
        let responseEntry = createResponseEntry(content: "New weather response")
        
        let mockModel = MockLanguageModel(responses: [toolCallsEntry, responseEntry])
        let session = LanguageModelSession(
            model: mockModel,
            tools: [WeatherTool()],
            transcript: existingTranscript
        )
        
        let response = try await session.respond(to: "New weather request")
        
        #expect(response.content == "New weather response")
        
        // Verify transcript contains both old and new entries
        let finalEntries = session.transcript.entries
        #expect(finalEntries.count >= 6) // 3 existing + new prompt + toolCalls + toolOutput + response
        
        // First 3 entries should be the existing ones
        #expect(finalEntries[0].id == existingEntries[0].id)
        #expect(finalEntries[1].id == existingEntries[1].id)
        #expect(finalEntries[2].id == existingEntries[2].id)
    }
}