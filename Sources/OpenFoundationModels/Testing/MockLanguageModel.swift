// MockLanguageModel.swift
// OpenFoundationModels
//
// ✅ PHASE 4.3: Mock language model for testing

import Foundation

/// Mock language model for testing purposes
/// 
/// ✅ PHASE 4.3: Provides controllable responses for unit testing
/// - Simulates SystemLanguageModel behavior without actual AI
/// - Allows predefined responses for testing scenarios
/// - Supports both sync and async generation patterns
public final class MockLanguageModel: Observable, Sendable, SendableMetatype, Copyable {
    
    /// Predefined responses for specific prompts
    private let responses: [String: String]
    
    /// Default response when no specific response is configured
    private let defaultResponse: String
    
    /// Simulated delay for realistic testing
    private let delay: UInt64
    
    /// Initialize mock model with predefined responses
    /// - Parameters:
    ///   - responses: Dictionary mapping prompts to responses
    ///   - defaultResponse: Default response for unmatched prompts
    ///   - delay: Simulated delay in nanoseconds (default: 10ms)
    public init(
        responses: [String: String] = [:],
        defaultResponse: String = "Mock response",
        delay: UInt64 = 10_000_000 // 10ms default
    ) {
        self.responses = responses
        self.defaultResponse = defaultResponse
        self.delay = delay
    }
    
    /// Mock version of SystemLanguageModel availability
    public var isAvailable: Bool {
        return true // Mock is always available
    }
    
    /// Mock version of SystemLanguageModel availability details
    public var availability: MockAvailability {
        return .available
    }
    
    /// Mock supported languages
    public var supportedLanguages: Set<Locale.Language> {
        return [
            Locale.Language(identifier: "en"),
            Locale.Language(identifier: "es"),
            Locale.Language(identifier: "fr"),
            Locale.Language(identifier: "de"),
            Locale.Language(identifier: "ja"),
        ]
    }
    
    // MARK: - Generation Methods
    
    /// Generate text response from prompt
    /// ✅ PHASE 4.3: Mock implementation for testing
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - options: Generation options (ignored in mock)
    /// - Returns: Mock response string
    public func generate(prompt: String, options: GenerationOptions?) async throws -> String {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: delay)
        
        // Check for exact prompt matches first
        if let response = responses[prompt] {
            return response
        }
        
        // Check for partial matches
        for (key, value) in responses {
            if prompt.contains(key) {
                return value
            }
        }
        
        // Return default response with prompt context
        return "\(defaultResponse): \(prompt)"
    }
    
    /// Generate streaming text response
    /// ✅ PHASE 4.3: Mock streaming implementation
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - options: Generation options (ignored in mock)
    /// - Returns: AsyncStream of string chunks
    public func stream(prompt: String, options: GenerationOptions?) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                do {
                    let response = try await generate(prompt: prompt, options: options)
                    let chunks = response.chunked(into: 5) // Smaller chunks for testing
                    
                    for chunk in chunks {
                        try await Task.sleep(nanoseconds: delay / 2) // Faster streaming
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}

// MARK: - Mock Availability Types

/// Mock availability status for testing
public enum MockAvailability {
    case available
    case unavailable(MockUnavailableReason)
    
    /// Mock unavailable reasons
    public enum MockUnavailableReason {
        case testingDisabled
        case networkError
        case configurationError
    }
}

// MARK: - Convenience Initializers

public extension MockLanguageModel {
    
    /// Create mock model with structured data responses
    /// ✅ PHASE 4.3: Convenient testing setup for structured generation
    static func withStructuredResponses() -> MockLanguageModel {
        let responses = [
            "username": """
            {
                "username": "testuser",
                "email": "test@example.com",
                "displayName": "Test User"
            }
            """,
            "sentiment": """
            {
                "sentimentScore": 7,
                "category": "positive",
                "themes": ["helpful", "clear"],
                "confidence": 0.85
            }
            """,
            "content": """
            {
                "actions": ["read", "analyze"],
                "emotions": ["curiosity", "interest"],
                "objects": ["document", "text"],
                "topics": ["testing", "software"]
            }
            """
        ]
        
        return MockLanguageModel(
            responses: responses,
            defaultResponse: "Mock structured response",
            delay: 5_000_000 // 5ms for faster testing
        )
    }
    
    /// Create mock model for error testing
    /// ✅ PHASE 4.3: Testing error scenarios
    static func withErrors() -> MockLanguageModel {
        return MockLanguageModel(
            responses: [:],
            defaultResponse: "Error response",
            delay: 1_000_000 // 1ms for very fast testing
        )
    }
    
    /// Create mock model with instant responses
    /// ✅ PHASE 4.3: Testing without delays
    static func instant() -> MockLanguageModel {
        return MockLanguageModel(
            responses: [:],
            defaultResponse: "Instant response",
            delay: 0 // No delay
        )
    }
}