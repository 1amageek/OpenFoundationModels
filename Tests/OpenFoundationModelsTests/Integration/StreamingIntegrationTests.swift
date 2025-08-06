import Testing
import Foundation
@testable import OpenFoundationModels

/// Tests for streaming integration workflows
/// 
/// **Focus:** Validates full streaming pipeline validation including ResponseStream,
/// partial response handling, error propagation, and complete workflows that integrate
/// multiple components according to Apple's Foundation Models specification.
///
/// **Apple Foundation Models Documentation:**
/// Streaming integration tests validate the complete pipeline from initiation through
/// progressive partial updates to final completion, ensuring robust error handling
/// and proper resource management throughout the streaming lifecycle.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/responsestream
@Suite("Streaming Integration Tests", .tags(.streaming, .integration, .core))
struct StreamingIntegrationTests {
    
    @Test("Complete streaming lifecycle with String content")
    func completeStreamingLifecycleString() async throws {
        // Test complete streaming workflow with String content
        let expectedValues = ["Hello", "Hello, world", "Hello, world!"]
        var valueIndex = 0
        
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            for (index, value) in expectedValues.enumerated() {
                // String.PartiallyGenerated = String (default)
                continuation.yield(value)
            }
            continuation.finish()
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        
        // Test iteration through complete lifecycle
        for try await partial in responseStream {
            // partial is now String (String.PartiallyGenerated = String)
            #expect(partial == expectedValues[valueIndex])
            // For String, we don't have isComplete tracking in streaming
            valueIndex += 1
        }
        
        #expect(valueIndex == expectedValues.count)
    }
    
    @Test("Streaming with early termination on complete")
    func streamingWithEarlyTerminationOnComplete() async throws {
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            // String.PartiallyGenerated = String (default)
            continuation.yield("partial1")
            continuation.yield("partial2")
            continuation.yield("complete")
            continuation.yield("after complete")
            continuation.finish()
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        var receivedValues: [String] = []
        
        // Test early termination when isComplete is reached
        for try await partial in responseStream {
            // partial is now String
            receivedValues.append(partial)
            // For String streaming, we need a different completion strategy
            if partial == "complete" {
                break
            }
        }
        
        // Should have stopped at "complete", not processed "after complete"
        #expect(receivedValues == ["partial1", "partial2", "complete"])
    }
    
    @Test("Concurrent streaming operations")
    func concurrentStreamingOperations() async throws {
        // Test multiple concurrent streaming operations
        func createStringStream(identifier: String, count: Int) -> ResponseStream<String> {
            let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
                for i in 0..<count {
                    continuation.yield("\(identifier)-\(i)")
                }
                continuation.finish()
            }
            return ResponseStream(stream: stream)
        }
        
        let stream1 = createStringStream(identifier: "A", count: 3)
        let stream2 = createStringStream(identifier: "B", count: 2)
        
        // Test concurrent collection
        async let result1 = stream1.collect()
        async let result2 = stream2.collect()
        
        let (response1, response2) = try await (result1, result2)
        
