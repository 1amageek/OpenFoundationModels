import Testing
import Foundation
@testable import OpenFoundationModels

/// Tests for concurrent generation operations under load
/// 
/// **Focus:** Validates system behavior when multiple generation operations
/// run concurrently, testing thread safety, resource contention, and
/// performance characteristics according to Apple's Foundation Models specification.
///
/// **Apple Foundation Models Documentation:**
/// Concurrent generation tests ensure that multiple language model sessions
/// can operate simultaneously without conflicts, maintaining thread safety
/// and acceptable performance under load.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession
@Suite("Concurrent Generation Tests", .tags(.performance, .core, .integration))
struct ConcurrentGenerationTests {
    
    @Test("Concurrent response stream creation", .timeLimit(.minutes(1)))
    func concurrentResponseStreamCreation() async throws {
        let streamCount = 10
        let itemsPerStream = 5
        
        // Create multiple concurrent streams
        let streams = (0..<streamCount).map { streamIndex in
            AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
                Task {
                    for itemIndex in 0..<itemsPerStream {
                        let isComplete = (itemIndex == itemsPerStream - 1)
                        continuation.yield(Response<String>.Partial(
                            content: "stream-\(streamIndex)-item-\(itemIndex)",
                            isComplete: isComplete
                        ))
                    }
                    continuation.finish()
                }
            }
        }
        
        let responseStreams = streams.map { ResponseStream(stream: $0) }
        
        let startTime = Date()
        
        // Process all streams concurrently
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
        
        // Verify all streams completed
        #expect(results.count == streamCount)
        
        // Verify each stream produced the expected final content
        for (index, result) in results.enumerated() {
            let expectedFinalContent = "stream-\(index)-item-\(itemsPerStream - 1)"
            #expect(result.contains(expectedFinalContent))
        }
        
