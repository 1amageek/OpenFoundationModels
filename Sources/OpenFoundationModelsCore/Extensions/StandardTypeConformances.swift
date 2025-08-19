import Foundation

// MARK: - String Conformance

extension String: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: String.self,
            description: "Text content",
            properties: []
        )
    }
    
    public init(_ content: GeneratedContent) throws {
        self = content.text
    }
    
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .string(self))
    }
}

// MARK: - Bool Conformance

extension Bool: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Bool.self,
            description: "A boolean value",
            properties: []
        )
    }
    
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
    
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .bool(self))
    }
}

// MARK: - Int Conformance

extension Int: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Int.self,
            description: "An integer value",
            properties: []
        )
    }
    
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
    
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .number(Double(self)))
    }
}

// MARK: - Float Conformance

extension Float: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Float.self,
            description: "A floating-point number",
            properties: []
        )
    }
    
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
    
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .number(Double(self)))
    }
}

// MARK: - Double Conformance

extension Double: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Double.self,
            description: "A double-precision floating-point number",
            properties: []
        )
    }
    
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
    
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .number(self))
    }
}

// MARK: - Decimal Conformance

extension Decimal: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Decimal.self,
            description: "A decimal number with arbitrary precision",
            properties: []
        )
    }
    
    public init(_ content: GeneratedContent) throws {
        switch content.kind {
        case .number(let value):
            self = Decimal(value)
        case .string(let text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let value = Decimal(string: trimmed) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Unable to decode Decimal from: \(text)"
                    )
                )
            }
            self = value
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Decimal from Kind: \(content.kind)"
                )
            )
        }
    }
    
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .number(NSDecimalNumber(decimal: self).doubleValue))
    }
}

// MARK: - UUID Conformance

extension UUID: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: UUID.self,
            description: "A universally unique identifier in standard UUID format (8-4-4-4-12)",
            properties: []
        )
    }
    
    public init(_ content: GeneratedContent) throws {
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
    
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .string(self.uuidString))
    }
}

// MARK: - Date Conformance

extension Date: Generable {
    private static func createISO8601Formatter(withFractionalSeconds: Bool = true) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = withFractionalSeconds 
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter
    }
    
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Date.self,
            description: "A date and time value in ISO 8601 format (e.g., '2024-01-15T10:30:00.000Z')",
            properties: []
        )
    }
    
    public init(_ content: GeneratedContent) throws {
        let text = content.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let formatterWithFractional = Self.createISO8601Formatter(withFractionalSeconds: true)
        if let date = formatterWithFractional.date(from: text) {
            self = date
        } else {
            let formatterNoFractional = Self.createISO8601Formatter(withFractionalSeconds: false)
            if let date = formatterNoFractional.date(from: text) {
                self = date
            } else {
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
    
    public var generatedContent: GeneratedContent {
        let formatter = Self.createISO8601Formatter(withFractionalSeconds: true)
        return GeneratedContent(kind: .string(formatter.string(from: self)))
    }
}

// MARK: - URL Conformance

extension URL: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: URL.self,
            description: "A uniform resource locator (URL)",
            properties: []
        )
    }
    
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
    
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .string(self.absoluteString))
    }
}

// MARK: - Never Conformance

extension Never: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Never.self,
            description: "Never type (uninhabited)",
            properties: []
        )
    }
    
    public init(_ content: GeneratedContent) throws {
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Cannot create an instance of Never"
            )
        )
    }
    
    public var generatedContent: GeneratedContent {
        fatalError("Never has no instances")
    }
}