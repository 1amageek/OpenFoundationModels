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
        let jsonString = String(data: data, encoding: .utf8) ?? "{}"
        self.arguments = try GeneratedContent(json: jsonString)
    }
}

// MARK: - Convenience Methods

public extension ToolCall {
    /// Decode arguments as a specific type
    /// - Parameter type: The type to decode arguments as
    /// - Returns: Decoded arguments
    /// - Throws: DecodingError if decoding fails
    func decodeArguments<T: Decodable>(as type: T.Type) throws -> T {
        // Convert GeneratedContent back to JSON data
        let jsonString = arguments.text
        guard let data = jsonString.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid arguments for tool '\(name)': Failed to convert arguments to data"
                )
            )
        }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    /// Get arguments as a dictionary
    /// - Returns: Arguments as [String: Any] dictionary
    /// - Throws: Error if JSON parsing fails
    func argumentsDictionary() throws -> [String: Any] {
        // For GeneratedContent created from JSON, we need to reconstruct the dictionary
        let properties = try arguments.properties()
        var result: [String: Any] = [:]
        for (key, value) in properties {
            // Convert each GeneratedContent value to appropriate Swift type
            if (try? value.properties()) != nil {
                // Nested object
                result[key] = try convertToSwiftObject(value)
            } else if let elements = try? value.elements() {
                // Array
                result[key] = try elements.map { try convertToSwiftObject($0) }
            } else {
                // Simple value
                result[key] = value.text
            }
        }
        return result
    }
    
    /// Helper to convert GeneratedContent to Swift object
    private func convertToSwiftObject(_ content: GeneratedContent) throws -> Any {
        if let properties = try? content.properties() {
            var dict: [String: Any] = [:]
            for (key, value) in properties {
                dict[key] = try convertToSwiftObject(value)
            }
            return dict
        } else if let elements = try? content.elements() {
            return try elements.map { try convertToSwiftObject($0) }
        } else {
            return content.text
        }
    }
}


// MARK: - CustomStringConvertible

extension ToolCall: CustomStringConvertible {
    public var description: String {
        return "ToolCall(id: \(id), name: \(name), arguments: \(arguments.text))"
    }
}