import Foundation
import OpenFoundationModelsCore

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

// GeneratedContent already conforms to Generable in OpenFoundationModelsCore

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

extension Array: ConvertibleToGeneratedContent where Element: ConvertibleToGeneratedContent {
    public var generatedContent: GeneratedContent {
        let elements = self.map { $0.generatedContent }
        return GeneratedContent(kind: .array(elements))
    }
}

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