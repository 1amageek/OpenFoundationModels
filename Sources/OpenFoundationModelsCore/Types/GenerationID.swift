import Foundation

public struct GenerationID: Equatable, Hashable, Sendable {
    private let value: UUID
    
    public init() {
        self.value = UUID()
    }
    
    internal init(value: UUID) {
        self.value = value
    }
}

extension GenerationID: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.uuidString)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let uuidString = try container.decode(String.self)
        guard let uuid = UUID(uuidString: uuidString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid UUID string: \(uuidString)"
            )
        }
        self.value = uuid
    }
}

extension GenerationID: CustomStringConvertible {
    public var description: String {
        return value.uuidString
    }
}

extension GenerationID: Generable {
    public static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: GenerationID.self,
            description: "A unique identifier that is stable for the duration of a response",
            properties: []
        )
    }
    
    public init(_ content: GeneratedContent) throws {
        let uuidString = content.text
        if let uuid = UUID(uuidString: uuidString) {
            self.init(value: uuid)
        } else {
            self.init()
        }
    }
    
    public var generatedContent: GeneratedContent {
        return GeneratedContent(kind: .string(value.uuidString))
    }
}