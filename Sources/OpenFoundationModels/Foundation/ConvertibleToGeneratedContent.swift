// ConvertibleToGeneratedContent.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Required by Apple Foundation Models API

import Foundation

/// Protocol for types that can be converted to generated content
/// 
/// ✅ CONFIRMED: Referenced in Apple documentation for:
/// - Generable protocol inheritance
/// - Required by GeneratedContent initializers
public protocol ConvertibleToGeneratedContent: InstructionsRepresentable, PromptRepresentable {
    /// A representation of this instance as generated content
    /// ✅ CONFIRMED: Required by Apple's GeneratedContent init(properties:) and init<C>(elements:)
    var generatedContent: GeneratedContent { get }
}

// MARK: - Missing Required Types
// ❌ GeneratedContent type not yet implemented