import Foundation

/// System-level instructions that guide the model's behavior
public struct Instructions: Sendable {
    /// The instruction text
    public let text: String
    
    /// Priority level of these instructions
    public let priority: Priority
    
    /// Initialize instructions
    /// - Parameters:
    ///   - text: The instruction text
    ///   - priority: The priority level (default: .normal)
    public init(_ text: String, priority: Priority = .normal) {
        self.text = text
        self.priority = priority
    }
    
    /// Priority levels for instructions
    public enum Priority: Int, Sendable {
        case low = 0
        case normal = 1
        case high = 2
    }
}

// MARK: - ExpressibleByStringLiteral
extension Instructions: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}