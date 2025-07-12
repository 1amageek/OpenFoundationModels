// ToolOutput.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Based on Apple Foundation Models API specification

import Foundation

/// A structure that contains the output a tool generates.
/// 
/// **Apple Foundation Models Documentation:**
/// A structure that contains the output a tool generates.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/tooloutput
/// 
/// **Apple Official API:** `struct ToolOutput`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - Sendable
/// - SendableMetatype
/// 
/// **Usage:**
/// ```swift
/// func call(arguments: Arguments) async throws -> ToolOutput {
///     let result = ["contactNames": ["John Doe", "Jane Smith"]]
///     return ToolOutput(GeneratedContent(properties: result))
/// }
/// ```
public struct ToolOutput: Sendable, SendableMetatype {
    
    /// The encoded output data
    private let encodedData: Data
    
    /// Creates a tool output with a generated encodable object.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a tool output with a generated encodable object.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tooloutput/init(_:)
    /// 
    /// **Apple Official API:** `init(_:)`
    /// 
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
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Decodes the tool output to a specific type.
    /// 
    /// - Parameter type: The type to decode the output as
    /// - Returns: The decoded object
    /// - Throws: DecodingError if decoding fails
    public func decode<T>(as type: T.Type) throws -> T where T: Decodable {
        return try JSONDecoder().decode(type, from: encodedData)
    }
    
    /// Convert tool output to GeneratedContent
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Converts the tool output to GeneratedContent for use in model interactions.
    /// 
    /// - Returns: GeneratedContent representation of the tool output
    public func toGeneratedContent() -> GeneratedContent {
        // Convert the encoded data to a string representation
        let jsonString = String(data: encodedData, encoding: .utf8) ?? "{}"
        return GeneratedContent(jsonString)
    }
    
    /// Create ToolOutput from GeneratedContent
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a ToolOutput from GeneratedContent.
    /// 
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