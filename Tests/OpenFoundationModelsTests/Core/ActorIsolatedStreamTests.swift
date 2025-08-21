import Testing
import Foundation
@testable import OpenFoundationModels

/// Tests demonstrating proper concurrency patterns for non-Sendable ResponseStream
/// Since ResponseStream is not Sendable according to Apple's documentation,
/// we need to use actor isolation or other patterns to handle concurrent operations
@Suite("Actor Isolated Stream Tests", .tags(.core, .streaming))
struct ActorIsolatedStreamTests {
    
    /// Actor to handle stream processing results
    /// Note: We can't pass ResponseStream to the actor because it's not Sendable
    actor StreamResultCollector {
        private var results: [String] = []
        
        func addResult(_ result: String) {
            results.append(result)
        }
        
        func getAllResults() -> [String] {
            return results
        }
        
        func clear() {
            results.removeAll()
        }
    }
    
    @Test("Actor for collecting results (not streams)")
    func actorForCollectingResults() async throws {
        let collector = StreamResultCollector()
        
        // Create multiple streams
        let streams = (0..<5).map { index in
            AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
                Task {
                    let content = "stream-\(index)"
                    let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                        content: content,
                        rawContent: GeneratedContent(content)
                    )
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }
        }
        
        let responseStreams = streams.map { LanguageModelSession.ResponseStream<String>(stream: $0) }
        
        // Process streams locally, then send results to actor
        for stream in responseStreams {
            let response = try await stream.collect()
            let result = response.content
            await collector.addResult(result)
        }
        
        let allResults = await collector.getAllResults()
        #expect(allResults.count == 5)
        for i in 0..<5 {
            #expect(allResults[i] == "stream-\(i)")
        }
    }
    
    @Test("MainActor-isolated stream processing")
    @MainActor
    func mainActorIsolatedStreamProcessing() async throws {
        // Create a stream
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            Task {
                let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: "main-actor-content",
                    rawContent: GeneratedContent("main-actor-content")
                )
                continuation.yield(snapshot)
                continuation.finish()
            }
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // Process on MainActor
        let response = try await responseStream.collect()
        #expect(response.content == "main-actor-content")
    }
    
    @Test("Sequential processing with timing")
    func sequentialProcessingWithTiming() async throws {
        let streamCount = 10
        
        let streams = (0..<streamCount).map { index in
            AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
                Task {
                    // Simulate some async work
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    
                    let content = "content-\(index)"
                    let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                        content: content,
                        rawContent: GeneratedContent(content)
                    )
                    continuation.yield(snapshot)
                    continuation.finish()
                }
            }
        }
        
        let responseStreams = streams.map { LanguageModelSession.ResponseStream<String>(stream: $0) }
        
        let startTime = Date()
        var results: [String] = []
        
        // Sequential processing - safe for non-Sendable types
        for stream in responseStreams {
            let response = try await stream.collect()
            results.append(response.content)
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        #expect(results.count == streamCount)
        // Sequential processing should complete all streams
        #expect(elapsedTime > 0) // Should take some time
        
        for (index, result) in results.enumerated() {
            #expect(result == "content-\(index)")
        }
    }
    
    @Test("Stream processing with async let")
    func streamProcessingWithAsyncLet() async throws {
        // Create two separate streams
        let stream1 = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            Task {
                let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: "first",
                    rawContent: GeneratedContent("first")
                )
                continuation.yield(snapshot)
                continuation.finish()
            }
        }
        
        let stream2 = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            Task {
                let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: "second",
                    rawContent: GeneratedContent("second")
                )
                continuation.yield(snapshot)
                continuation.finish()
            }
        }
        
        let responseStream1 = LanguageModelSession.ResponseStream<String>(stream: stream1)
        let responseStream2 = LanguageModelSession.ResponseStream<String>(stream: stream2)
        
        // Use async let to process both streams
        // This is safe because each stream is processed in its own context
        async let response1 = responseStream1.collect()
        async let response2 = responseStream2.collect()
        
        let result1 = try await response1
        let result2 = try await response2
        
        #expect(result1.content == "first")
        #expect(result2.content == "second")
    }
    
    @Test("ResponseStream AsyncSequence protocol compliance")
    func responseStreamAsyncSequenceCompliance() async throws {
        var snapshots: [LanguageModelSession.ResponseStream<String>.Snapshot] = []
        
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            Task {
                for i in 0..<3 {
                    let content = "item-\(i)"
                    let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                        content: content,
                        rawContent: GeneratedContent(content)
                    )
                    continuation.yield(snapshot)
                }
                continuation.finish()
            }
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // Test AsyncSequence iteration
        for try await snapshot in responseStream {
            snapshots.append(snapshot)
        }
        
        #expect(snapshots.count == 3)
        #expect(snapshots[0].content == "item-0")
        #expect(snapshots[1].content == "item-1")
        #expect(snapshots[2].content == "item-2")
    }
    
    @Test("ResponseStream with PartiallyGenerated content")
    func responseStreamWithPartiallyGenerated() async throws {
        // Test that Snapshot correctly uses Content.PartiallyGenerated
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            Task {
                // For String, PartiallyGenerated = String
                let partialContent = "partial"
                let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: partialContent, // This is String (which is String.PartiallyGenerated)
                    rawContent: GeneratedContent(partialContent)
                )
                continuation.yield(snapshot)
                
                let completeContent = "complete"
                let completeSnapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: completeContent,
                    rawContent: GeneratedContent(completeContent)
                )
                continuation.yield(completeSnapshot)
                continuation.finish()
            }
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        var collectedSnapshots: [LanguageModelSession.ResponseStream<String>.Snapshot] = []
        for try await snapshot in responseStream {
            collectedSnapshots.append(snapshot)
        }
        
        #expect(collectedSnapshots.count == 2)
        #expect(collectedSnapshots[0].content == "partial")
        #expect(collectedSnapshots[1].content == "complete")
        
        // Test collect() which should return the final content
        let stream2 = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            Task {
                for content in ["p", "pa", "par", "partial", "partial-complete"] {
                    let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                        content: content,
                        rawContent: GeneratedContent(content)
                    )
                    continuation.yield(snapshot)
                }
                continuation.finish()
            }
        }
        
        let responseStream2 = LanguageModelSession.ResponseStream<String>(stream: stream2)
        let finalResponse = try await responseStream2.collect()
        
        // collect() should return the last complete value
        #expect(finalResponse.content == "partial-complete")
    }
}