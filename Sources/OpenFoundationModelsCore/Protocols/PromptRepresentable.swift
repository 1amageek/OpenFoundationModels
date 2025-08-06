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
    /// An instance that represents a prompt.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An instance that represents a prompt.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptrepresentable/promptrepresentation
    /// 
    /// **Apple Official API:** `@PromptBuilder var promptRepresentation: Prompt { get }`
    @PromptBuilder var promptRepresentation: Prompt { get }
}