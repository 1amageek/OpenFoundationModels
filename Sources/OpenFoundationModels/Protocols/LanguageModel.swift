// LanguageModel.swift
// OpenFoundationModels
//
// ✅ PHASE 4.1: Protocol abstraction for dependency injection and testing

import Foundation

/// Protocol defining the interface for language models
/// 
/// ✅ APPLE SPEC: Common interface for SystemLanguageModel, MockLanguageModel, etc.
/// - Supports both synchronous and streaming generation
/// - Provides availability and capability checking
/// - Enables dependency injection for testing
public protocol LanguageModel: Sendable {
    /// Generate a response for the given prompt
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - options: Generation options (optional)
    ///   - tools: Available tools for function calling (optional)
    /// - Returns: The generated response as a string
    func generate(prompt: String, options: GenerationOptions?, tools: [any Tool]?) async throws -> String
    
    /// Stream a response for the given prompt
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - options: Generation options (optional)
    ///   - tools: Available tools for function calling (optional)
    /// - Returns: An async stream of partial responses
    func stream(prompt: String, options: GenerationOptions?, tools: [any Tool]?) -> AsyncStream<String>
    
    /// Check if the model is available for use
    /// - Returns: true if the model is ready for requests
    var isAvailable: Bool { get }
    
    /// Check if the model supports a specific locale
    /// - Parameter locale: The locale to check
    /// - Returns: true if the locale is supported
    func supports(locale: Locale) -> Bool
}

// MARK: - Default Implementations

public extension LanguageModel {
    /// Default locale support check
    /// - Parameter locale: The locale to check
    /// - Returns: true for English, false for others (override for specific support)
    func supports(locale: Locale) -> Bool {
        return locale.identifier.hasPrefix("en")
    }
}