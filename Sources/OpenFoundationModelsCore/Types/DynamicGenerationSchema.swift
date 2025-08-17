
import Foundation


public struct DynamicGenerationSchema: Sendable {
    
    internal let name: String
    
    internal let description: String?
    
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
        internal let name: String
        
        internal let description: String?
        
        internal let schema: DynamicGenerationSchema
        
        internal let isOptional: Bool
        
        public init(name: String, description: String? = nil, schema: DynamicGenerationSchema, isOptional: Bool = false) {
            self.name = name
            self.description = description
            self.schema = schema
            self.isOptional = isOptional
        }
    }
}

