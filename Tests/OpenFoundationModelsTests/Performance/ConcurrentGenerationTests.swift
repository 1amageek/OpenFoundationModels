import Testing
import Foundation
@testable import OpenFoundationModels



@Generable
struct TestSchemaType1 {
    @Guide(description: "Field A") let fieldA: String
    @Guide(description: "Field B") let fieldB: Int
}

@Generable
struct TestSchemaType2 {
    @Guide(description: "Field X") let fieldX: String
    @Guide(description: "Field Y") let fieldY: Double
}

@Generable
struct TestSchemaType3 {
    @Guide(description: "Field P") let fieldP: String
    @Guide(description: "Field Q") let fieldQ: Bool
}

@Generable
struct TestConcurrentTypeA {
    @Guide(description: "Name") let name: String
    @Guide(description: "Count") let count: Int
}

@Generable
struct TestConcurrentTypeB {
    @Guide(description: "Value") let value: String
    @Guide(description: "Score") let score: Double
}

@Generable
struct TestConcurrentTypeC {
    @Guide(description: "ID") let id: String
    @Guide(description: "Active") let active: Bool
}

@Generable
struct TestLoadTestType {
    @Guide(description: "ID") let id: String
    @Guide(description: "Data") let data: String
    @Guide(description: "Index") let index: Int
}

@Generable
struct TestSharedResourceType {
    @Guide(description: "Resource ID") let resourceId: String
    @Guide(description: "Access count") let accessCount: Int
    @Guide(description: "Timestamp") let timestamp: String
}

@Suite("Concurrent Generation Tests", .tags(.performance, .core, .integration))
struct ConcurrentGenerationTests {
    
