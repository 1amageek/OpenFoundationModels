// PromptRepresentable.swift
// OpenFoundationModelsCore
//
// ✅ CONFIRMED: Required by Apple Foundation Models API

import Foundation

/// Protocol for types that can represent prompts
/// 
/// ✅ CONFIRMED: Referenced in Apple documentation for:
/// - Generable protocol inheritance
public protocol PromptRepresentable {
    /// Required property with default implementation
    /// ✅ CONFIRMED: promptRepresentation property from Apple docs
    var promptRepresentation: Prompt { get }
}