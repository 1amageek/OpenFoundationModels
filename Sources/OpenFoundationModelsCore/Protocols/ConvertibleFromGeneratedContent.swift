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
public protocol ConvertibleFromGeneratedContent: SendableMetatype {
    /// Create an instance from generated content
    /// - Parameter content: The generated content to convert from
    /// - Throws: If the content cannot be converted to this type
    /// ✅ CONFIRMED: init(_:) throws from Apple docs
    init(_ content: GeneratedContent) throws
}

// MARK: - Missing Required Types
// ❌ GeneratedContent type not yet implemented