    @Test("Concurrent response stream creation", .timeLimit(.minutes(1)))
    func concurrentResponseStreamCreation() async throws {
        let streamCount = 10
        let itemsPerStream = 5
        
        let streams = (0..<streamCount).map { streamIndex in
            AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
                Task {
                    for itemIndex in 0..<itemsPerStream {
                        let content = "stream-\(streamIndex)-item-\(itemIndex)"
                        let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                            content: content,
                            rawContent: GeneratedContent(content)
                        )
                        continuation.yield(snapshot)
                    }
                    continuation.finish()
                }
            }
        }
        
        let responseStreams = streams.map { LanguageModelSession.ResponseStream<String>(stream: $0) }
        
        let startTime = Date()
        
        let results = try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, stream) in responseStreams.enumerated() {
                group.addTask {
                    let response = try await stream.collect()
                    return (index, "Stream \(index): \(response.content)")
                }
            }
            
            var collectedResults: [(Int, String)] = []
            for try await result in group {
                collectedResults.append(result)
            }
            return collectedResults.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(results.count == streamCount)
        
        for (index, result) in results.enumerated() {
            let expectedFinalContent = "stream-\(index)-item-\(itemsPerStream - 1)"
            #expect(result.contains(expectedFinalContent))
        }
        
        #expect(totalTime < 5.0)
    }
    
    @Test("Concurrent schema generation", .timeLimit(.minutes(1)))
    func concurrentSchemaGeneration() async throws {
        let concurrencyLevel = 20
        let startTime = Date()
        
        let results = try await withThrowingTaskGroup(of: (String, String).self) { group in
            for i in 0..<concurrencyLevel {
                group.addTask {
                    let schema1 = TestSchemaType1.generationSchema
                    let schema2 = TestSchemaType2.generationSchema
                    let schema3 = TestSchemaType3.generationSchema
                    
                    return ("task-\(i)", "\(schema1.debugDescription)-\(schema2.debugDescription)-\(schema3.debugDescription)")
                }
            }
            
            var collectedResults: [(String, String)] = []
            for try await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(results.count == concurrencyLevel)
        
        for (taskId, schemaTypes) in results {
            #expect(taskId.hasPrefix("task-"))
            #expect(schemaTypes.contains("GenerationSchema"))
        }
        
        #expect(totalTime < 2.0)
    }
    
    @Test("Concurrent instance creation with different types", .timeLimit(.minutes(1)))
    func concurrentInstanceCreationWithDifferentTypes() async throws {
        let instancesPerType = 50
        let startTime = Date()
        
        let results = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<instancesPerType {
                group.addTask {
                    let instance = try TestConcurrentTypeA(GeneratedContent(json: "{}"))
                    return "A:\(instance.name):\(instance.count)"
                }
            }
            
            for _ in 0..<instancesPerType {
                group.addTask {
                    let instance = try TestConcurrentTypeB(GeneratedContent(json: "{}"))
                    return "B:\(instance.value):\(instance.score)"
                }
            }
            
            for _ in 0..<instancesPerType {
                group.addTask {
                    let instance = try TestConcurrentTypeC(GeneratedContent(json: "{}"))
                    return "C:\(instance.id):\(instance.active)"
                }
            }
            
            var collectedResults: [String] = []
            for try await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(results.count == instancesPerType * 3)
        
        let typeACounts = results.filter { $0.hasPrefix("A:") }.count
        let typeBCounts = results.filter { $0.hasPrefix("B:") }.count
        let typeCCounts = results.filter { $0.hasPrefix("C:") }.count
        
        #expect(typeACounts == instancesPerType)
        #expect(typeBCounts == instancesPerType)
        #expect(typeCCounts == instancesPerType)
        
        for result in results {
            if result.hasPrefix("A:") {
                #expect(result == "A::0") // Empty string and 0
            } else if result.hasPrefix("B:") {
                #expect(result == "B::0.0") // Empty string and 0.0
            } else if result.hasPrefix("C:") {
                #expect(result == "C::false") // Empty string and false
            }
        }
        
        #expect(totalTime < 1.0)
    }
    
    @Test("Concurrent streaming with error handling", .timeLimit(.minutes(1)))
    func concurrentStreamingWithErrorHandling() async throws {
        let successStreamCount = 5
        let errorStreamCount = 3
        
        let successStreams = (0..<successStreamCount).map { index in
            AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
                let content = "success-\(index)"
                let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: content,
                    rawContent: GeneratedContent(content)
                )
                continuation.yield(snapshot)
                continuation.finish()
            }
        }
        
        let errorStreams = (0..<errorStreamCount).map { index in
            AsyncThrowingStream<LanguageModelSession.ResponseStream<String>.Snapshot, Error> { continuation in
                let content = "partial-\(index)"
                let snapshot = LanguageModelSession.ResponseStream<String>.Snapshot(
                    content: content,
                    rawContent: GeneratedContent(content)
                )
                continuation.yield(snapshot)
                let error = GenerationError.rateLimited(
                    GenerationError.Context(debugDescription: "Concurrent test error \(index)")
                )
                continuation.finish(throwing: error)
            }
        }
        
        let allStreams = successStreams + errorStreams
        let responseStreams = allStreams.map { LanguageModelSession.ResponseStream<String>(stream: $0) }
        
        let startTime = Date()
        
        let results = try await withThrowingTaskGroup(of: Result<String, Error>.self) { group in
            for (index, stream) in responseStreams.enumerated() {
                group.addTask {
                    do {
                        let response = try await stream.collect()
                        return .success("Stream \(index): \(response.content)")
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            var collectedResults: [Result<String, Error>] = []
            for try await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(results.count == successStreamCount + errorStreamCount)
        
        let successes = results.compactMap { result -> String? in
            if case .success(let value) = result { return value }
            return nil
        }
        
        let failures = results.compactMap { result -> Error? in
            if case .failure(let error) = result { return error }
            return nil
        }
        
        #expect(successes.count == successStreamCount)
        #expect(failures.count == errorStreamCount)
        
        for error in failures {
            #expect(error is GenerationError)
        }
        
        #expect(totalTime < 2.0)
    }
    
    @Test("High-load concurrent operations", .timeLimit(.minutes(2)))
    func highLoadConcurrentOperations() async throws {
        let totalOperations = 200
        let batchSize = 20
        let startTime = Date()
        
        var allResults: [String] = []
        
        for batchStart in stride(from: 0, to: totalOperations, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, totalOperations)
            
            let batchResults = try await withThrowingTaskGroup(of: String.self) { group in
                for i in batchStart..<batchEnd {
                    group.addTask {
                        let schema = TestLoadTestType.generationSchema
                        let instance = try TestLoadTestType(GeneratedContent(json: "{}"))
                        
                        return "op-\(i):\(schema.debugDescription):\(instance.id):\(instance.index)"
                    }
                }
                
                var batchCollected: [String] = []
                for try await result in group {
                    batchCollected.append(result)
                }
                return batchCollected
            }
            
            allResults.append(contentsOf: batchResults)
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(allResults.count == totalOperations)
        
        for (_, result) in allResults.enumerated() {
            let parts = result.components(separatedBy: ":")
            #expect(parts.count >= 3)
            #expect(result.contains("GenerationSchema"))
        }
        
        #expect(totalTime < 10.0)
    }
    
    @Test("Resource contention test", .timeLimit(.minutes(1)))
    func resourceContentionTest() async throws {
        let concurrentAccesses = 100
        let startTime = Date()
        
        let results = try await withThrowingTaskGroup(of: (Int, String, String).self) { group in
            for i in 0..<concurrentAccesses {
                group.addTask {
                    let schema1 = TestSharedResourceType.generationSchema
                    let instance1 = try TestSharedResourceType(GeneratedContent(json: "{}"))
                    
                    let schema2 = TestSharedResourceType.generationSchema
                    let _ = try TestSharedResourceType(GeneratedContent(json: "{}"))
                    
                    let schemasMatch = (schema1.debugDescription == schema2.debugDescription)
                    
                    return (i, instance1.resourceId, schemasMatch ? "consistent" : "inconsistent")
                }
            }
            
            var collectedResults: [(Int, String, String)] = []
            for try await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(results.count == concurrentAccesses)
        
        for (_, resourceId, consistency) in results {
            #expect(resourceId == "") // Default empty string
            #expect(consistency == "consistent") // Schemas should be consistent
        }
        
        #expect(totalTime < 3.0)
    }
}