        // Performance check - concurrent should be reasonably fast
        #expect(totalTime < 5.0)
    }
    
    @Test("Concurrent schema generation", .timeLimit(.minutes(1)))
    func concurrentSchemaGeneration() async throws {
        // Define multiple schema types
        @Generable
        struct SchemaType1 {
            @Guide(description: "Field A") let fieldA: String
            @Guide(description: "Field B") let fieldB: Int
        }
        
        @Generable
        struct SchemaType2 {
            @Guide(description: "Field X") let fieldX: String
            @Guide(description: "Field Y") let fieldY: Double
        }
        
        @Generable
        struct SchemaType3 {
            @Guide(description: "Field P") let fieldP: String
            @Guide(description: "Field Q") let fieldQ: Bool
        }
        
        let concurrencyLevel = 20
        let startTime = Date()
        
        // Generate schemas concurrently
        let results = try await withThrowingTaskGroup(of: (String, String).self) { group in
            for i in 0..<concurrencyLevel {
                group.addTask {
                    let schema1 = SchemaType1.generationSchema
                    let schema2 = SchemaType2.generationSchema
                    let schema3 = SchemaType3.generationSchema
                    
                    return ("task-\(i)", "\(schema1.type)-\(schema2.type)-\(schema3.type)")
                }
            }
            
            var collectedResults: [(String, String)] = []
            for try await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Verify all tasks completed
        #expect(results.count == concurrencyLevel)
        
        // Verify all schemas were generated correctly
        for (taskId, schemaTypes) in results {
            #expect(taskId.hasPrefix("task-"))
            #expect(schemaTypes == "object-object-object")
        }
        
        // Performance check
        #expect(totalTime < 2.0)
    }
    
    @Test("Concurrent instance creation with different types", .timeLimit(.minutes(1)))
    func concurrentInstanceCreationWithDifferentTypes() async throws {
        @Generable
        struct TypeA {
            @Guide(description: "Name") let name: String
            @Guide(description: "Count") let count: Int
        }
        
        @Generable
        struct TypeB {
            @Guide(description: "Value") let value: String
            @Guide(description: "Score") let score: Double
        }
        
        @Generable
        struct TypeC {
            @Guide(description: "ID") let id: String
            @Guide(description: "Active") let active: Bool
        }
        
        let instancesPerType = 50
        let startTime = Date()
        
        // Create instances concurrently
        let results = try await withThrowingTaskGroup(of: String.self) { group in
            // Type A instances
            for i in 0..<instancesPerType {
                group.addTask {
                    let instance = try TypeA(GeneratedContent("{}"))
                    return "A:\(instance.name):\(instance.count)"
                }
            }
            
            // Type B instances
            for i in 0..<instancesPerType {
                group.addTask {
                    let instance = try TypeB(GeneratedContent("{}"))
                    return "B:\(instance.value):\(instance.score)"
                }
            }
            
            // Type C instances
            for i in 0..<instancesPerType {
                group.addTask {
                    let instance = try TypeC(GeneratedContent("{}"))
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
        
        // Verify all instances were created
        #expect(results.count == instancesPerType * 3)
        
        // Count instances by type
        let typeACounts = results.filter { $0.hasPrefix("A:") }.count
        let typeBCounts = results.filter { $0.hasPrefix("B:") }.count
        let typeCCounts = results.filter { $0.hasPrefix("C:") }.count
        
        #expect(typeACounts == instancesPerType)
        #expect(typeBCounts == instancesPerType)
        #expect(typeCCounts == instancesPerType)
        
        // Verify default values
        for result in results {
            if result.hasPrefix("A:") {
                #expect(result == "A::0") // Empty string and 0
            } else if result.hasPrefix("B:") {
                #expect(result == "B::0.0") // Empty string and 0.0
            } else if result.hasPrefix("C:") {
                #expect(result == "C::false") // Empty string and false
            }
        }
        
        // Performance check
        #expect(totalTime < 1.0)
    }
    
    @Test("Concurrent streaming with error handling", .timeLimit(.minutes(1)))
    func concurrentStreamingWithErrorHandling() async throws {
        let successStreamCount = 5
        let errorStreamCount = 3
        
        // Create successful streams
        let successStreams = (0..<successStreamCount).map { index in
            AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
                continuation.yield(Response<String>.Partial(content: "success-\(index)", isComplete: true))
                continuation.finish()
            }
        }
        
        // Create error streams
        let errorStreams = (0..<errorStreamCount).map { index in
            AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
                continuation.yield(Response<String>.Partial(content: "partial-\(index)", isComplete: false))
                let error = GenerationError.rateLimited(
                    GenerationError.Context(debugDescription: "Concurrent test error \(index)")
                )
                continuation.finish(throwing: error)
            }
        }
        
        let allStreams = successStreams + errorStreams
        let responseStreams = allStreams.map { ResponseStream(stream: $0) }
        
        let startTime = Date()
        
        // Process streams concurrently with error handling
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
        
        // Verify all streams were processed
        #expect(results.count == successStreamCount + errorStreamCount)
        
        // Count successes and failures
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
        
        // Verify error types
        for error in failures {
            #expect(error is GenerationError)
        }
        
        // Performance check
        #expect(totalTime < 2.0)
    }
    
    @Test("High-load concurrent operations", .timeLimit(.minutes(2)))
    func highLoadConcurrentOperations() async throws {
        @Generable
        struct LoadTestType {
            @Guide(description: "ID") let id: String
            @Guide(description: "Data") let data: String
            @Guide(description: "Index") let index: Int
        }
        
        let totalOperations = 200
        let batchSize = 20
        let startTime = Date()
        
        // Process operations in batches to avoid overwhelming the system
        var allResults: [String] = []
        
        for batchStart in stride(from: 0, to: totalOperations, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, totalOperations)
            
            let batchResults = try await withThrowingTaskGroup(of: String.self) { group in
                for i in batchStart..<batchEnd {
                    group.addTask {
                        // Mix of operations: schema access and instance creation
                        let schema = LoadTestType.generationSchema
                        let instance = try LoadTestType(GeneratedContent("{}"))
                        
                        return "op-\(i):\(schema.type):\(instance.id):\(instance.index)"
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
        
        // Verify all operations completed
        #expect(allResults.count == totalOperations)
        
        // Verify operation results
        for (_, result) in allResults.enumerated() {
            let parts = result.components(separatedBy: ":")
            #expect(parts.count == 4)
            #expect(parts[1] == "object") // Schema type
            #expect(parts[2] == "") // Empty ID (default value)
            #expect(parts[3] == "0") // Default index value
        }
        
        // Performance check - should handle high load efficiently
        #expect(totalTime < 10.0)
    }
    
    @Test("Resource contention test", .timeLimit(.minutes(1)))
    func resourceContentionTest() async throws {
        @Generable
        struct SharedResourceType {
            @Guide(description: "Resource ID") let resourceId: String
            @Guide(description: "Access count") let accessCount: Int
            @Guide(description: "Timestamp") let timestamp: String
        }
        
        let concurrentAccesses = 100
        let startTime = Date()
        
        // Test concurrent access to the same schema and type
        let results = try await withThrowingTaskGroup(of: (Int, String, String).self) { group in
            for i in 0..<concurrentAccesses {
                group.addTask {
                    // Multiple operations on the same type to test resource contention
                    let schema1 = SharedResourceType.generationSchema
                    let instance1 = try SharedResourceType(GeneratedContent("{}"))
                    
                    let schema2 = SharedResourceType.generationSchema
                    let _ = try SharedResourceType(GeneratedContent("{}"))
                    
                    // Verify schemas are consistent
                    let schemasMatch = (schema1.type == schema2.type)
                    
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
        
        // Verify all operations completed
        #expect(results.count == concurrentAccesses)
        
        // Verify consistency under contention
        for (_, resourceId, consistency) in results {
            #expect(resourceId == "") // Default empty string
            #expect(consistency == "consistent") // Schemas should be consistent
        }
        
        // Performance check
        #expect(totalTime < 3.0)
    }
}