        #expect(response1.content == "A-2") // Last value from stream1
        #expect(response2.content == "B-1") // Last value from stream2
    }
    
    @Test("Streaming error recovery and propagation")
    func streamingErrorRecoveryAndPropagation() async throws {
        let testError = GenerationError.rateLimited(
            GenerationError.Context(debugDescription: "Rate limited during streaming")
        )
        
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            continuation.yield("success1")
            continuation.yield("success2")
            continuation.finish(throwing: testError)
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        var successfulPartials: [String] = []
        
        // Test error propagation preserves successful partials
        do {
            for try await partial in responseStream {
                // partial is now String
                successfulPartials.append(partial)
            }
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as GenerationError {
            #expect(successfulPartials == ["success1", "success2"])
            if case .rateLimited = error {
                // Expected error type
            } else {
                #expect(Bool(false), "Wrong error type")
            }
        }
    }
    
    @Test("Streaming with timeout behavior simulation")
    func streamingWithTimeoutBehaviorSimulation() async throws {
        // Simulate timeout scenario with delayed streaming
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            Task {
                // Immediate first partial
                continuation.yield("immediate")
                
                // Simulated delay
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                continuation.yield("delayed")
                
                // Final completion
                continuation.yield("final")
                continuation.finish()
            }
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        var timestamps: [Date] = []
        var contents: [String] = []
        
        let startTime = Date()
        for try await partial in responseStream {
            timestamps.append(Date())
            // partial is now String
            contents.append(partial)
            // Check for final content
            if partial == "final" {
                break
            }
        }
        
        #expect(contents == ["immediate", "delayed", "final"])
        #expect(timestamps.count == 3)
        
        // Verify timing (immediate should be much faster than delayed)
        let immediateTime = timestamps[0].timeIntervalSince(startTime)
        let delayedTime = timestamps[1].timeIntervalSince(startTime)
        #expect(delayedTime > immediateTime)
    }
    
    @Test("Streaming collectPartials() complete workflow")
    func streamingCollectPartialsCompleteWorkflow() async throws {
        let expectedPartials = [
            ("Loading...", false),
            ("Processing data...", false),
            ("Almost done...", false),
            ("Complete!", true)
        ]
        
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            for (content, _) in expectedPartials {
                continuation.yield(content)
            }
            continuation.finish()
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        
        // Test collectPartials() captures all intermediate states
        let allPartials = try await responseStream.collectPartials()
        
        #expect(allPartials.count == expectedPartials.count)
        for (index, partial) in allPartials.enumerated() {
            let expected = expectedPartials[index]
            // partial is now String
            #expect(partial == expected.0)
            // isComplete tracking not available for String
        }
    }
    
    @Test("Streaming with empty content handling")
    func streamingWithEmptyContentHandling() async throws {
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            continuation.yield("")
            continuation.yield("content")
            continuation.yield("")
            continuation.finish()
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        
        // Test that empty content is handled correctly
        let finalResponse = try await responseStream.collect()
        #expect(finalResponse.content == "") // Last complete value was empty
    }
    
    @Test("Multiple iterator instances from same stream")
    func multipleIteratorInstancesFromSameStream() async throws {
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            continuation.yield("first")
            continuation.yield("second")
            continuation.yield("third")
            continuation.finish()
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        
        // Test multiple iterators (though they'll share the same underlying stream)
        var iterator1 = responseStream.makeAsyncIterator()
        var iterator2 = responseStream.makeAsyncIterator()
        
        let first1 = try await iterator1.next()
        let first2 = try await iterator2.next()
        
        // Both should get the first element (or subsequent elements)
        #expect(first1 != nil)
        #expect(first2 != nil)
    }
    
    @Test("Streaming integration with Sendable requirements")
    func streamingIntegrationWithSendableRequirements() async throws {
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            continuation.yield("sendable test")
            continuation.finish()
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        
        // Test Sendable conformance in Task context
        let result = await withTaskGroup(of: String.self) { group in
            group.addTask {
                do {
                    let response = try await responseStream.collect()
                    return response.content
                } catch {
                    return "error"
                }
            }
            
            guard let result = await group.next() else {
                return "no result"
            }
            return result
        }
        
        #expect(result == "sendable test")
    }
    
    @Test("Streaming pipeline performance characteristics")
    func streamingPipelinePerformanceCharacteristics() async throws {
        let itemCount = 100
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            for i in 0..<itemCount {
                continuation.yield("item-\(i)")
            }
            continuation.finish()
        }
        
        let responseStream = ResponseStream<String>(stream: stream)
        let startTime = Date()
        
        var processedCount = 0
        for try await partial in responseStream {
            processedCount += 1
            // For String, we need to track completion differently
            // Since we're just counting items, we can continue until the stream ends
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(processedCount == itemCount)
        #expect(duration < 1.0) // Should process 100 items quickly
    }
}