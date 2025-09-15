import Foundation
import Testing
@testable import OpenFoundationModels
import OpenFoundationModelsMacros

@Suite("Tool Schema in Instructions Tests")
struct ToolSchemaInInstructionsTests {
    
    // MARK: - Test Tools
    
    struct WeatherTool: Tool {
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
        let description = "Perform mathematical calculations"
        
        // Override to not include schema in instructions for testing
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
            
            // Return a simple response
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
    
    // MARK: - Tests
    
    @Test("Tool schema is included in instructions when includesSchemaInInstructions is true")
    func toolSchemaIncludedInInstructions() async throws {
        let model = MockLanguageModel()
        let weatherTool = WeatherTool()
        
        let session = LanguageModelSession(
            model: model,
            tools: [weatherTool],
            instructions: "You are a helpful assistant."
        )
        
        // Trigger a response to capture the transcript
        _ = try await session.respond(to: "What's the weather?")
        
        // Check that the transcript was captured
        let transcript = try #require(model.capturedTranscript)
        
        // Find the instructions entry
        let instructionsEntry = transcript.entries.first { entry in
            if case .instructions = entry {
                return true
            }
            return false
        }
        
        let instructions = try #require(instructionsEntry)
        
        // Extract the instructions content
        if case .instructions(let instructionsData) = instructions {
            let textSegment = instructionsData.segments.first
            
            if case .text(let text) = textSegment {
                let content = text.content
                
                // Verify the instructions contain the base text
                #expect(content.contains("You are a helpful assistant."))
                
                // Verify the instructions contain the Available Tools section
                #expect(content.contains("## Available Tools"))
                
                // Verify the tool name and description are included
                #expect(content.contains("### Tool: WeatherTool"))
                #expect(content.contains("Description: Get weather information for a city"))
                
                // Verify the parameters schema is included
                #expect(content.contains("Parameters:"))
                #expect(content.contains("```json"))
                
                // Verify the schema contains expected properties
                #expect(content.contains("\"city\""))
                #expect(content.contains("\"units\""))
            } else {
                Issue.record("Expected text segment in instructions")
            }
        } else {
            Issue.record("Expected instructions entry")
        }
    }
    
    @Test("Tool schema is not included when includesSchemaInInstructions is false")
    func toolSchemaNotIncludedWhenFlagIsFalse() async throws {
        let model = MockLanguageModel()
        let calculatorTool = CalculatorTool()
        
        let session = LanguageModelSession(
            model: model,
            tools: [calculatorTool],
            instructions: "You are a helpful assistant."
        )
        
        // Trigger a response to capture the transcript
        _ = try await session.respond(to: "Calculate 2+2")
        
        // Check that the transcript was captured
        let transcript = try #require(model.capturedTranscript)
        
        // Find the instructions entry
        let instructionsEntry = transcript.entries.first { entry in
            if case .instructions = entry {
                return true
            }
            return false
        }
        
        let instructions = try #require(instructionsEntry)
        
        // Extract the instructions content
        if case .instructions(let instructionsData) = instructions {
            let textSegment = instructionsData.segments.first
            
            if case .text(let text) = textSegment {
                let content = text.content
                
                // Verify the tool is listed but without schema
                #expect(content.contains("### Tool: CalculatorTool"))
                #expect(content.contains("Description: Perform mathematical calculations"))
                
                // Verify the parameters schema is NOT included
                #expect(!content.contains("Parameters:"))
                #expect(!content.contains("\"expression\""))
            } else {
                Issue.record("Expected text segment in instructions")
            }
        } else {
            Issue.record("Expected instructions entry")
        }
    }
    
    @Test("Multiple tools are correctly formatted in instructions")
    func multipleToolsInInstructions() async throws {
        let model = MockLanguageModel()
        let weatherTool = WeatherTool()
        let calculatorTool = CalculatorTool()
        
        let session = LanguageModelSession(
            model: model,
            tools: [weatherTool, calculatorTool],
            instructions: "You are a helpful assistant."
        )
        
        // Trigger a response to capture the transcript
        _ = try await session.respond(to: "Test")
        
        // Check that the transcript was captured
        let transcript = try #require(model.capturedTranscript)
        
        // Find the instructions entry
        let instructionsEntry = transcript.entries.first { entry in
            if case .instructions = entry {
                return true
            }
            return false
        }
        
        let instructions = try #require(instructionsEntry)
        
        // Extract the instructions content
        if case .instructions(let instructionsData) = instructions {
            let textSegment = instructionsData.segments.first
            
            if case .text(let text) = textSegment {
                let content = text.content
                
                // Verify both tools are listed
                #expect(content.contains("### Tool: WeatherTool"))
                #expect(content.contains("### Tool: CalculatorTool"))
                
                // Verify WeatherTool has schema (includesSchemaInInstructions = true by default)
                let weatherToolIndex = content.range(of: "### Tool: WeatherTool")?.lowerBound ?? content.startIndex
                let calculatorToolIndex = content.range(of: "### Tool: CalculatorTool")?.lowerBound ?? content.startIndex
                let weatherSection = String(content[weatherToolIndex..<calculatorToolIndex])
                
                #expect(weatherSection.contains("Parameters:"))
                #expect(weatherSection.contains("```json"))
                
                // Verify CalculatorTool does not have schema (includesSchemaInInstructions = false)
                let calculatorSection = String(content[calculatorToolIndex...])
                #expect(!calculatorSection.contains("Parameters:"))
            } else {
                Issue.record("Expected text segment in instructions")
            }
        } else {
            Issue.record("Expected instructions entry")
        }
    }
    
    @Test("No tools section when no tools are provided")
    func noToolsSectionWhenNoTools() async throws {
        let model = MockLanguageModel()
        
        let session = LanguageModelSession(
            model: model,
            tools: [],
            instructions: "You are a helpful assistant."
        )
        
        // Trigger a response to capture the transcript
        _ = try await session.respond(to: "Test")
        
        // Check that the transcript was captured
        let transcript = try #require(model.capturedTranscript)
        
        // Find the instructions entry
        let instructionsEntry = transcript.entries.first { entry in
            if case .instructions = entry {
                return true
            }
            return false
        }
        
        let instructions = try #require(instructionsEntry)
        
        // Extract the instructions content
        if case .instructions(let instructionsData) = instructions {
            let textSegment = instructionsData.segments.first
            
            if case .text(let text) = textSegment {
                let content = text.content
                
                // Verify the instructions contain only the base text
                #expect(content == "You are a helpful assistant.")
                
                // Verify no Available Tools section
                #expect(!content.contains("## Available Tools"))
            } else {
                Issue.record("Expected text segment in instructions")
            }
        } else {
            Issue.record("Expected instructions entry")
        }
    }
}
