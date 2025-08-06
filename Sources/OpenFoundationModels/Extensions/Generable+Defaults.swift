// Generable+Defaults.swift
// OpenFoundationModels
//
// ✅ APPLE SPEC: Default implementations for Generable protocol

import Foundation
import OpenFoundationModelsCore

// MARK: - Generable Default Implementations

extension Generable {
    /// Default implementation of asPartiallyGenerated()
    /// 
    /// **Apple Foundation Models Documentation:**
    /// The default implementation handles two cases:
    /// 1. When PartiallyGenerated = Self (default), returns self
    /// 2. When PartiallyGenerated is a custom type, creates it from generatedContent
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generable/aspartiallygenerated()
    public func asPartiallyGenerated() -> Self.PartiallyGenerated {
        // Check if PartiallyGenerated is the same as Self (default case)
        // This is true for primitive types like String, Int, Bool, etc.
        if Self.PartiallyGenerated.self == Self.self {
            // Safe force cast because we've verified the types are the same
            return self as! Self.PartiallyGenerated
        } else {
            // Custom PartiallyGenerated type
            // This is used for @Generable structs with custom PartiallyGenerated
            do {
                return try Self.PartiallyGenerated(self.generatedContent)
            } catch {
                // This should not happen in practice as generatedContent should be valid
                // But we handle it gracefully
                fatalError("Failed to create PartiallyGenerated from generatedContent: \(error)")
            }
        }
    }
}

// MARK: - Default PartiallyGenerated Type

// Note: In Apple's implementation, when PartiallyGenerated is not explicitly defined,
// it defaults to Self. This is achieved through the protocol definition:
// associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self
// The default is automatically applied by Swift's type system.