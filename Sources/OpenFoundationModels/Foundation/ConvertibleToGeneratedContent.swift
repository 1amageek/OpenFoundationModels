// ConvertibleToGeneratedContent.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Required by Apple Foundation Models API

import Foundation

/// Protocol for types that can be converted to generated content
/// 
/// ✅ CONFIRMED: Referenced in Apple documentation for:
/// - Generable protocol inheritance
public protocol ConvertibleToGeneratedContent {
    /// Convert this instance to generated content
    /// - Returns: The generated content representation
    /// - Throws: If the instance cannot be converted to generated content
    func toGeneratedContent() throws -> GeneratedContent
}

// MARK: - Missing Required Types
// ❌ GeneratedContent type not yet implemented