import Foundation

/// Reasons why a language model might be unavailable
public enum UnavailabilityReason: Sendable {
    /// Apple Intelligence is not enabled on the device
    case appleIntelligenceNotEnabled
    
    /// The device does not support the language model
    case deviceNotSupported
    
    /// The device's battery level is too low
    case batteryLevelTooLow
    
    /// The requested locale is not supported
    case localeNotSupported
    
    /// The model is temporarily unavailable
    case temporarilyUnavailable
    
    /// A custom reason for unavailability
    case other(String)
}