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
        switch content.kind {
        case .bool(let value):
            self = value
        case .number(let value):
            self = value != 0
        case .string(let s):
            let text = s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            switch text {
            case "true", "yes", "1":
                self = true
            case "false", "no", "0":
                self = false
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Unable to decode Bool from string: \(s)"
                    )
                )
            }
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Bool from Kind: \(content.kind)"
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
        switch content.kind {
        case .number(let value):
            guard value.truncatingRemainder(dividingBy: 1) == 0 else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Cannot convert decimal number \(value) to Int"
                    )
                )
            }
            self = Int(value)
        case .string(let s):
            let text = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let value = Int(text) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Unable to decode Int from string: \(s)"
                    )
                )
            }
            self = value
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Int from Kind: \(content.kind)"
                )
            )
        }
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
        switch content.kind {
        case .number(let value):
            self = Float(value)
        case .string(let s):
            let text = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let value = Float(text) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Unable to decode Float from string: \(s)"
                    )
                )
            }
            self = value
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Float from Kind: \(content.kind)"
                )
            )
        }
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
        switch content.kind {
        case .number(let value):
            self = value
        case .string(let s):
            let text = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let value = Double(text) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Unable to decode Double from string: \(s)"
                    )
                )
            }
            self = value
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Double from Kind: \(content.kind)"
                )
            )
        }
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

// MARK: - UUID Generable Conformance

extension UUID: Generable {
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: UUID.self,
            description: "A universally unique identifier in standard UUID format (8-4-4-4-12)",
            properties: []
        )
    }
    
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // UUID文字列の検証とパース
        guard let uuid = UUID(uuidString: text) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid UUID format: '\(text)'. Expected format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
                )
            )
        }
        self = uuid
    }
    
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .string(self.uuidString))
    }
    
    // asPartiallyGenerated() uses default implementation from protocol extension
    // Returns self since PartiallyGenerated = UUID (default)
}

// MARK: - Date Generable Conformance

extension Date: Generable {
    // Create formatters locally to avoid concurrency issues
    private static func createISO8601Formatter(withFractionalSeconds: Bool = true) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = withFractionalSeconds 
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter
    }
    
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Date.self,
            description: "A date and time value in ISO 8601 format (e.g., '2024-01-15T10:30:00.000Z')",
            properties: []
        )
    }
    
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 複数のISO8601フォーマットを試行
        let formatterWithFractional = Self.createISO8601Formatter(withFractionalSeconds: true)
        if let date = formatterWithFractional.date(from: text) {
            self = date
        } else {
            let formatterNoFractional = Self.createISO8601Formatter(withFractionalSeconds: false)
            if let date = formatterNoFractional.date(from: text) {
                self = date
            } else {
                // Unixタイムスタンプとしても試行（数値の場合）
                if let timestamp = Double(text) {
                    self = Date(timeIntervalSince1970: timestamp)
                } else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: [],
                            debugDescription: "Unable to decode Date from: '\(text)'. Expected ISO 8601 format or Unix timestamp."
                        )
                    )
                }
            }
        }
    }
    
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        let formatter = Self.createISO8601Formatter(withFractionalSeconds: true)
        return GeneratedContent(kind: .string(formatter.string(from: self)))
    }
    
    // asPartiallyGenerated() uses default implementation from protocol extension
    // Returns self since PartiallyGenerated = Date (default)
}

// MARK: - URL Generable Conformance

extension URL: Generable {
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: URL.self,
            description: "A uniform resource locator (URL)",
            properties: []
        )
    }
    
    /// Creates an instance with the content.
    public init(_ content: GeneratedContent) throws {
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let url = URL(string: text) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid URL format: '\(text)'"
                )
            )
        }
        self = url
    }
    
    /// An instance that represents the generated content.
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .string(self.absoluteString))
    }
    
    // asPartiallyGenerated() uses default implementation from protocol extension
    // Returns self since PartiallyGenerated = URL (default)
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
