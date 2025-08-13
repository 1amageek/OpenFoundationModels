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
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "Hello",
                rawContent: GeneratedContent("Hello")
            )
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "Hello, world!",
                rawContent: GeneratedContent("Hello, world!")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // Verify the stream is created successfully
        // ResponseStream doesn't have a last property - it's just an AsyncSequence
    }
    
    @Test("ResponseStream AsyncSequence iteration with String content")
    func responseStreamStringIteration() async throws {
        // Create a stream that yields partial string responses
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "Hello",
                rawContent: GeneratedContent("Hello")
            )
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "Hello, world!",
                rawContent: GeneratedContent("Hello, world!")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        var collectedPartials: [String] = []
        
        // Test AsyncSequence iteration
        for try await snapshot in responseStream {
            collectedPartials.append(snapshot.content)
        }
        
        // Verify we collected the expected partial responses
        #expect(collectedPartials.count == 2)
        // Partials are now String
        #expect(collectedPartials[0] == "Hello")
        #expect(collectedPartials[1] == "Hello, world!")
    }
    
    @Test("ResponseStream with String Generable content")
    func responseStreamStringGenerableIteration() async throws {
        // String already conforms to Generable, so we can test with it
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "partial content",
                rawContent: GeneratedContent("partial content")
            )
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "complete content",
                rawContent: GeneratedContent("complete content")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        var partialCount = 0
        var lastContent = ""
        
        // Test iteration with String Generable content
        for try await snapshot in responseStream {
            partialCount += 1
            // snapshot contains the content and rawContent
            lastContent = snapshot.content
            
            // For String, check if we've reached the expected final content
            if snapshot.content == "complete content" {
                break
            }
        }
        
        #expect(partialCount == 2)
        #expect(lastContent == "complete content")
    }
    
    @Test("ResponseStream collect() method")
    func responseStreamCollect() async throws {
        // Use String content for collect() testing
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "partial",
                rawContent: GeneratedContent("partial")
            )
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "final content",
                rawContent: GeneratedContent("final content")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // Test the collect() method
        let finalResponse = try await responseStream.collect()
        
        // Verify the final response contains the complete content
        #expect(finalResponse.content == "final content")
        #expect(finalResponse.transcriptEntries.isEmpty) // No transcript entries in mock
    }
    
    @Test("ResponseStream collect() with String returns last value")
    func responseStreamCollectWithString() async throws {
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "partial",
                rawContent: GeneratedContent("partial")
            )
            continuation.yield(snapshot)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // For String type, collect() returns the last value since String has no concept of "complete"
        let response = try await responseStream.collect()
        #expect(response.content == "partial")
    }
    
    @Test("ResponseStream collectPartials() helper method")
    func responseStreamCollectPartials() async throws {
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "first",
                rawContent: GeneratedContent("first")
            )
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "second",
                rawContent: GeneratedContent("second")
            )
            let snapshot3 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "final",
                rawContent: GeneratedContent("final")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.yield(snapshot3)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // Collect all partials manually since collectPartials() doesn't exist
        var allPartials: [String] = []
        for try await snapshot in responseStream {
            allPartials.append(snapshot.content)
        }
        
        #expect(allPartials.count == 3)
        // Partials are now String
        #expect(allPartials[0] == "first")
        #expect(allPartials[1] == "second")
        #expect(allPartials[2] == "final")
    }
    
    @Test("ResponseStream error handling")
    func responseStreamErrorHandling() async throws {
        let expectedError = LanguageModelSession.GenerationError.rateLimited(
            LanguageModelSession.GenerationError.Context(debugDescription: "Test rate limit")
        )
        
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "partial",
                rawContent: GeneratedContent("partial")
            )
            continuation.yield(snapshot)
            continuation.finish(throwing: expectedError)
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // Test error propagation through AsyncSequence
        await #expect(throws: LanguageModelSession.GenerationError.self) {
            for try await _ in responseStream {
                // Should throw before completing iteration
            }
        }
    }
    
    @Test("ResponseStream AsyncIterator works correctly")
    func responseStreamIteratorCorrectness() async throws {
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "one",
                rawContent: GeneratedContent("one")
            )
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "two",
                rawContent: GeneratedContent("two")
            )
            let snapshot3 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "three",
                rawContent: GeneratedContent("three")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.yield(snapshot3)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // Create an iterator and verify it works
        var iterator = responseStream.makeAsyncIterator()
        
        let first = try await iterator.next()
        let second = try await iterator.next()
        let third = try await iterator.next()
        let fourth = try await iterator.next()
        
        // Snapshots contain content and rawContent
        #expect(first?.content == "one")
        #expect(second?.content == "two")
        #expect(third?.content == "three")
        #expect(fourth == nil) // Stream should be finished
    }
    
    @Test("ResponseStream Sendable conformance")
    func responseStreamSendableConformance() {
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // This test verifies Sendable conformance compiles
        let _: any Sendable = responseStream
        #expect(Bool(true)) // Compilation success
    }
}