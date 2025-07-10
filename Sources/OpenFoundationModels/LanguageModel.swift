import Foundation

/// Protocol defining the interface for language models
public protocol LanguageModel: Sendable {
    /// Generate a response for the given prompt
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - options: Generation options (optional)
    /// - Returns: The generated response as a string
    func generate(prompt: String, options: GenerationOptions?) async throws -> String
    
    /// Stream a response for the given prompt
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - options: Generation options (optional)
    /// - Returns: An async stream of partial responses
    func stream(prompt: String, options: GenerationOptions?) -> AsyncThrowingStream<String, Error>
    
    /// Check the availability of the model
    /// - Returns: The current availability status
    func availability() async -> AvailabilityStatus
    
    /// Check if the model supports a specific locale
    /// - Parameter locale: The locale to check
    /// - Returns: true if the locale is supported
    func supports(locale: Locale) -> Bool
}