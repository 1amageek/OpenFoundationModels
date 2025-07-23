// ToolOutputApple.swift
// OpenFoundationModels
//
// ✅ PHASE 4.6: Apple Foundation Models compliant ToolOutput structure
// Note: This is separate from the existing ToolOutput.swift to avoid conflicts

import Foundation

/// Output from a tool execution for Apple Foundation Models
/// 
/// ✅ APPLE SPEC: Tool output structure from Apple documentation
/// - Contains unique identifier for tracking
/// - Output in GeneratedContent format
/// - Codable for transcript serialization
public struct ToolOutputApple: Codable, Sendable {
    /// Unique identifier matching the tool call
    /// ✅ APPLE SPEC: Required for tracking tool execution
    public let id: String
    
    /// Output from the tool execution
    /// ✅ APPLE SPEC: Uses GeneratedContent format
    public let output: GeneratedContent
    
    /// Initialize tool output
    /// - Parameters:
    ///   - id: Unique identifier matching the tool call
    ///   - output: Tool output as GeneratedContent
    public init(id: String, output: GeneratedContent) {
        self.id = id
        self.output = output
    }
    
    /// Initialize tool output with string output
    /// - Parameters:
    ///   - id: Unique identifier matching the tool call
    ///   - output: Tool output as string
    public init(id: String, output: String) {
        self.id = id
        self.output = GeneratedContent(output)
    }
    
    /// Initialize tool output with encodable output
    /// - Parameters:
    ///   - id: Unique identifier matching the tool call
    ///   - output: Tool output as encodable object
    public init<T: Encodable>(id: String, output: T) throws {
        self.id = id
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(output)
        let jsonString = String(data: data, encoding: .utf8) ?? "{}"
        self.output = try GeneratedContent(json: jsonString)
    }
}

// MARK: - Convenience Methods

public extension ToolOutputApple {
    /// Decode output as a specific type
    /// - Parameter type: The type to decode output as
    /// - Returns: Decoded output
    /// - Throws: DecodingError if decoding fails
    func decodeOutput<T: Decodable>(as type: T.Type) throws -> T {
        // Convert GeneratedContent back to JSON data
        let jsonString = output.stringValue
        guard let data = jsonString.data(using: .utf8) else {
            throw ToolOutputError.invalidOutputFormat
        }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    /// Get output as a dictionary
    /// - Returns: Output as [String: Any] dictionary
    /// - Throws: Error if JSON parsing fails
    func outputDictionary() throws -> [String: Any] {
        // For GeneratedContent created from JSON, we need to reconstruct the dictionary
        let properties = try output.properties()
        var result: [String: Any] = [:]
        for (key, value) in properties {
            // Convert each GeneratedContent value to appropriate Swift type
            if let nestedProps = try? value.properties() {
                // Nested object
                result[key] = try convertToSwiftObject(value)
            } else if let elements = try? value.elements() {
                // Array
                result[key] = try elements.map { try convertToSwiftObject($0) }
            } else {
                // Simple value
                result[key] = value.stringValue
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
            return content.stringValue
        }
    }
}

// MARK: - Errors

public enum ToolOutputError: Error {
    case invalidOutputFormat
    case decodingFailed
    case encodingFailed
}

// MARK: - CustomStringConvertible

extension ToolOutputApple: CustomStringConvertible {
    public var description: String {
        return "ToolOutput(id: \(id), output: \(output.stringValue))"
    }
}