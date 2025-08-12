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

// MARK: - Nested Structure Test Types

@Generable
struct TestCompany {
    let name: String
    let address: TestCompanyAddress
    let employees: [TestCompanyEmployee]
}

@Generable
struct TestCompanyAddress {
    let street: String
    let city: String
    let zipCode: String
}

@Generable
struct TestCompanyEmployee {
    let id: String
    let name: String
    let department: String?
}

// MARK: - Array Structure Test Types

/*
@Generable
struct TestShoppingCart {
    let userId: String
    let items: [TestCartItem]
    let total: Double
}

@Generable
struct TestCartItem {
    let productId: String
    let name: String
    let quantity: Int
    let price: Double
}
*/

// MARK: - Deep Nested Structure Test Types

/*
@Generable
struct TestDocument {
    let title: String
    let metadata: TestDocumentMetadata
    let sections: [TestDocumentSection]
}

@Generable
struct TestDocumentMetadata {
    let author: TestDocumentAuthor
    let tags: [String]
    let version: String
}

@Generable
struct TestDocumentAuthor {
    let name: String
    let email: String
    let organization: TestDocumentOrganization?
}

@Generable
struct TestDocumentOrganization {
    let name: String
    let department: String
}

@Generable
struct TestDocumentSection {
    let title: String
    let content: String
    let subsections: [TestDocumentSubsection]?
}

@Generable
struct TestDocumentSubsection {
    let title: String
    let content: String
}
*/

@Suite("PartiallyGenerated Tests", .tags(.generable, .streaming, .integration))
struct PartiallyGeneratedTests {
    
    @Test("Basic PartiallyGenerated with simple types")
    func basicPartiallyGeneratedSimpleTypes() throws {
        // Test asPartiallyGenerated method exists and works
        let json = #"{"name": "Alice", "age": 25}"#
        let userInfo = try TestUserInfo(GeneratedContent(json: json))
        let partial = userInfo.asPartiallyGenerated()
        
        // Verify partial has same values as original
        #expect(partial.name == "Alice")
        #expect(partial.age == 25)
        #expect(partial.isComplete == true)
    }
    
    @Test("Partial Response creation and isComplete flag", .disabled("Response.Partial not implemented"))
    func partialResponseCreationAndCompleteness() throws {
        // Response.Partial is not part of the current implementation
        // This test is disabled until the API is clarified
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
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
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
        let partial = try TestProduct.PartiallyGenerated(GeneratedContent(json: partialJSON))
        
        // Verify partial properties
        #expect(partial.name == "Widget")
        #expect(partial.price == 19.99)
        #expect(partial.inStock == nil)  // Missing property should be nil
        #expect(partial.isComplete == false)  // Not all properties present
        
        // Test with complete JSON
        let completeJSON = #"{"name": "Widget", "price": 19.99, "inStock": true}"#
        let complete = try TestProduct.PartiallyGenerated(GeneratedContent(json: completeJSON))
        
        #expect(complete.name == "Widget")
        #expect(complete.price == 19.99)
        #expect(complete.inStock == true)
        #expect(complete.isComplete == true)  // All properties present
    }
    
