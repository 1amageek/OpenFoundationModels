import Testing
import Foundation
@testable import OpenFoundationModels

@Suite("Streaming Integration Tests", .tags(.streaming, .integration, .core))
struct StreamingIntegrationTests {
    
    @Test("Complete streaming lifecycle with String content")
    func completeStreamingLifecycleString() async throws {
        let expectedValues = ["Hello", "Hello, world", "Hello, world!"]
        var valueIndex = 0
        
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            for value in expectedValues {
                let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: value,
                    rawContent: GeneratedContent(value)
                )
                continuation.yield(snapshot)
            }
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        for try await snapshot in responseStream {
            #expect(snapshot.content == expectedValues[valueIndex])
            valueIndex += 1
        }
        
        #expect(valueIndex == expectedValues.count)
    }
    
    @Test("Streaming with early termination on complete")
    func streamingWithEarlyTerminationOnComplete() async throws {
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "partial1",
                rawContent: GeneratedContent("partial1")
            )
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "partial2",
                rawContent: GeneratedContent("partial2")
            )
            let snapshot3 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "complete",
                rawContent: GeneratedContent("complete")
            )
            let snapshot4 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "after complete",
                rawContent: GeneratedContent("after complete")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.yield(snapshot3)
            continuation.yield(snapshot4)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        var receivedValues: [String] = []
        
        for try await snapshot in responseStream {
            receivedValues.append(snapshot.content)
            if snapshot.content == "complete" {
                break
            }
        }
        
        #expect(receivedValues == ["partial1", "partial2", "complete"])
    }
    
    @Test("Concurrent streaming operations")
    func concurrentStreamingOperations() async throws {
        func createStringStream(identifier: String, count: Int) -> LanguageModelSession.ResponseStream<String> {
            let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
                for i in 0..<count {
                    let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                        content: "\(identifier)-\(i)",
                        rawContent: GeneratedContent("\(identifier)-\(i)")
                    )
                    continuation.yield(snapshot)
                }
                continuation.finish()
            }
            return LanguageModelSession.ResponseStream(stream: stream)
        }
        
        let stream1 = createStringStream(identifier: "A", count: 3)
        let stream2 = createStringStream(identifier: "B", count: 2)
        
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
        
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "success1",
                rawContent: GeneratedContent("success1")
            )
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "success2",
                rawContent: GeneratedContent("success2")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.finish(throwing: testError)
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        var successfulPartials: [String] = []
        
        do {
            for try await snapshot in responseStream {
                successfulPartials.append(snapshot.content)
            }
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as GenerationError {
            #expect(successfulPartials == ["success1", "success2"])
            if case .rateLimited = error {
            } else {
                #expect(Bool(false), "Wrong error type")
            }
        }
    }
    
    @Test("Streaming with timeout behavior simulation")
    func streamingWithTimeoutBehaviorSimulation() async throws {
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            Task {
                let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: "immediate",
                    rawContent: GeneratedContent("immediate")
                )
                continuation.yield(snapshot1)
                
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: "delayed",
                    rawContent: GeneratedContent("delayed")
                )
                continuation.yield(snapshot2)
                
                let snapshot3 = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: "final",
                    rawContent: GeneratedContent("final")
                )
                continuation.yield(snapshot3)
                continuation.finish()
            }
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        var timestamps: [Date] = []
        var contents: [String] = []
        
        let startTime = Date()
        for try await snapshot in responseStream {
            timestamps.append(Date())
            contents.append(snapshot.content)
            if snapshot.content == "final" {
                break
            }
        }
        
        #expect(contents == ["immediate", "delayed", "final"])
        #expect(timestamps.count == 3)
        
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
        
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            for (content, _) in expectedPartials {
                let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: content,
                    rawContent: GeneratedContent(content)
                )
                continuation.yield(snapshot)
            }
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        var allPartials: [String] = []
        for try await snapshot in responseStream {
            allPartials.append(snapshot.content)
        }
        
        #expect(allPartials.count == expectedPartials.count)
        for (index, partial) in allPartials.enumerated() {
            let expected = expectedPartials[index]
            #expect(partial == expected.0)
        }
    }
    
    @Test("Streaming with empty content handling")
    func streamingWithEmptyContentHandling() async throws {
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot1 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "",
                rawContent: GeneratedContent("")
            )
            let snapshot2 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "content",
                rawContent: GeneratedContent("content")
            )
            let snapshot3 = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "",
                rawContent: GeneratedContent("")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.yield(snapshot3)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        let finalResponse = try await responseStream.collect()
        #expect(finalResponse.content == "") // Last complete value was empty
    }
    
    @Test("Multiple iterator instances from same stream")
    func multipleIteratorInstancesFromSameStream() async throws {
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
                content: "third",
                rawContent: GeneratedContent("third")
            )
            continuation.yield(snapshot1)
            continuation.yield(snapshot2)
            continuation.yield(snapshot3)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        var iterator1 = responseStream.makeAsyncIterator()
        var iterator2 = responseStream.makeAsyncIterator()
        
        let first1 = try await iterator1.next()
        let first2 = try await iterator2.next()
        
        #expect(first1 != nil)
        #expect(first2 != nil)
    }
    
    @Test("Streaming integration without Sendable requirements")
    func streamingIntegrationWithoutSendableRequirements() async throws {
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                content: "non-sendable test",
                rawContent: GeneratedContent("non-sendable test")
            )
            continuation.yield(snapshot)
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        
        // Process directly without TaskGroup since ResponseStream is not Sendable
        let response = try await responseStream.collect()
        let result = response.content
        
        #expect(result == "non-sendable test")
    }
    
    @Test("Streaming pipeline performance characteristics")
    func streamingPipelinePerformanceCharacteristics() async throws {
        let itemCount = 100
        let stream = AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
            for i in 0..<itemCount {
                let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: "item-\(i)",
                    rawContent: GeneratedContent("item-\(i)")
                )
                continuation.yield(snapshot)
            }
            continuation.finish()
        }
        
        let responseStream = LanguageModelSession.ResponseStream<String>(stream: stream)
        let startTime = Date()
        
        var processedCount = 0
        for try await _ in responseStream {
            processedCount += 1
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(processedCount == itemCount)
        #expect(duration < 1.0) // Should process 100 items quickly
    }
}