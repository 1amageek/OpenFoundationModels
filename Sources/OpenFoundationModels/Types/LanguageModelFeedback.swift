// LanguageModelFeedback.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Based on Apple Foundation Models API specification

import Foundation

/// Feedback appropriate for attaching to Feedback Assistant.
/// 
/// **Apple Foundation Models Documentation:**
/// Feedback appropriate for attaching to Feedback Assistant.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback
/// 
/// **Apple Official API:** `struct LanguageModelFeedback`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
public struct LanguageModelFeedback: Sendable {
    /// The prompt that was submitted
    public let prompt: String
    
    /// The response that was generated
    public let response: String
    
    /// The model that was used
    public let model: String
    
    /// Additional context or notes
    public let context: String?
    
    /// Timestamp of the interaction
    public let timestamp: Date
    
    /// Creates a new feedback instance
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates feedback appropriate for attaching to Feedback Assistant.
    /// 
    /// - Parameters:
    ///   - prompt: The prompt that was submitted
    ///   - response: The response that was generated
    ///   - model: The model that was used
    ///   - context: Additional context or notes
    ///   - timestamp: Timestamp of the interaction
    public init(
        prompt: String,
        response: String,
        model: String = "SystemLanguageModel",
        context: String? = nil,
        timestamp: Date = Date()
    ) {
        self.prompt = prompt
        self.response = response
        self.model = model
        self.context = context
        self.timestamp = timestamp
    }
}

// MARK: - Codable Support

extension LanguageModelFeedback: Codable {
    /// Coding keys for LanguageModelFeedback
    private enum CodingKeys: String, CodingKey {
        case prompt
        case response
        case model
        case context
        case timestamp
    }
}

// MARK: - Equatable

extension LanguageModelFeedback: Equatable {}

// MARK: - Hashable

extension LanguageModelFeedback: Hashable {}

// MARK: - CustomStringConvertible

extension LanguageModelFeedback: CustomStringConvertible {
    /// A textual representation of this instance.
    public var description: String {
        var parts = [
            "Model: \(model)",
            "Prompt: \(prompt)",
            "Response: \(response)",
            "Timestamp: \(timestamp)"
        ]
        
        if let context = context {
            parts.append("Context: \(context)")
        }
        
        return parts.joined(separator: "\n")
    }
}