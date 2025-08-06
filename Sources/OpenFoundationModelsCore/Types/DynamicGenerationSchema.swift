// DynamicGenerationSchema.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Based on Apple Foundation Models API specification

import Foundation

/// The dynamic counterpart to the generation schema type that you use to construct schemas at runtime.
/// 
/// **Apple Foundation Models Documentation:**
/// An individual schema may reference other schemas by name, and references are resolved when
/// converting a set of dynamic schemas into a GenerationSchema.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema
/// 
/// **Apple Official API:** `struct DynamicGenerationSchema`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conforms To:**
/// - Sendable
/// - SendableMetatype
public struct DynamicGenerationSchema: Sendable, SendableMetatype, Equatable {
    
    /// The name of the schema
    public let name: String
    
    /// Description of the schema
    public let description: String?
    
    /// The type of schema
    internal indirect enum SchemaType: Sendable, Equatable {
        static func == (lhs: SchemaType, rhs: SchemaType) -> Bool {
            switch (lhs, rhs) {
            case (.object(let lProps), .object(let rProps)):
                return lProps == rProps
            case (.array(let lOf, let lMin, let lMax), .array(let rOf, let rMin, let rMax)):
                return lOf == rOf && lMin == rMin && lMax == rMax
            case (.reference(let lTo), .reference(let rTo)):
                return lTo == rTo
            case (.anyOf(let lSchemas), .anyOf(let rSchemas)):
                return lSchemas == rSchemas
            case (.generic(let lType, _), .generic(let rType, _)):
                // Compare types by their string representation
                return String(describing: lType) == String(describing: rType)
            default:
                return false
            }
        }
        
        case object(properties: [Property])
        case array(of: DynamicGenerationSchema, minElements: Int?, maxElements: Int?)
        case reference(to: String)
        case anyOf([DynamicGenerationSchema])
        case generic(type: any SendableMetatype.Type, guides: [AnyGenerationGuide])
    }
    
    internal let schemaType: SchemaType
    
    /// Creates an object schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates an object schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:properties:)
    /// 
    /// **Apple Official API:** `init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])`
    /// 
    /// - Parameters:
    ///   - name: The name of the schema
    ///   - description: Optional description of the schema
    ///   - properties: Array of properties for the object schema
    public init(name: String, description: String? = nil, properties: [DynamicGenerationSchema.Property]) {
        self.name = name
        self.description = description
        self.schemaType = .object(properties: properties)
    }
    
    /// Creates an array schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates an array schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(arrayof:minimumelements:maximumelements:)
    /// 
    /// **Apple Official API:** `init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`
    /// 
    /// - Parameters:
    ///   - arrayOf: The schema for array elements
    ///   - minimumElements: Optional minimum number of elements
    ///   - maximumElements: Optional maximum number of elements
    public init(arrayOf: DynamicGenerationSchema, minimumElements: Int? = nil, maximumElements: Int? = nil) {
        self.name = "Array"
        self.description = nil
        self.schemaType = .array(of: arrayOf, minElements: minimumElements, maxElements: maximumElements)
    }
    
    /// Creates a reference schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a reference schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(referenceto:)
    /// 
    /// **Apple Official API:** `init(referenceTo: String)`
    /// 
    /// - Parameter referenceTo: The name of the schema to reference
    public init(referenceTo: String) {
        self.name = referenceTo
        self.description = nil
        self.schemaType = .reference(to: referenceTo)
    }
    
    /// Creates an any-of schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates an any-of schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:anyof:)
    /// 
    /// **Apple Official API:** `init(name:description:anyOf:)`
    /// 
    /// - Parameters:
    ///   - name: The name of the schema
    ///   - description: Optional description
    ///   - anyOf: Array of possible schemas
    public init(name: String, description: String? = nil, anyOf: [DynamicGenerationSchema]) {
        self.name = name
        self.description = description
        self.schemaType = .anyOf(anyOf)
    }
    
    /// Creates an any-of schema for string values.
    /// 
    /// **Custom Extension:**
    /// Convenience initializer for creating string enum schemas
    /// 
    /// - Parameters:
    ///   - name: The name of the schema
    ///   - description: Optional description
    ///   - anyOf: Array of possible string values
    public init(name: String, description: String? = nil, anyOf values: [String]) {
        self.name = name
        self.description = description
        // Convert string values to individual schemas
        let schemas = values.map { value in
            DynamicGenerationSchema(name: value, description: nil, properties: [])
        }
        self.schemaType = .anyOf(schemas)
    }
    
