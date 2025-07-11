// ContentTaggingExample.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification examples

import Foundation

/// Example implementation matching Apple's ContentTaggingResult
/// ✅ CONFIRMED: Structure from Apple documentation examples
@Generable(description: "Content tagging result with categorized tags")
public struct ContentTaggingResult: Generable, Codable {
    @Guide(
        description: "Most important actions in the input text",
        .maximumCount(3)
    )
    public let actions: [String]
    
    @Guide(
        description: "Most important emotions in the input text", 
        .maximumCount(3)
    )
    public let emotions: [String]
    
    @Guide(
        description: "Most important objects in the input text",
        .maximumCount(3)
    )
    public let objects: [String]
    
    @Guide(
        description: "Most important topics in the input text",
        .maximumCount(3)
    )
    public let topics: [String]
    
    public init(actions: [String], emotions: [String], objects: [String], topics: [String]) {
        self.actions = actions
        self.emotions = emotions
        self.objects = objects
        self.topics = topics
    }
}

/// Additional example with different guide types
@Generable(description: "User feedback analysis")
public struct FeedbackAnalysis: Generable, Codable {
    @Guide(description: "Overall sentiment score", .range(1...10))
    public let sentimentScore: Int
    
    @Guide(description: "Feedback category", .enumeration(["positive", "negative", "neutral", "mixed"]))
    public let category: String
    
    @Guide(description: "Key themes mentioned", .maximumCount(5))
    public let themes: [String]
    
    @Guide(description: "Confidence level", .range(0.0...1.0))
    public let confidence: Double
    
    public init(sentimentScore: Int, category: String, themes: [String], confidence: Double) {
        self.sentimentScore = sentimentScore
        self.category = category
        self.themes = themes
        self.confidence = confidence
    }
}

/// Example with pattern constraints for testing Phase 3.2
@Generable(description: "User profile with pattern constraints")
public struct UserProfile: Generable, Codable {
    @Guide(description: "Username must be alphanumeric", .pattern("^[a-zA-Z0-9_]{3,20}$"))
    public let username: String
    
    @Guide(description: "Email address", .pattern("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$"))
    public let email: String
    
    @Guide(description: "Display name", .maximumCount(50))
    public let displayName: String
    
    public init(username: String, email: String, displayName: String) {
        self.username = username
        self.email = email
        self.displayName = displayName
    }
}