    @Test("PartiallyGenerated Sendable conformance")
    func partiallyGeneratedSendableConformance() async throws {
        let data = try TestSafeData(GeneratedContent(json: "{}"))
        let partial = data.asPartiallyGenerated()
        
        // Test that partial works in async context (Sendable conformance)
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let asyncPartial = partial
                #expect(asyncPartial.message == nil)
                #expect(asyncPartial.value == nil)
            }
        }
    }
    
    @Test("Response.Partial with String content", .disabled("Response.Partial not implemented"))
    func responsePartialWithStringContent() {
        // Response.Partial is not part of the current implementation
        // This test is disabled until the API is clarified
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
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
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
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
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
        let typeA = try TestTypeA(GeneratedContent(json: "{}"))
        let typeB = try TestTypeB(GeneratedContent(json: "{}"))
        
        let partialA = typeA.asPartiallyGenerated()
        let partialB = typeB.asPartiallyGenerated()
        
        #expect(partialA.valueA == nil)
        #expect(partialB.valueB == nil)
        
        // Response.Partial tests removed - not part of current implementation
        // Test type independence directly - partialA and partialB are valid instances
        // They are non-optional values, so checking they exist is not necessary
    }
    
    @Test("Progressive streaming JSON simulation")
    func progressiveStreamingJSONSimulation() throws {
        // Simulate progressive JSON streaming like from an LLM
        
        // Stage 1: Empty JSON
        let stage1 = try GeneratedContent(json: "{}")
        let partial1 = try TestStreamingProfile.PartiallyGenerated(stage1)
        #expect(partial1.id == nil)
        #expect(partial1.username == nil)
        #expect(partial1.email == nil)
        #expect(partial1.score == nil)
        #expect(partial1.isComplete == false)
        
        // Stage 2: ID arrives
        let stage2 = try GeneratedContent(json: #"{"id": "user123"}"#)
        let partial2 = try TestStreamingProfile.PartiallyGenerated(stage2)
        #expect(partial2.id == "user123")
        #expect(partial2.username == nil)
        #expect(partial2.email == nil)
        #expect(partial2.score == nil)
        #expect(partial2.isComplete == false)
        
        // Stage 3: Username and email arrive
        let stage3 = try GeneratedContent(json: #"{"id": "user123", "username": "alice", "email": "alice@example.com"}"#)
        let partial3 = try TestStreamingProfile.PartiallyGenerated(stage3)
        #expect(partial3.id == "user123")
        #expect(partial3.username == "alice")
        #expect(partial3.email == "alice@example.com")
        #expect(partial3.score == nil)
        #expect(partial3.isComplete == false)
        
        // Stage 4: Complete JSON
        let stage4 = try GeneratedContent(json: #"{"id": "user123", "username": "alice", "email": "alice@example.com", "score": 95}"#)
        let partial4 = try TestStreamingProfile.PartiallyGenerated(stage4)
        #expect(partial4.id == "user123")
        #expect(partial4.username == "alice")
        #expect(partial4.email == "alice@example.com")
        #expect(partial4.score == 95)
        #expect(partial4.isComplete == true)
    }
    
    @Test("Progressive nested JSON parsing")
    func progressiveNestedJSONParsing() throws {
        // Test progressive parsing of nested JSON structures
        
        // Stage 1: Empty JSON
        let stage1 = try GeneratedContent(json: "{}")
        let partial1 = try TestCompany.PartiallyGenerated(stage1)
        #expect(partial1.name == nil)
        #expect(partial1.address == nil)
        #expect(partial1.employees == nil)
        #expect(partial1.isComplete == false)
        
        // Stage 2: Company name only
        let stage2 = try GeneratedContent(json: #"{"name": "TechCorp"}"#)
        let partial2 = try TestCompany.PartiallyGenerated(stage2)
        #expect(partial2.name == "TechCorp")
        #expect(partial2.address == nil)
        #expect(partial2.employees == nil)
        #expect(partial2.isComplete == false)
        
        // Stage 3: Complete JSON with all fields
        let stage3 = try GeneratedContent(json: #"""
        {
            "name": "TechCorp",
            "address": {
                "street": "123 Main St",
                "city": "San Francisco",
                "zipCode": "94105"
            },
            "employees": [
                {"id": "emp1", "name": "Alice", "department": "Engineering"},
                {"id": "emp2", "name": "Bob", "department": null}
            ]
        }
        """#)
        let partial3 = try TestCompany.PartiallyGenerated(stage3)
        #expect(partial3.name == "TechCorp")
        #expect(partial3.address != nil)
        #expect(partial3.address?.street == "123 Main St")
        #expect(partial3.employees != nil)
        #expect(partial3.employees?.count == 2)
        #expect(partial3.isComplete == true)
    }
    
    @Test("Array streaming with partial elements", .disabled("Array structures temporarily disabled"))
    func arrayStreamingWithPartialElements() throws {
        // Test progressive building of arrays in JSON
        // NOTE: Test implementation temporarily removed due to macro expansion issues
        // with array types. Will be re-enabled once macro handles these cases.
    }
    
    @Test("Deep nesting progressive construction", .disabled("Deep nested structures temporarily disabled"))
    func deepNestingProgressiveConstruction() throws {
        // Test deeply nested structures being built progressively
        // NOTE: Test implementation temporarily removed due to macro expansion issues
        // with deeply nested types. Will be re-enabled once macro handles these cases.
    }
}