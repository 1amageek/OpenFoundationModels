// ConvertibleFromGeneratedContent.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Required by Apple Foundation Models API

import Foundation

/// Protocol for types that can be created from generated content
/// 
/// ✅ CONFIRMED: Referenced in Apple documentation for:
/// - Tool.Arguments constraint
/// - Generable protocol inheritance
/// - PartiallyGenerated associated type constraint
public protocol ConvertibleFromGeneratedContent {
    /// Create an instance from generated content
    /// - Parameter generatedContent: The generated content to convert from
    /// - Returns: An instance of this type
    /// - Throws: If the content cannot be converted to this type
    static func from(generatedContent: GeneratedContent) throws -> Self
}

// MARK: - Missing Required Types
// ❌ GeneratedContent type not yet implemented