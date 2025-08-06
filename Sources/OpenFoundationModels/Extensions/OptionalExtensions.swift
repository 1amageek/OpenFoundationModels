// OptionalExtensions.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Optional conformances to Generable protocols

import Foundation
import OpenFoundationModelsCore

// MARK: - Optional PartiallyGenerated

extension Optional where Wrapped: Generable {
    // Apple spec: PartiallyGenerated = Wrapped.PartiallyGenerated (no Optional wrapper)
    public typealias PartiallyGenerated = Wrapped.PartiallyGenerated
}

// MARK: - Optional Protocol Conformances

extension Optional: ConvertibleToGeneratedContent where Wrapped: ConvertibleToGeneratedContent {
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        switch self {
        case .none:
            return GeneratedContent("null")
        case .some(let value):
            return value.generatedContent
        }
    }
}

extension Optional: PromptRepresentable where Wrapped: ConvertibleToGeneratedContent {
    /// An instance that represents a prompt.
    public var promptRepresentation: Prompt {
        switch self {
        case .none:
            return Prompt("")
        case .some(let value):
            return Prompt(value.generatedContent.text)
        }
    }
}

extension Optional: InstructionsRepresentable where Wrapped: ConvertibleToGeneratedContent {
    /// An instance that represents the instructions.
    public var instructionsRepresentation: Instructions {
        switch self {
        case .none:
            return Instructions("")
        case .some(let value):
            return Instructions(value.generatedContent.text)
        }
    }
}

// MARK: - Optional SendableMetatype Conformance

extension Optional: SendableMetatype where Wrapped: SendableMetatype {}

// MARK: - Optional ConvertibleFromGeneratedContent Conformance

extension Optional: ConvertibleFromGeneratedContent where Wrapped: ConvertibleFromGeneratedContent {
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        // Check if content represents null
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if text == "null" || text == "nil" || text.isEmpty {
            self = nil
        } else {
            // Try to decode as wrapped type
            self = try Wrapped(content)
        }
    }
}

// MARK: - Optional Generable Conformance

extension Optional: Generable where Wrapped: Generable {
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        // For optional types, we use the wrapped type's schema
        // The framework handles optionality through the Property initializers
        return Wrapped.generationSchema
    }
    
    /// Convert to partially generated representation
    public func asPartiallyGenerated() -> Wrapped.PartiallyGenerated {
        switch self {
        case .none:
            // For nil Optional, we need to create an "empty" PartiallyGenerated
            // This requires the PartiallyGenerated to be ConvertibleFromGeneratedContent
            return try! Wrapped.PartiallyGenerated(GeneratedContent("null"))
        case .some(let value):
            return value.asPartiallyGenerated()
        }
    }
}

