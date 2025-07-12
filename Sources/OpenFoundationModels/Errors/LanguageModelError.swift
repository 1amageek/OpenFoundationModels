import Foundation

/// Errors that can occur when using language models
public enum LanguageModelError: LocalizedError {
    /// The requested functionality is not yet implemented
    case notImplemented
    
    /// The context window size has been exceeded
    case exceededContextWindowSize
    
    /// The model is not available
    case modelUnavailable(AvailabilityStatus)
    
    /// Invalid input was provided
    case invalidInput(String)
    
    /// The model provider returned an error
    case providerError(String)
    
    /// Network error occurred
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This functionality is not yet implemented"
        case .exceededContextWindowSize:
            return "The context window size limit has been exceeded"
        case .modelUnavailable(let status):
            return "The model is unavailable: \(status)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .providerError(let message):
            return "Provider error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}