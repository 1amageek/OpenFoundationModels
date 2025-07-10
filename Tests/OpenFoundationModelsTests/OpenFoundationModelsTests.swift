import Testing
import Foundation
@testable import OpenFoundationModels

@Suite("OpenFoundationModels Core Tests")
struct OpenFoundationModelsTests {
    
    @Test("Availability Status Tests")
    func availabilityStatus() {
        let available = AvailabilityStatus.available
        #expect(available.isAvailable == true)
        
        let unavailable = AvailabilityStatus.unavailable(reason: .deviceNotSupported)
        #expect(unavailable.isAvailable == false)
    }
    
    @Test("Prompt Creation")
    func promptCreation() {
        let prompt1: Prompt = "Hello, world!"
        #expect(prompt1.text == "Hello, world!")
        #expect(prompt1.metadata == nil)
        
        let prompt2 = Prompt("Test", metadata: ["key": "value"])
        #expect(prompt2.text == "Test")
        #expect(prompt2.metadata?["key"] == "value")
    }
    
    @Test("Instructions Creation")
    func instructionsCreation() {
        let instructions1: Instructions = "Be helpful"
        #expect(instructions1.text == "Be helpful")
        #expect(instructions1.priority == .normal)
        
        let instructions2 = Instructions("Be creative", priority: .high)
        #expect(instructions2.text == "Be creative")
        #expect(instructions2.priority == .high)
    }
    
    @Test("Response Structure")
    func responseStructure() {
        let response = Response(
            content: "Hello!",
            usage: TokenUsage(promptTokens: 10, completionTokens: 5),
            metadata: ResponseMetadata(model: "test-model")
        )
        
        #expect(response.content == "Hello!")
        #expect(response.usage?.totalTokens == 15)
        #expect(response.metadata?.model == "test-model")
    }
    
    @Test("Tool Call Structure")
    func toolCallStructure() {
        let toolCall = ToolCall(
            name: "weather",
            arguments: "{\"city\": \"Tokyo\"}"
        )
        
        #expect(toolCall.name == "weather")
        #expect(toolCall.arguments.contains("Tokyo"))
        #expect(!toolCall.id.isEmpty)
    }
    
    @Test("Transcript Entry Creation")
    func transcriptEntryCreation() {
        let userEntry = TranscriptEntry.user("Hello")
        #expect(userEntry.role == .user)
        #expect(userEntry.content == "Hello")
        
        let assistantEntry = TranscriptEntry.assistant("Hi there!")
        #expect(assistantEntry.role == .assistant)
        #expect(assistantEntry.content == "Hi there!")
    }
    
    @Test("Generation Options")
    func generationOptions() {
        let options = GenerationOptions(
            temperature: 0.7,
            topP: 0.9,
            maxTokens: 100,
            samplingMethod: .random
        )
        
        #expect(options.temperature == 0.7)
        #expect(options.topP == 0.9)
        #expect(options.maxTokens == 100)
        #expect(options.samplingMethod == .random)
    }
}
