import Foundation

/// Represents the availability status of a language model
public enum AvailabilityStatus: Sendable {
    /// The model is available for use
    case available
    
    /// The model is unavailable with a specific reason
    case unavailable(reason: UnavailabilityReason)
    
    /// Convenience property to check if the model is available
    public var isAvailable: Bool {
        switch self {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
}