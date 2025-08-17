
import Foundation


public struct DynamicGenerationSchema: Sendable {
    
    public let name: String
    
    public let description: String?
    
    internal indirect enum SchemaType: Sendable {
        case object(properties: [Property])
        case array(of: DynamicGenerationSchema, minElements: Int?, maxElements: Int?)
        case reference(to: String)
        case anyOf([DynamicGenerationSchema])
        case generic(type: any Generable.Type, guides: [AnyGenerationGuide])
        
    }
    
    internal let schemaType: SchemaType
    
    public init(name: String, description: String? = nil, properties: [DynamicGenerationSchema.Property]) {
        self.name = name
        self.description = description
        self.schemaType = .object(properties: properties)
    }
    
    public init(arrayOf itemSchema: DynamicGenerationSchema, minimumElements: Int? = nil, maximumElements: Int? = nil) {
        self.name = "Array"
        self.description = nil
        self.schemaType = .array(of: itemSchema, minElements: minimumElements, maxElements: maximumElements)
    }
    
    public init(referenceTo name: String) {
        self.name = name
        self.description = nil
        self.schemaType = .reference(to: name)
    }
    
    public init(name: String, description: String? = nil, anyOf: [DynamicGenerationSchema]) {
        self.name = name
        self.description = description
        self.schemaType = .anyOf(anyOf)
    }
    
    public init(name: String, description: String? = nil, anyOf choices: [String]) {
        self.name = name
        self.description = description
        let schemas = choices.map { value in
            DynamicGenerationSchema(name: value, description: nil, properties: [])
        }
        self.schemaType = .anyOf(schemas)
    }
    
    public init<Value>(type: Value.Type, guides: [GenerationGuide<Value>] = []) where Value: Generable {
        self.name = String(describing: type)
        self.description = nil
        let anyGuides = guides.map { AnyGenerationGuide($0) }
        self.schemaType = .generic(type: type, guides: anyGuides)
    }
    
    public struct Property: Sendable {
        public let name: String
        
        public let description: String?
        
        public let schema: DynamicGenerationSchema
        
        public let isOptional: Bool
        
        public init(name: String, description: String? = nil, schema: DynamicGenerationSchema, isOptional: Bool = false) {
            self.name = name
            self.description = description
            self.schema = schema
            self.isOptional = isOptional
        }
    }
}


extension DynamicGenerationSchema: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, description, schemaType
        case type, properties, arrayOf, minElements, maxElements
        case referenceTo, anyOf, choices
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        
        switch schemaType {
        case .object(let properties):
            try container.encode("object", forKey: .type)
            try container.encode(properties, forKey: .properties)
            
        case .array(let of, let min, let max):
            try container.encode("array", forKey: .type)
            try container.encode(of, forKey: .arrayOf)
            try container.encodeIfPresent(min, forKey: .minElements)
            try container.encodeIfPresent(max, forKey: .maxElements)
            
        case .reference(let to):
            try container.encode("reference", forKey: .type)
            try container.encode(to, forKey: .referenceTo)
            
        case .anyOf(let schemas):
            if schemas.allSatisfy({ schema in
                if case .object(let properties) = schema.schemaType {
                    return properties.isEmpty && schema.description == nil
                }
                return false
            }) {
                try container.encode("enum", forKey: .type)
                let choices = schemas.map { $0.name }
                try container.encode(choices, forKey: .choices)
            } else {
                try container.encode("anyOf", forKey: .type)
                try container.encode(schemas, forKey: .anyOf)
            }
            
        case .generic:
            throw EncodingError.invalidValue(
                schemaType,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Generic schemas with type information cannot be persisted. Convert to a concrete schema first."
                )
            )
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "object":
            let properties = try container.decode([Property].self, forKey: .properties)
            self.schemaType = .object(properties: properties)
            
        case "array":
            let of = try container.decode(DynamicGenerationSchema.self, forKey: .arrayOf)
            let min = try container.decodeIfPresent(Int.self, forKey: .minElements)
            let max = try container.decodeIfPresent(Int.self, forKey: .maxElements)
            self.schemaType = .array(of: of, minElements: min, maxElements: max)
            
        case "reference":
            let to = try container.decode(String.self, forKey: .referenceTo)
            self.schemaType = .reference(to: to)
            
        case "anyOf":
            let schemas = try container.decode([DynamicGenerationSchema].self, forKey: .anyOf)
            self.schemaType = .anyOf(schemas)
            
        case "enum":
            let choices = try container.decode([String].self, forKey: .choices)
            let schemas = choices.map { value in
                DynamicGenerationSchema(name: value, description: nil, properties: [])
            }
            self.schemaType = .anyOf(schemas)
            
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown schema type: \(type)"
                )
            )
        }
    }
}

extension DynamicGenerationSchema.Property: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, description, schema, isOptional
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(schema, forKey: .schema)
        try container.encode(isOptional, forKey: .isOptional)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.schema = try container.decode(DynamicGenerationSchema.self, forKey: .schema)
        self.isOptional = try container.decode(Bool.self, forKey: .isOptional)
    }
}

