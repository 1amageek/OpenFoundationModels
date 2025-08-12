// StandardTypeConformances.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Standard type conformances to Generable

import Foundation
import OpenFoundationModelsCore

// MARK: - Bool Generable Conformance

extension Bool: Generable {
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Bool.self,
            description: "A boolean value",
            properties: []
        )
    }
    
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        let text = content.text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch text {
        case "true", "yes", "1":
            self = true
        case "false", "no", "0":
            self = false
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Bool from: \(content.text)"
                )
            )
        }
    }
    
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .bool(self))
    }
    
    // asPartiallyGenerated() uses default implementation from protocol extension
    // Returns self since PartiallyGenerated = Bool (default)
}

// MARK: - Int Generable Conformance

extension Int: Generable {
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Int.self,
            description: "An integer value",
            properties: []
        )
    }
    
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(text) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Int from: \(content.text)"
                )
            )
        }
        self = value
    }
    
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .number(Double(self)))
    }
    
    // asPartiallyGenerated() uses default implementation from protocol extension
    // Returns self since PartiallyGenerated = Int (default)
}

// MARK: - Float Generable Conformance

extension Float: Generable {
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Float.self,
            description: "A floating-point number",
            properties: []
        )
    }
    
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Float(text) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Float from: \(content.text)"
                )
            )
        }
        self = value
    }
    
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .number(Double(self)))
    }
    
    // asPartiallyGenerated() uses default implementation from protocol extension
    // Returns self since PartiallyGenerated = Float (default)
}

// MARK: - Double Generable Conformance

extension Double: Generable {
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Double.self,
            description: "A double-precision floating-point number",
            properties: []
        )
    }
    
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(text) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Double from: \(content.text)"
                )
            )
        }
        self = value
    }
    
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .number(self))
    }
    
    // asPartiallyGenerated() uses default implementation from protocol extension
    // Returns self since PartiallyGenerated = Double (default)
}

// MARK: - Decimal Generable Conformance

extension Decimal: Generable {
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Decimal.self,
            description: "A decimal number with arbitrary precision",
            properties: []
        )
    }
    
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Decimal(string: text) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Decimal from: \(content.text)"
                )
            )
        }
        self = value
    }
    
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        return GeneratedContent(String(describing: self))
    }
    
    // asPartiallyGenerated() uses default implementation from protocol extension
    // Returns self since PartiallyGenerated = Decimal (default)
}

// MARK: - Never Generable Conformance

extension Never: Generable {
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Never.self,
            description: "Never type (uninhabited)",
            properties: []
        )
    }
    
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Cannot create an instance of Never"
            )
        )
    }
    
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        // This will never be called since Never has no instances
        fatalError("Never has no instances")
    }
    
    // asPartiallyGenerated() uses default implementation from protocol extension
    // But will never be called since Never has no instances
}