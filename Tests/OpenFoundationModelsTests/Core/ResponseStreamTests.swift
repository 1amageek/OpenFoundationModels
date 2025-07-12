import Testing
import Foundation
@testable import OpenFoundationModels

/// Tests for ResponseStream functionality
/// 
/// **Focus:** Validates ResponseStream AsyncSequence behavior, streaming mechanics,
/// partial response handling, and collect() functionality according to Apple's specification.
///
/// **Apple Foundation Models Documentation:**
/// ResponseStream provides streaming access to generated content as it becomes
/// available from the language model, conforming to AsyncSequence protocol.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/responsestream
@Suite("ResponseStream Tests", .tags(.core, .streaming))
struct ResponseStreamTests {
    
    @Test("ResponseStream creation and basic properties")
    func responseStreamCreation() {
        // Create a simple stream with string content
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "Hello", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "Hello, world!", isComplete: true))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // Verify the stream is created successfully
        #expect(responseStream.last == nil) // Initially no last value
    }
    
    @Test("ResponseStream AsyncSequence iteration with String content")
    func responseStreamStringIteration() async throws {
        // Create a stream that yields partial string responses
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "Hello", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "Hello, world!", isComplete: true))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        var collectedPartials: [Response<String>.Partial] = []
        
        // Test AsyncSequence iteration
        for try await partial in responseStream {
            collectedPartials.append(partial)
        }
        
        // Verify we collected the expected partial responses
        #expect(collectedPartials.count == 2)
        #expect(collectedPartials[0].content == "Hello")
        #expect(collectedPartials[0].isComplete == false)
        #expect(collectedPartials[1].content == "Hello, world!")
        #expect(collectedPartials[1].isComplete == true)
    }
    
    @Test("ResponseStream with String Generable content")
    func responseStreamStringGenerableIteration() async throws {
        // String already conforms to Generable, so we can test with it
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "partial content", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "complete content", isComplete: true))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        var partialCount = 0
        var lastContent = ""
        
        // Test iteration with String Generable content
        for try await partial in responseStream {
            partialCount += 1
            lastContent = partial.content
            
            if partial.isComplete {
                break
            }
        }
        
        #expect(partialCount == 2)
        #expect(lastContent == "complete content")
    }
    
    @Test("ResponseStream collect() method")
    func responseStreamCollect() async throws {
        // Use String content for collect() testing
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "partial", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "final content", isComplete: true))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // Test the collect() method
        let finalResponse = try await responseStream.collect()
        
        // Verify the final response contains the complete content
        #expect(finalResponse.content == "final content")
        #expect(finalResponse.transcriptEntries.isEmpty) // No transcript entries in mock
    }
    
    @Test("ResponseStream collect() with no complete response throws error")
    func responseStreamCollectIncomplete() async throws {
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "partial", isComplete: false))
            continuation.finish() // No complete response
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // Should throw when no complete response is found
        await #expect(throws: GenerationError.self) {
            try await responseStream.collect()
        }
    }
    
    @Test("ResponseStream collectPartials() helper method")
    func responseStreamCollectPartials() async throws {
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "first", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "second", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "final", isComplete: true))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // Test the collectPartials() helper method
        let allPartials = try await responseStream.collectPartials()
        
        #expect(allPartials.count == 3)
        #expect(allPartials[0].content == "first")
        #expect(allPartials[1].content == "second")
        #expect(allPartials[2].content == "final")
        #expect(allPartials[2].isComplete == true)
    }
    
    @Test("ResponseStream error handling")
    func responseStreamErrorHandling() async throws {
        let expectedError = GenerationError.rateLimited(
            GenerationError.Context(debugDescription: "Test rate limit")
        )
        
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "partial", isComplete: false))
            continuation.finish(throwing: expectedError)
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // Test error propagation through AsyncSequence
        await #expect(throws: GenerationError.self) {
            for try await _ in responseStream {
                // Should throw before completing iteration
            }
        }
    }
    
    @Test("ResponseStream AsyncIterator works correctly")
    func responseStreamIteratorCorrectness() async throws {
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "one", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "two", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "three", isComplete: true))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // Create an iterator and verify it works
        var iterator = responseStream.makeAsyncIterator()
        
        let first = try await iterator.next()
        let second = try await iterator.next()
        let third = try await iterator.next()
        let fourth = try await iterator.next()
        
        #expect(first?.content == "one")
        #expect(first?.isComplete == false)
        #expect(second?.content == "two")
        #expect(second?.isComplete == false)
        #expect(third?.content == "three")
        #expect(third?.isComplete == true)
        #expect(fourth == nil) // Stream should be finished
    }
    
    @Test("ResponseStream Sendable conformance")
    func responseStreamSendableConformance() {
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // This test verifies Sendable conformance compiles
        let _: any Sendable = responseStream
        #expect(Bool(true)) // Compilation success
    }
}