import Testing
import Foundation
@testable import OpenFoundationModels

@Suite("ResponseStream Tests", .tags(.core, .streaming))
struct ResponseStreamTests {
    
    @Test("ResponseStream creation and basic properties")
    func responseStreamCreation() {
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
        
        let _ = LanguageModelSession.ResponseStream<String>(stream: stream)
        
    }
    
    @Test("ResponseStream AsyncSequence iteration with String content")
    func responseStreamStringIteration() async throws {
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
        
        for try await snapshot in responseStream {
            collectedPartials.append(snapshot.content)
        }
        
        #expect(collectedPartials.count == 2)
        #expect(collectedPartials[0] == "Hello")
        #expect(collectedPartials[1] == "Hello, world!")
    }
    
    @Test("ResponseStream with String Generable content")
    func responseStreamStringGenerableIteration() async throws {
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
        
        for try await snapshot in responseStream {
            partialCount += 1
            lastContent = snapshot.content
            
            if snapshot.content == "complete content" {
                break
            }
        }
        
        #expect(partialCount == 2)
        #expect(lastContent == "complete content")
    }
    
    @Test("ResponseStream collect() method")
    func responseStreamCollect() async throws {
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
        
        let finalResponse = try await responseStream.collect()
        
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
        
        var allPartials: [String] = []
        for try await snapshot in responseStream {
            allPartials.append(snapshot.content)
        }
        
        #expect(allPartials.count == 3)
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
        
        await #expect(throws: LanguageModelSession.GenerationError.self) {
            for try await _ in responseStream {
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
        
        var iterator = responseStream.makeAsyncIterator()
        
        let first = try await iterator.next()
        let second = try await iterator.next()
        let third = try await iterator.next()
        let fourth = try await iterator.next()
        
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
        
        let _: any Sendable = responseStream
        #expect(Bool(true)) // Compilation success
    }
}