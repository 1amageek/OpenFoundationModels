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

@Suite("PartiallyGenerated Tests", .tags(.generable, .streaming, .integration))
struct PartiallyGeneratedTests {
    
    @Test("Basic PartiallyGenerated with simple types")
    func basicPartiallyGeneratedSimpleTypes() throws {
        // Test asPartiallyGenerated method exists and works
        let userInfo = try TestUserInfo(GeneratedContent("{}"))
        let partial = userInfo.asPartiallyGenerated()
        
        // Verify partial has same values as original (basic implementation)
        #expect(partial.name == userInfo.name)
        #expect(partial.age == userInfo.age)
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
        let initialPartial = Response<String>.Partial(
            content: "Initial content",
            isComplete: false
        )
        
        let midPartial = Response<String>.Partial(
            content: "Middle content",
            isComplete: false
        )
        
        let finalPartial = Response<String>.Partial(
            content: "Final content",
            isComplete: true
        )
        
        // Create a stream that simulates progressive generation
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(initialPartial)
            continuation.yield(midPartial)
            continuation.yield(finalPartial)
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        var partialCount = 0
        var lastComplete = false
        
        // Test progressive updates
        for try await partial in responseStream {
            partialCount += 1
            if partial.isComplete {
                lastComplete = true
                break
            }
        }
        
        #expect(partialCount == 3) // All three partials should be received
        #expect(lastComplete == true) // Final should be marked complete
    }
    
    @Test("PartiallyGenerated with multiple properties")
    func partiallyGeneratedWithMultipleProperties() throws {
        let product = try TestProduct(GeneratedContent("{}"))
        let partial = product.asPartiallyGenerated()
        
        // Verify all properties are accessible in partial
        #expect(partial.name == "")
        #expect(partial.price == 0.0)
        #expect(partial.inStock == false)
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
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            // Partial updates
            continuation.yield(Response<String>.Partial(
                content: "partial1",
                isComplete: false
            ))
            continuation.yield(Response<String>.Partial(
                content: "partial2",
                isComplete: false
            ))
            // Final complete
            continuation.yield(Response<String>.Partial(
                content: "complete content",
                isComplete: true
            ))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
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
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(
                content: "partial content",
                isComplete: false
            ))
            continuation.finish(throwing: error)
        }
        
        let responseStream = ResponseStream(stream: stream)
        
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
}