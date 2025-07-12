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
        self.output = GeneratedContent(data: data, contentType: .json)
    }
}

// MARK: - Convenience Methods

public extension ToolOutputApple {
    /// Decode output as a specific type
    /// - Parameter type: The type to decode output as
    /// - Returns: Decoded output
    /// - Throws: DecodingError if decoding fails
    func decodeOutput<T: Decodable>(as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: output.dataValue)
    }
    
    /// Get output as a dictionary
    /// - Returns: Output as [String: Any] dictionary
    /// - Throws: Error if JSON parsing fails
    func outputDictionary() throws -> [String: Any] {
        let data = output.dataValue
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ToolOutputError.invalidOutputFormat
        }
        return dict
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