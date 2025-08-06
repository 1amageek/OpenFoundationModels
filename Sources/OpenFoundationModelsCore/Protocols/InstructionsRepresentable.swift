// InstructionsRepresentable.swift
// OpenFoundationModelsCore
//
// ✅ CONFIRMED: Required by Apple Foundation Models API

import Foundation

/// Conforming types represent instructions.
/// 
/// **Apple Foundation Models Documentation:**
/// Conforming types represent instructions.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable
/// 
/// **Apple Official API:** `protocol InstructionsRepresentable`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Inherited By:**
/// - ConvertibleToGeneratedContent
/// - Generable
/// 
/// **Conforming Types:**
/// - GeneratedContent
/// - Instructions
public protocol InstructionsRepresentable {
    /// An instance that represents the instructions.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An instance that represents the instructions.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable/instructionsrepresentation
    /// 
    /// **Apple Official API:** `@InstructionsBuilder var instructionsRepresentation: Instructions { get }`
    @InstructionsBuilder var instructionsRepresentation: Instructions { get }
}