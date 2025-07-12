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
        
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            for (index, value) in expectedValues.enumerated() {
                let isComplete = (index == expectedValues.count - 1)
                continuation.yield(Response<String>.Partial(
                    content: value,
                    isComplete: isComplete
                ))
            }
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // Test iteration through complete lifecycle
        for try await partial in responseStream {
            #expect(partial.content == expectedValues[valueIndex])
            #expect(partial.isComplete == (valueIndex == expectedValues.count - 1))
            valueIndex += 1
        }
        
        #expect(valueIndex == expectedValues.count)
    }
    
    @Test("Streaming with early termination on complete")
    func streamingWithEarlyTerminationOnComplete() async throws {
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "partial1", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "partial2", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "complete", isComplete: true))
            continuation.yield(Response<String>.Partial(content: "after complete", isComplete: false))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        var receivedValues: [String] = []
        
        // Test early termination when isComplete is reached
        for try await partial in responseStream {
            receivedValues.append(partial.content)
            if partial.isComplete {
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
            let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
                for i in 0..<count {
                    let isComplete = (i == count - 1)
                    continuation.yield(Response<String>.Partial(
                        content: "\(identifier)-\(i)",
                        isComplete: isComplete
                    ))
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
        
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "success1", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "success2", isComplete: false))
            continuation.finish(throwing: testError)
        }
        
        let responseStream = ResponseStream(stream: stream)
        var successfulPartials: [String] = []
        
        // Test error propagation preserves successful partials
        do {
            for try await partial in responseStream {
                successfulPartials.append(partial.content)
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
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            Task {
                // Immediate first partial
                continuation.yield(Response<String>.Partial(content: "immediate", isComplete: false))
                
                // Simulated delay
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                continuation.yield(Response<String>.Partial(content: "delayed", isComplete: false))
                
                // Final completion
                continuation.yield(Response<String>.Partial(content: "final", isComplete: true))
                continuation.finish()
            }
        }
        
        let responseStream = ResponseStream(stream: stream)
        var timestamps: [Date] = []
        var contents: [String] = []
        
        let startTime = Date()
        for try await partial in responseStream {
            timestamps.append(Date())
            contents.append(partial.content)
            if partial.isComplete {
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
        
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            for (content, isComplete) in expectedPartials {
                continuation.yield(Response<String>.Partial(
                    content: content,
                    isComplete: isComplete
                ))
            }
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // Test collectPartials() captures all intermediate states
        let allPartials = try await responseStream.collectPartials()
        
        #expect(allPartials.count == expectedPartials.count)
        for (index, partial) in allPartials.enumerated() {
            let expected = expectedPartials[index]
            #expect(partial.content == expected.0)
            #expect(partial.isComplete == expected.1)
        }
    }
    
    @Test("Streaming with empty content handling")
    func streamingWithEmptyContentHandling() async throws {
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "content", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "", isComplete: true))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
        // Test that empty content is handled correctly
        let finalResponse = try await responseStream.collect()
        #expect(finalResponse.content == "") // Last complete value was empty
    }
    
    @Test("Multiple iterator instances from same stream")
    func multipleIteratorInstancesFromSameStream() async throws {
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "first", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "second", isComplete: false))
            continuation.yield(Response<String>.Partial(content: "third", isComplete: true))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
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
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            continuation.yield(Response<String>.Partial(content: "sendable test", isComplete: true))
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        
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
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            for i in 0..<itemCount {
                let isComplete = (i == itemCount - 1)
                continuation.yield(Response<String>.Partial(
                    content: "item-\(i)",
                    isComplete: isComplete
                ))
            }
            continuation.finish()
        }
        
        let responseStream = ResponseStream(stream: stream)
        let startTime = Date()
        
        var processedCount = 0
        for try await partial in responseStream {
            processedCount += 1
            if partial.isComplete {
                break
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(processedCount == itemCount)
        #expect(duration < 1.0) // Should process 100 items quickly
    }
}