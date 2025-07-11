// MockLanguageModelTests.swift
// OpenFoundationModels
//
// ✅ PHASE 4.3: Example usage of MockLanguageModel for testing

import Foundation

/// Example test cases demonstrating MockLanguageModel usage
/// 
/// ✅ PHASE 4.3: Shows how to use MockLanguageModel in tests
/// - Demonstrates structured response testing
/// - Shows streaming response testing
/// - Examples of error scenario testing
public struct MockLanguageModelTests {
    
    /// Example: Testing structured generation with mock responses
    /// ✅ PHASE 4.3: Demonstrates controllable responses
    public static func exampleStructuredGeneration() async throws {
        // Create mock model with predefined structured responses
        let mock = MockLanguageModel.withStructuredResponses()
        
        // Test username generation
        let userResponse = try await mock.generate(prompt: "Generate username", options: nil)
        print("User Response: \(userResponse)")
        
        // Test sentiment analysis
        let sentimentResponse = try await mock.generate(prompt: "Analyze sentiment", options: nil)
        print("Sentiment Response: \(sentimentResponse)")
        
        // Test content tagging
        let contentResponse = try await mock.generate(prompt: "Tag content", options: nil)
        print("Content Response: \(contentResponse)")
    }
    
    /// Example: Testing streaming responses
    /// ✅ PHASE 4.3: Demonstrates streaming behavior
    public static func exampleStreamingGeneration() async throws {
        let mock = MockLanguageModel.instant()
        
        print("Streaming response:")
        let stream = mock.stream(prompt: "Generate a long response", options: nil)
        
        for await chunk in stream {
            print("Chunk: \(chunk)")
        }
    }
    
    /// Example: Testing with custom responses
    /// ✅ PHASE 4.3: Demonstrates custom response mapping
    public static func exampleCustomResponses() async throws {
        let customResponses = [
            "hello": "Hello, world!",
            "goodbye": "Farewell!",
            "test": "This is a test response"
        ]
        
        let mock = MockLanguageModel(
            responses: customResponses,
            defaultResponse: "Default mock response",
            delay: 1_000_000 // 1ms delay
        )
        
        // Test exact matches
        let helloResponse = try await mock.generate(prompt: "hello", options: nil)
        print("Hello Response: \(helloResponse)")
        
        // Test partial matches
        let testResponse = try await mock.generate(prompt: "please test this", options: nil)
        print("Test Response: \(testResponse)")
        
        // Test default response
        let unknownResponse = try await mock.generate(prompt: "unknown prompt", options: nil)
        print("Unknown Response: \(unknownResponse)")
    }
    
    /// Example: Testing error scenarios
    /// ✅ PHASE 4.3: Demonstrates error handling
    public static func exampleErrorScenarios() async throws {
        let mock = MockLanguageModel.withErrors()
        
        // Test basic error response
        let errorResponse = try await mock.generate(prompt: "cause error", options: nil)
        print("Error Response: \(errorResponse)")
        
        // Test availability
        print("Mock Available: \(mock.isAvailable)")
        print("Mock Availability: \(mock.availability)")
        print("Supported Languages: \(mock.supportedLanguages)")
    }
}

// MARK: - Helper Extensions for Testing

public extension MockLanguageModel {
    
    /// Create mock model for UserProfile testing
    /// ✅ PHASE 4.3: Specific testing scenario
    static func forUserProfileTesting() -> MockLanguageModel {
        let responses = [
            "user": """
            {
                "username": "testuser123",
                "email": "testuser@example.com",
                "displayName": "Test User"
            }
            """,
            "profile": """
            {
                "username": "johndoe",
                "email": "john.doe@email.com",
                "displayName": "John Doe"
            }
            """
        ]
        
        return MockLanguageModel(
            responses: responses,
            defaultResponse: "Mock user profile",
            delay: 2_000_000 // 2ms
        )
    }
    
    /// Create mock model for ContentTagging testing
    /// ✅ PHASE 4.3: Specific testing scenario
    static func forContentTaggingTesting() -> MockLanguageModel {
        let responses = [
            "analyze": """
            {
                "actions": ["analyze", "categorize", "summarize"],
                "emotions": ["curiosity", "satisfaction", "excitement"],
                "objects": ["document", "text", "content"],
                "topics": ["AI", "machine learning", "testing"]
            }
            """,
            "tag": """
            {
                "actions": ["tag", "classify"],
                "emotions": ["neutral"],
                "objects": ["item", "element"],
                "topics": ["general", "unspecified"]
            }
            """
        ]
        
        return MockLanguageModel(
            responses: responses,
            defaultResponse: "Mock content tagging",
            delay: 3_000_000 // 3ms
        )
    }
}