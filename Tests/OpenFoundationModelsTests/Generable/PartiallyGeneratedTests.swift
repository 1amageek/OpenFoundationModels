import Testing
import Foundation
@testable import OpenFoundationModels



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





@Suite("PartiallyGenerated Tests", .tags(.generable, .streaming, .integration))
struct PartiallyGeneratedTests {
    
    @Test("Basic PartiallyGenerated with simple types")
    func basicPartiallyGeneratedSimpleTypes() throws {
        let json = #"{"name": "Alice", "age": 25}"#
        let userInfo = try TestUserInfo(GeneratedContent(json: json))
        let partial = userInfo.asPartiallyGenerated()
        
        #expect(partial.name == "Alice")
        #expect(partial.age == 25)
        #expect(partial.isComplete == true)
    }
    
    @Test("Partial Response creation and isComplete flag", .disabled("Response.Partial not implemented"))
    func partialResponseCreationAndCompleteness() throws {
    }
    
    @Test("Streaming progression with partial updates")
    func streamingProgressionWithPartialUpdates() async throws {
        let initialPartial = "Initial content"
        let midPartial = "Middle content"
        let finalPartial = "Final content"
        
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: initialPartial,
                rawContent: GeneratedContent(initialPartial)
            )
            continuation.yield(snapshot1)
            
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: midPartial,
                rawContent: GeneratedContent(midPartial)
            )
            continuation.yield(snapshot2)
            
            let snapshot3 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: finalPartial,
                rawContent: GeneratedContent(finalPartial)
            )
            continuation.yield(snapshot3)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        var partialCount = 0
        var lastComplete = false
        
        for try await snapshot in responseStream {
            partialCount += 1
            if snapshot.content == "Final content" {
                lastComplete = true
                break
            }
        }
        
        #expect(partialCount == 3) // All three partials should be received
        #expect(lastComplete == true) // Final should be marked complete
    }
    
    @Test("PartiallyGenerated with multiple properties")
    func partiallyGeneratedWithMultipleProperties() throws {
        let partialJSON = #"{"name": "Widget", "price": 19.99}"#
        let partial = try TestProduct.PartiallyGenerated(GeneratedContent(json: partialJSON))
        
        #expect(partial.name == "Widget")
        #expect(partial.price == 19.99)
        #expect(partial.inStock == nil)  // Missing property should be nil
        #expect(partial.isComplete == false)  // Not all properties present
        
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
    }
    
    @Test("Streaming collect() with PartiallyGenerated")
    func streamingCollectWithPartiallyGenerated() async throws {
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "partial1",
                rawContent: GeneratedContent("partial1")
            )
            continuation.yield(snapshot1)
            
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "partial2",
                rawContent: GeneratedContent("partial2")
            )
            continuation.yield(snapshot2)
            
            let snapshot3 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "complete content",
                rawContent: GeneratedContent("complete content")
            )
            continuation.yield(snapshot3)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        let finalResponse = try await responseStream.collect()
        
        #expect(finalResponse.content == "complete content")
        #expect(finalResponse.transcriptEntries.isEmpty)
    }
    
    @Test("Error handling during partial generation")
    func errorHandlingDuringPartialGeneration() async {
        let error = GenerationError.decodingFailure(
            GenerationError.Context(debugDescription: "Test generation failure")
        )
        
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "partial content",
                rawContent: GeneratedContent("partial content")
            )
            continuation.yield(snapshot)
            continuation.finish(throwing: error)
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        await #expect(throws: GenerationError.self) {
            for try await _ in responseStream {
            }
        }
    }
    
    @Test("Multiple PartiallyGenerated types in same stream")
    func multiplePartiallyGeneratedTypesInSameStream() throws {
        let typeA = try TestTypeA(GeneratedContent(json: "{}"))
        let typeB = try TestTypeB(GeneratedContent(json: "{}"))
        
        let partialA = typeA.asPartiallyGenerated()
        let partialB = typeB.asPartiallyGenerated()
        
        #expect(partialA.valueA == nil)
        #expect(partialB.valueB == nil)
        
    }
    
    @Test("Progressive streaming JSON simulation")
    func progressiveStreamingJSONSimulation() throws {
        
        let stage1 = try GeneratedContent(json: "{}")
        let partial1 = try TestStreamingProfile.PartiallyGenerated(stage1)
        #expect(partial1.id == nil)
        #expect(partial1.username == nil)
        #expect(partial1.email == nil)
        #expect(partial1.score == nil)
        #expect(partial1.isComplete == false)
        
        let stage2 = try GeneratedContent(json: #"{"id": "user123"}"#)
        let partial2 = try TestStreamingProfile.PartiallyGenerated(stage2)
        #expect(partial2.id == "user123")
        #expect(partial2.username == nil)
        #expect(partial2.email == nil)
        #expect(partial2.score == nil)
        #expect(partial2.isComplete == false)
        
        let stage3 = try GeneratedContent(json: #"{"id": "user123", "username": "alice", "email": "alice@example.com"}"#)
        let partial3 = try TestStreamingProfile.PartiallyGenerated(stage3)
        #expect(partial3.id == "user123")
        #expect(partial3.username == "alice")
        #expect(partial3.email == "alice@example.com")
        #expect(partial3.score == nil)
        #expect(partial3.isComplete == false)
        
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
        
        let stage1 = try GeneratedContent(json: "{}")
        let partial1 = try TestCompany.PartiallyGenerated(stage1)
        #expect(partial1.name == nil)
        #expect(partial1.address == nil)
        #expect(partial1.employees == nil)
        #expect(partial1.isComplete == false)
        
        let stage2 = try GeneratedContent(json: #"{"name": "TechCorp"}"#)
        let partial2 = try TestCompany.PartiallyGenerated(stage2)
        #expect(partial2.name == "TechCorp")
        #expect(partial2.address == nil)
        #expect(partial2.employees == nil)
        #expect(partial2.isComplete == false)
        
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
    }
    
    @Test("Deep nesting progressive construction", .disabled("Deep nested structures temporarily disabled"))
    func deepNestingProgressiveConstruction() throws {
    }
}