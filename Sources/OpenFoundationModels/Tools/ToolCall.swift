// ToolCall.swift
// OpenFoundationModels
//
// ✅ PHASE 4.6: Apple Foundation Models compliant ToolCall structure

import Foundation

/// A single tool call made by the model
/// 
/// ✅ APPLE SPEC: Tool call structure from Apple documentation
/// - Contains unique identifier for tracking
/// - Tool name and arguments in GeneratedContent format
/// - Codable for transcript serialization
public struct ToolCall: Codable, Sendable {
    /// Unique identifier for this tool call
    /// ✅ APPLE SPEC: Required for tracking tool execution
    public let id: String
    
    /// Name of the tool being called
    /// ✅ APPLE SPEC: Must match Tool.name
    public let name: String
    
    /// Arguments for the tool call
    /// ✅ APPLE SPEC: Uses GeneratedContent format
    public let arguments: GeneratedContent
    
    /// Initialize a tool call
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - name: Tool name
    ///   - arguments: Tool arguments as GeneratedContent
    public init(id: String = UUID().uuidString, name: String, arguments: GeneratedContent) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
    
    /// Initialize a tool call with string arguments
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - name: Tool name
    ///   - arguments: Tool arguments as JSON string
    public init(id: String = UUID().uuidString, name: String, arguments: String) {
        self.id = id
        self.name = name
        self.arguments = GeneratedContent(arguments)
    }
    
    /// Initialize a tool call with encodable arguments
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - name: Tool name
    ///   - arguments: Tool arguments as encodable object
    public init<T: Encodable>(id: String = UUID().uuidString, name: String, arguments: T) throws {
        self.id = id
        self.name = name
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(arguments)
        self.arguments = GeneratedContent(data: data, contentType: .json)
    }
}

// MARK: - Convenience Methods

public extension ToolCall {
    /// Decode arguments as a specific type
    /// - Parameter type: The type to decode arguments as
    /// - Returns: Decoded arguments
    /// - Throws: DecodingError if decoding fails
    func decodeArguments<T: Decodable>(as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: arguments.dataValue)
    }
    
    /// Get arguments as a dictionary
    /// - Returns: Arguments as [String: Any] dictionary
    /// - Throws: Error if JSON parsing fails
    func argumentsDictionary() throws -> [String: Any] {
        let data = arguments.dataValue
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ToolCallError.invalidArguments(
                toolName: "unknown",
                reason: "Arguments must be a valid JSON object"
            )
        }
        return dict
    }
}

// MARK: - Legacy Errors (deprecated)

// Note: ToolCallError is now defined in Foundation/ToolCallError.swift
// This enum is kept for backward compatibility

// MARK: - CustomStringConvertible

extension ToolCall: CustomStringConvertible {
    public var description: String {
        return "ToolCall(id: \(id), name: \(name), arguments: \(arguments.stringValue))"
    }
}