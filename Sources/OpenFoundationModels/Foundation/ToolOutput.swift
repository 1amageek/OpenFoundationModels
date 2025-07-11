// ToolOutput.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// Structure that contains output a tool generates
/// 
/// ✅ CONFIRMED: From Apple Developer Documentation
/// - Single initializer that takes any Encodable object
/// - Conforms to Sendable and SendableMetatype
public struct ToolOutput: Sendable, SendableMetatype {
    
    /// The encoded output data
    private let encodedData: Data
    
    /// Create tool output with generated encodable object
    /// ✅ CONFIRMED: Generic initializer from Apple docs
    /// - Parameter object: Any encodable object to wrap as tool output
    public init<T>(_ object: T) where T : Encodable {
        do {
            self.encodedData = try JSONEncoder().encode(object)
        } catch {
            // Implementation needed - handle encoding failure
            self.encodedData = Data()
        }
    }
    
    /// Access the output as a specific decodable type
    /// - Parameter type: The type to decode the output as
    /// - Returns: The decoded object
    /// - Throws: DecodingError if decoding fails
    public func decode<T>(as type: T.Type) throws -> T where T: Decodable {
        return try JSONDecoder().decode(type, from: encodedData)
    }
    
    /// Convert tool output to GeneratedContent
    /// ✅ PHASE 4.2: Add GeneratedContent support to ToolOutput
    /// - Returns: GeneratedContent representation of the tool output
    public func toGeneratedContent() -> GeneratedContent {
        // Convert the encoded data to a string representation
        let jsonString = String(data: encodedData, encoding: .utf8) ?? "{}"
        return GeneratedContent(jsonString)
    }
    
    /// Create ToolOutput from GeneratedContent
    /// ✅ PHASE 4.2: Add GeneratedContent support to ToolOutput
    /// - Parameter content: GeneratedContent to convert
    /// - Returns: ToolOutput instance
    public static func from(generatedContent: GeneratedContent) -> ToolOutput {
        // Create a simple wrapper structure for the generated content
        let wrapper = GeneratedContentWrapper(content: generatedContent.stringValue)
        return ToolOutput(wrapper)
    }
}

// MARK: - Supporting Types

/// Wrapper for GeneratedContent when creating ToolOutput
private struct GeneratedContentWrapper: Codable {
    let content: String
}

// MARK: - Protocol Conformances
extension ToolOutput: CustomStringConvertible {
    public var description: String {
        return String(data: encodedData, encoding: .utf8) ?? "ToolOutput(invalid data)"
    }
}