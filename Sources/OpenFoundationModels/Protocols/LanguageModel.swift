// LanguageModel.swift
// OpenFoundationModels
//
// ✅ TRANSCRIPT-BASED: Protocol for Transcript-centric language model interface

import Foundation

/// Protocol defining the interface for language models
/// 
/// ✅ APPLE SPEC: Transcript-based interface following Apple Foundation Models design
/// - Receives complete Transcript containing Instructions, Tools, and conversation history
/// - Stateless interface - all context provided via Transcript
/// - Supports both synchronous and streaming generation
/// - Model implementation decides how to interpret Transcript
public protocol LanguageModel: Sendable {
    
    /// Generate a response for the given transcript
    /// - Parameters:
    ///   - transcript: Complete conversation transcript including instructions, tools, and history
    ///   - options: Generation options (optional)
    /// - Returns: The generated response as a string
    func generate(transcript: Transcript, options: GenerationOptions?) async throws -> String
    
    /// Stream a response for the given transcript
    /// - Parameters:
    ///   - transcript: Complete conversation transcript including instructions, tools, and history
    ///   - options: Generation options (optional)
    /// - Returns: An async stream of partial responses
    func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncStream<String>
    
    /// Check if the model is available for use
    /// - Returns: true if the model is ready for requests
    var isAvailable: Bool { get }
    
    /// Check if the model supports a specific locale
    /// - Parameter locale: The locale to check
    /// - Returns: true if the locale is supported
    func supports(locale: Locale) -> Bool
}
