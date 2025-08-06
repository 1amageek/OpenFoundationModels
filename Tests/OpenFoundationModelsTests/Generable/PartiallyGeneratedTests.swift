import Testing
import Foundation
@testable import OpenFoundationModels

/// Tests for PartiallyGenerated functionality during streaming
/// 
/// **Focus:** Validates partial response handling during streaming generation,
/// testing the progression from incomplete to complete responses with @Generable
/// types according to Apple's Foundation Models specification.
///
/// **Apple Foundation Models Documentation:**
/// PartiallyGenerated types represent intermediate states during streaming generation,
/// allowing real-time updates as content is generated progressively.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/generable/partiallygenerated

// MARK: - Test Types (moved from local scope to top level)

@Generable
struct TestUserInfo {
    let name: String
    let age: Int
}

@Generable
struct TestMessage {
    let content: String
    let timestamp: Int
}

@Generable
struct TestProduct {
    @Guide(description: "Product name")
    let name: String
    
    @Guide(description: "Price in USD")
    let price: Double
    
    @Guide(description: "In stock")
    let inStock: Bool
}

@Generable
struct TestSafeData {
    let message: String
    let value: Int
}

@Generable
struct TestTypeA {
    let valueA: String
}

@Generable
struct TestTypeB {
    let valueB: Int
}

@Generable
struct TestStreamingProfile {
    let id: String
    let username: String
    let email: String
    let score: Int
}

@Suite("PartiallyGenerated Tests", .tags(.generable, .streaming, .integration))
struct PartiallyGeneratedTests {
    
    @Test("Basic PartiallyGenerated with simple types")
    func basicPartiallyGeneratedSimpleTypes() throws {
        // Test asPartiallyGenerated method exists and works
        let json = #"{"name": "Alice", "age": 25}"#
        let userInfo = try TestUserInfo(GeneratedContent(json))
        let partial = userInfo.asPartiallyGenerated()
        
        // Verify partial has same values as original
        #expect(partial.name == "Alice")
        #expect(partial.age == 25)
        #expect(partial.isComplete == true)
    }
    
    @Test("Partial Response creation and isComplete flag")
    func partialResponseCreationAndCompleteness() throws {
        let message = try TestMessage(GeneratedContent("{}"))
        
        // Test Response.Partial creation
        let incompletePartial = Response<TestMessage>.Partial(
            content: message,
            isComplete: false
        )
        
        let completePartial = Response<TestMessage>.Partial(
            content: message,
            isComplete: true
        )
        
        // Verify isComplete flag works correctly
        #expect(incompletePartial.isComplete == false)
        #expect(completePartial.isComplete == true)
        
        // Verify content is accessible
        #expect(incompletePartial.content.content == "")
        #expect(completePartial.content.content == "")
    }
    
    @Test("Streaming progression with partial updates")
    func streamingProgressionWithPartialUpdates() async throws {
        // Use String content (already Generable) for streaming tests
        // For String, PartiallyGenerated = String (default)
        let initialPartial = "Initial content"
        let midPartial = "Middle content"
        let finalPartial = "Final content"
        
        // Create a stream that simulates progressive generation
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            continuation.yield(initialPartial)
            continuation.yield(midPartial)
            continuation.yield(finalPartial)
            continuation.finish()
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        var partialCount = 0
        var lastComplete = false
        
        // Test progressive updates
        for try await partial in responseStream {
            partialCount += 1
            // For String, we don't have isComplete tracking
            // Check for specific final content instead
            if partial == "Final content" {
                lastComplete = true
                break
            }
        }
        
        #expect(partialCount == 3) // All three partials should be received
        #expect(lastComplete == true) // Final should be marked complete
    }
    
    @Test("PartiallyGenerated with multiple properties")
    func partiallyGeneratedWithMultipleProperties() throws {
        // Test with partial JSON data
        let partialJSON = #"{"name": "Widget", "price": 19.99}"#
        let partial = try TestProduct.PartiallyGenerated(GeneratedContent(partialJSON))
        
        // Verify partial properties
        #expect(partial.name == "Widget")
        #expect(partial.price == 19.99)
        #expect(partial.inStock == nil)  // Missing property should be nil
        #expect(partial.isComplete == false)  // Not all properties present
        
        // Test with complete JSON
        let completeJSON = #"{"name": "Widget", "price": 19.99, "inStock": true}"#
        let complete = try TestProduct.PartiallyGenerated(GeneratedContent(completeJSON))
        
        #expect(complete.name == "Widget")
        #expect(complete.price == 19.99)
        #expect(complete.inStock == true)
        #expect(complete.isComplete == true)  // All properties present
    }
    