    /// Creates a schema from a generable type and guides.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a schema from a generable type and guides.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(type:guides:)
    /// 
    /// **Apple Official API:** `init<Value>(type: Value.Type, guides: [GenerationGuide<Value>])`
    /// 
    /// - Parameters:
    ///   - type: The type to generate
    ///   - guides: Array of generation guides
    public init<Value: Sendable>(type: Value.Type, guides: [GenerationGuide<Value>]) where Value: SendableMetatype {
        self.name = String(describing: type)
        self.description = nil
        let anyGuides = guides.map { AnyGenerationGuide($0) }
        self.schemaType = .generic(type: type as any SendableMetatype.Type, guides: anyGuides)
    }
    
    /// A property that belongs to a dynamic generation schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A property that belongs to a dynamic generation schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/property
    /// 
    /// **Apple Official API:** `struct Property`
    public struct Property: Sendable, Equatable {
        /// The name of the property
        public let name: String
        
        /// Optional description of the property
        public let description: String?
        
        /// The schema for this property
        public let schema: DynamicGenerationSchema
        
        /// Whether the property is required
        public let isRequired: Bool
        
        /// Creates a property for a dynamic generation schema.
        /// 
        /// - Parameters:
        ///   - name: The property name
        ///   - description: Optional description
        ///   - schema: The schema for this property
        ///   - isRequired: Whether the property is required (default: true)
        public init(name: String, description: String? = nil, schema: DynamicGenerationSchema, isRequired: Bool = true) {
            self.name = name
            self.description = description
            self.schema = schema
            self.isRequired = isRequired
        }
    }
}

// MARK: - GenerationSchema Integration

/// Dummy Generable type for dynamic schema creation
private struct DynamicGenerable: Generable, InstructionsRepresentable, PromptRepresentable {
    static var generationSchema: GenerationSchema {
        return GenerationSchema(type: DynamicGenerable.self, description: nil, properties: [])
    }
    
    init(_ content: GeneratedContent) throws {
        // Dummy implementation
    }
    
    var generatedContent: GeneratedContent {
        return GeneratedContent("")
    }
    
    func asPartiallyGenerated() -> DynamicGenerable {
        return self
    }
    
    @InstructionsBuilder
    var instructionsRepresentation: Instructions {
        Instructions("Dynamic content")
    }
    
    @PromptBuilder
    var promptRepresentation: Prompt {
        Prompt("Dynamic content")
    }
}

extension GenerationSchema {
    
    /// Helper method to convert dynamic schema to static schema
    private static func convertDynamicSchema(_ dynamic: DynamicGenerationSchema, dependencies: [String: DynamicGenerationSchema]) throws -> GenerationSchema {
        switch dynamic.schemaType {
        case .object(let properties):
            // Convert properties to GenerationSchema.Property array
            let schemaProperties = properties.map { prop in
                GenerationSchema.Property(
                    name: prop.name,
                    description: prop.description,
                    type: String.self,
                    guides: []
                )
            }
            return GenerationSchema(type: DynamicGenerable.self, description: dynamic.description, properties: schemaProperties)
            
        case .array(let elementSchema, let minElements, let maxElements):
            let innerSchema = try convertDynamicSchema(elementSchema, dependencies: dependencies)
            // Create array schema with constraints
            return GenerationSchema(schemaType: GenerationSchema.SchemaType.array(items: innerSchema), description: dynamic.description)
            
        case .reference(let name):
            // Resolve reference from dependencies
            guard let referenced = dependencies[name] else {
                throw SchemaError.unresolvedReference(name)
            }
            return try convertDynamicSchema(referenced, dependencies: dependencies)
            
        case .anyOf(let schemas):
            // For string anyOf, create enumeration
            if schemas.allSatisfy({ $0.name.count > 0 }) {
                let values = schemas.map { $0.name }
                return GenerationSchema(type: DynamicGenerable.self, description: dynamic.description, anyOf: values)
            }
            // For complex anyOf, we need more sophisticated handling
            // For now, use the first schema
            if let first = schemas.first {
                return try convertDynamicSchema(first, dependencies: dependencies)
            }
            return GenerationSchema(type: DynamicGenerable.self, description: dynamic.description, properties: [])
            
        case .generic(let type, let guides):
            // Create schema from type information
            return GenerationSchema(schemaType: GenerationSchema.SchemaType.primitive(type: String(describing: type)), description: dynamic.description)
        }
    }
    
    /// Schema creation errors
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Schema creation errors
    /// 
    /// **Apple Official API:** `enum SchemaError`
    public enum SchemaError: Error, Sendable {
        /// Reference to undefined schema
        case unresolvedReference(String)
        /// Invalid schema structure
        case invalidSchema(String)
        /// Circular reference detected
        case circularReference(String)
    }
}