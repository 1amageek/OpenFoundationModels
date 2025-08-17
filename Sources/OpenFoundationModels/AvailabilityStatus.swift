import Foundation

public enum AvailabilityStatus: Sendable {
    case available
    case unavailable(UnavailabilityReason)
    
    public var isAvailable: Bool {
        switch self {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
}