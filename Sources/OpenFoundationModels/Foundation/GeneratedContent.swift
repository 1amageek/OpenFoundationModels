// GeneratedContent.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Required by Apple Foundation Models API

import Foundation

/// Core content type for the Foundation Models conversion system
/// 
/// ✅ CONFIRMED: Referenced in Apple documentation for:
/// - ConvertibleFromGeneratedContent.from(generatedContent:)
/// - ConvertibleToGeneratedContent.toGeneratedContent() return type
/// - PromptRepresentable conformance (confirmed)
public struct GeneratedContent: Codable {
    /// The raw content data
    private let data: Data
    
    /// The content type/format
    private let contentType: ContentType
    
    /// Initialize with string content
    /// - Parameter content: The string content
    public init(_ content: String) {
        self.data = content.data(using: .utf8) ?? Data()
        self.contentType = .text
    }
    
    /// Initialize with data and content type
    /// - Parameters:
    ///   - data: The content data
    ///   - contentType: The content type
    public init(data: Data, contentType: ContentType) {
        self.data = data
        self.contentType = contentType
    }
    
    /// Get content as string
    public var stringValue: String {
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// Get content as text (alias for stringValue)
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Text representation of the generated content for compatibility.
    public var text: String {
        return stringValue
    }
    
    /// Get raw data
    public var dataValue: Data {
        return data
    }
    
    /// Content type enumeration
    public enum ContentType: Codable, Sendable {
        case text
        case json
        case structured(schema: String)
    }
}

// MARK: - Required Conformances
extension GeneratedContent: Sendable {
    // GeneratedContent must be Sendable for concurrent use
}

/// ✅ CONFIRMED: GeneratedContent conforms to PromptRepresentable
extension GeneratedContent: PromptRepresentable {
    /// Required property with default implementation
    /// ✅ CONFIRMED: promptRepresentation property from Apple docs
    public var promptRepresentation: Prompt {
        // Convert GeneratedContent to Prompt format
        return Prompt(stringValue)
    }
}