    @Test("PartiallyGenerated Sendable conformance")
    func partiallyGeneratedSendableConformance() async throws {
        let data = try TestSafeData(GeneratedContent("{}"))
        let partial = data.asPartiallyGenerated()
        
        // Test that partial works in async context (Sendable conformance)
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let asyncPartial = partial
                #expect(asyncPartial.message == "")
                #expect(asyncPartial.value == 0)
            }
        }
    }
    
    @Test("Response.Partial with String content")
    func responsePartialWithStringContent() {
        // Test with String content (already Sendable + Generable)
        let partialString = Response<String>.Partial(
            content: "Partial content",
            isComplete: false
        )
        
        let completeString = Response<String>.Partial(
            content: "Complete content",
            isComplete: true
        )
        
        #expect(partialString.content == "Partial content")
        #expect(partialString.isComplete == false)
        #expect(completeString.content == "Complete content")
        #expect(completeString.isComplete == true)
    }
    
    @Test("Streaming collect() with PartiallyGenerated")
    func streamingCollectWithPartiallyGenerated() async throws {
        // Use String content for collect() testing
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            // Partial updates (String.PartiallyGenerated = String)
            continuation.yield("partial1")
            continuation.yield("partial2")
            // Final complete
            continuation.yield("complete content")
            continuation.finish()
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        
        // Test collect() waits for complete response
        let finalResponse = try await responseStream.collect()
        
        // Should contain the complete version
        #expect(finalResponse.content == "complete content")
        #expect(finalResponse.transcriptEntries.isEmpty)
    }
    
    @Test("Error handling during partial generation")
    func errorHandlingDuringPartialGeneration() async {
        let error = GenerationError.decodingFailure(
            GenerationError.Context(debugDescription: "Test generation failure")
        )
        
        // Create stream that fails during partial generation using String content
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            // String.PartiallyGenerated = String (default)
            continuation.yield("partial content")
            continuation.finish(throwing: error)
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        
        // Test error propagation through PartiallyGenerated stream
        await #expect(throws: GenerationError.self) {
            for try await _ in responseStream {
                // Should throw before completing
            }
        }
    }
    
    @Test("Multiple PartiallyGenerated types in same stream")
    func multiplePartiallyGeneratedTypesInSameStream() throws {
        // Test that different Generable types can have their own partial representations
        let typeA = try TestTypeA(GeneratedContent("{}"))
        let typeB = try TestTypeB(GeneratedContent("{}"))
        
        let partialA = typeA.asPartiallyGenerated()
        let partialB = typeB.asPartiallyGenerated()
        
        #expect(partialA.valueA == "")
        #expect(partialB.valueB == 0)
        
        // Test that they can be used in separate Response.Partial instances
        let responsePartialA = Response<TestTypeA>.Partial(content: typeA, isComplete: false)
        let responsePartialB = Response<TestTypeB>.Partial(content: typeB, isComplete: true)
        
        #expect(responsePartialA.isComplete == false)
        #expect(responsePartialB.isComplete == true)
    }
    
    @Test("Progressive streaming JSON simulation")
    func progressiveStreamingJSONSimulation() throws {
        // Simulate progressive JSON streaming like from an LLM
        
        // Stage 1: Empty JSON
        let stage1 = GeneratedContent("{}")
        let partial1 = try TestStreamingProfile.PartiallyGenerated(stage1)
        #expect(partial1.id == nil)
        #expect(partial1.username == nil)
        #expect(partial1.email == nil)
        #expect(partial1.score == nil)
        #expect(partial1.isComplete == false)
        
        // Stage 2: ID arrives
        let stage2 = GeneratedContent(#"{"id": "user123"}"#)
        let partial2 = try TestStreamingProfile.PartiallyGenerated(stage2)
        #expect(partial2.id == "user123")
        #expect(partial2.username == nil)
        #expect(partial2.email == nil)
        #expect(partial2.score == nil)
        #expect(partial2.isComplete == false)
        
        // Stage 3: Username and email arrive
        let stage3 = GeneratedContent(#"{"id": "user123", "username": "alice", "email": "alice@example.com"}"#)
        let partial3 = try TestStreamingProfile.PartiallyGenerated(stage3)
        #expect(partial3.id == "user123")
        #expect(partial3.username == "alice")
        #expect(partial3.email == "alice@example.com")
        #expect(partial3.score == nil)
        #expect(partial3.isComplete == false)
        
        // Stage 4: Complete JSON
        let stage4 = GeneratedContent(#"{"id": "user123", "username": "alice", "email": "alice@example.com", "score": 95}"#)
        let partial4 = try TestStreamingProfile.PartiallyGenerated(stage4)
        #expect(partial4.id == "user123")
        #expect(partial4.username == "alice")
        #expect(partial4.email == "alice@example.com")
        #expect(partial4.score == 95)
        #expect(partial4.isComplete == true)
    }
}