import Foundation

// MARK: - Array Generable Conformance

extension Array: Generable where Element: Generable {
    
    /// A representation of partially generated content
    public typealias PartiallyGenerated = [Element.PartiallyGenerated]
    
    /// An instance of the generation schema.
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: Array<Element>.self,
            description: "Array of \(String(describing: Element.self))",
            properties: []
        )
    }
    
    // Custom implementation required because PartiallyGenerated != Self
    public func asPartiallyGenerated() -> PartiallyGenerated {
        return self.map { $0.asPartiallyGenerated() }
    }
}

// MARK: - Array ConvertibleToGeneratedContent

extension Array: ConvertibleToGeneratedContent where Element: ConvertibleToGeneratedContent {
    public var generatedContent: GeneratedContent {
        let elements = self.map { $0.generatedContent }
        return GeneratedContent(kind: .array(elements))
    }
}

// MARK: - Array ConvertibleFromGeneratedContent

extension Array: ConvertibleFromGeneratedContent where Element: ConvertibleFromGeneratedContent {
    public init(_ content: GeneratedContent) throws {
        switch content.kind {
        case .array(let elements):
            self = try elements.map { try Element($0) }
        case .string(let text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = trimmed.data(using: .utf8) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Unable to convert string to data for JSON parsing"
                    )
                )
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Unable to decode Array from string: expected valid JSON array format"
                    )
                )
            }
            
            self = try json.map {
                let jsonData = try JSONSerialization.data(withJSONObject: $0)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                return try Element(GeneratedContent(json: jsonString))
            }
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unable to decode Array from Kind: \(content.kind)"
                )
            )
        }
    }
}