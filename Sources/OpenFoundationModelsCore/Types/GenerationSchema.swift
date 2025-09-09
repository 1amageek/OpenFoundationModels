import Foundation

public struct GenerationSchema: Sendable, Codable, CustomDebugStringConvertible {
    internal let schemaType: SchemaType
    private let _description: String?
    
    // MARK: - Nested Types
    
    internal indirect enum SchemaType: Sendable {
        case object(properties: [PropertyInfo])
        case array(element: SchemaType, minItems: Int?, maxItems: Int?)
        case dictionary(valueType: SchemaType)
        case anyOf([SchemaType])
        case generic(type: any Generable.Type, guides: [AnyGenerationGuide])
    }
    
    internal struct PropertyInfo: Sendable {
        let name: String
        let description: String?
        let type: SchemaType
        let isOptional: Bool
    }
    
    internal var type: String {
        return schemaType.jsonSchemaType
    }
    
    internal var description: String? {
        return self._description
    }
    
    internal var properties: [String: GenerationSchema]? {
        return nil
    }
    
    
    internal init(
        type: String,
        description: String? = nil,
        properties: [String: GenerationSchema]? = nil,
        required: [String]? = nil,
        items: GenerationSchema? = nil,
        anyOf: [GenerationSchema] = []
    ) {
        self._description = description
        
        if type == "object" {
            let propInfos = (properties ?? [:]).map { (name, schema) in
                return PropertyInfo(
                    name: name,
                    description: schema._description,
                    type: schema.schemaType,
                    isOptional: false  // Default to required for JSON parsing
                )
            }.sorted { $0.name < $1.name }
            self.schemaType = .object(properties: propInfos)
        } else if type == "array" {
            if let items = items {
                self.schemaType = .array(element: items.schemaType, minItems: nil, maxItems: nil)
            } else {
                self.schemaType = .array(element: .generic(type: String.self, guides: []), minItems: nil, maxItems: nil)
            }
        } else if type == "string" && !anyOf.isEmpty {
            let schemas = anyOf.map { $0.schemaType }
            self.schemaType = .anyOf(schemas)
        } else {
            // Infer Generable type from primitive type string
            let generableType: any Generable.Type = switch type {
            case "string": String.self
            case "integer": Int.self
            case "number": Double.self
            case "boolean": Bool.self
            default: String.self
            }
            self.schemaType = .generic(type: generableType, guides: [])
        }
    }
    
    internal init(
        schemaType: SchemaType,
        description: String? = nil
    ) {
        self.schemaType = schemaType
        self._description = description
    }
    
    
    public init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws {
        self._description = root.description
        
        // Create dependency map for easier lookup
        let dependencyMap = Dictionary(uniqueKeysWithValues: dependencies.map { ($0.name, $0) })
        
        // Fully resolve all references at initialization
        self.schemaType = try Self.resolve(root.schemaType, dependencies: dependencyMap)
    }
    
    private static func resolve(
        _ dynamicType: DynamicGenerationSchema.SchemaType,
        dependencies: [String: DynamicGenerationSchema],
        visitedRefs: Set<String> = []
    ) throws -> GenerationSchema.SchemaType {
        switch dynamicType {
        case .object(let properties):
            // Resolve all properties
            let resolvedProps = try properties.map { prop in
                PropertyInfo(
                    name: prop.name,
                    description: prop.description,
                    type: try resolve(prop.schema.schemaType, dependencies: dependencies, visitedRefs: visitedRefs),
                    isOptional: prop.isOptional
                )
            }
            return .object(properties: resolvedProps)
            
        case .array(let element, let minItems, let maxItems):
            // Resolve array element
            let resolvedElement = try resolve(element.schemaType, dependencies: dependencies, visitedRefs: visitedRefs)
            return .array(element: resolvedElement, minItems: minItems, maxItems: maxItems)
            
        case .reference(let name):
            // Check for circular reference
            guard !visitedRefs.contains(name) else {
                throw SchemaError.undefinedReferences(
                    schema: name,
                    references: [name],
                    context: SchemaError.Context(debugDescription: "Circular reference detected: \(name)")
                )
            }
            
            // Find the referenced schema
            guard let referenced = dependencies[name] else {
                throw SchemaError.undefinedReferences(
                    schema: name,
                    references: [name],
                    context: SchemaError.Context(debugDescription: "Reference '\(name)' not found in dependencies")
                )
            }
            
            // Recursively resolve the referenced schema
            var newVisited = visitedRefs
            newVisited.insert(name)
            return try resolve(referenced.schemaType, dependencies: dependencies, visitedRefs: newVisited)
            
        case .anyOf(let schemas):
            // Resolve all schemas in anyOf
            let resolved = try schemas.map { schema in
                try resolve(schema.schemaType, dependencies: dependencies, visitedRefs: visitedRefs)
            }
            return .anyOf(resolved)
            
        case .generic(let type, let guides):
            // Generic types are already resolved
            return .generic(type: type, guides: guides)
        }
    }
    
    public init(type: any Generable.Type, description: String? = nil, anyOf choices: [String]) {
        // Create anyOf with string constants
        let schemas = choices.map { choice in
            SchemaType.generic(
                type: String.self,
                guides: [AnyGenerationGuide(GenerationGuide<String>.constant(choice))]
            )
        }
        self.schemaType = .anyOf(schemas)
        self._description = description
    }
    
    public init(type: any Generable.Type, description: String? = nil, properties: [GenerationSchema.Property]) {
        // Check if this is a standard primitive type with empty properties
        if properties.isEmpty {
            self.schemaType = .generic(type: type, guides: [])
        } else {
            // Convert Property to PropertyInfo
            let propInfos = properties.map { prop in
                // Use the actual generationSchema for the property type
                // This ensures arrays and other complex types are handled correctly
                // prop.type is already defined as any Generable.Type in the Property struct
                let propertySchemaType: SchemaType = prop.type.generationSchema.schemaType
                
                return PropertyInfo(
                    name: prop.name,
                    description: prop.description,
                    type: propertySchemaType,
                    isOptional: SchemaType.isOptionalType(prop.type)
                )
            }
            self.schemaType = .object(properties: propInfos)
        }
        self._description = description
    }
    
    public init(type: any Generable.Type, description: String? = nil, anyOf types: [any Generable.Type]) {
        // For union types, create schemas for each type
        let schemas = types.map { genType in
            SchemaType.generic(type: genType, guides: [])
        }
        self.schemaType = .anyOf(schemas)
        self._description = description
    }
    
    
    
    
    public var debugDescription: String {
        switch schemaType {
        case .object(let properties):
            let propList = properties.map { "\($0.name)" }.joined(separator: ", ")
            return "GenerationSchema(object: [\(propList)])"
        case .dictionary(let valueType):
            return "GenerationSchema(dictionary: \(valueType))"
        case .anyOf(let schemas):
            // Check if this is a simple enum (all string constants)
            var isEnum = true
            for schema in schemas {
                if case .generic(let type, let guides) = schema {
                    if type != String.self || guides.isEmpty {
                        isEnum = false
                        break
                    }
                } else {
                    isEnum = false
                    break
                }
            }
            if isEnum {
                return "GenerationSchema(enum: \(schemas.count) values)"
            }
            return "GenerationSchema(anyOf: \(schemas.count) schemas)"
        case .array(let element, let minItems, let maxItems):
            var desc = "GenerationSchema(array"
            desc += " of: \(element)"
            if let min = minItems {
                desc += ", min: \(min)"
            }
            if let max = maxItems {
                desc += ", max: \(max)"
            }
            desc += ")"
            return desc
        case .generic(let type, _):
            return "GenerationSchema(\(String(describing: type)))"
        }
    }
    
    internal func toSchemaDictionary(asRootSchema: Bool = false) -> [String: Any] {
        var schema = schemaType.toJSONSchema(description: _description)
        
        // Add $schema field for root schemas
        if asRootSchema {
            schema["$schema"] = "https://json-schema.org/draft/2020-12/schema"
        }
        
        return schema
    }
    
}


/// Guides that control how values are generated.
public struct GenerationGuide<Value> {
    // Internal storage for guide values
    private let storage: Storage
    
    // Private storage enum to hold different types of values
    private enum Storage {
        case string(StringStorage)
        case int(IntStorage)
        case float(FloatStorage)
        case double(DoubleStorage)
        case decimal(DecimalStorage)
        case array(ArrayStorage)
        case generic(GenericStorage)
    }
    
    private enum StringStorage {
        case constant(String)
        case anyOf([String])
        case pattern(String)
    }
    
    private enum IntStorage {
        case minimum(Int)
        case maximum(Int)
        case range(ClosedRange<Int>)
    }
    
    private enum FloatStorage {
        case minimum(Float)
        case maximum(Float)
        case range(ClosedRange<Float>)
    }
    
    private enum DoubleStorage {
        case minimum(Double)
        case maximum(Double)
        case range(ClosedRange<Double>)
    }
    
    private enum DecimalStorage {
        case minimum(Decimal)
        case maximum(Decimal)
        case range(ClosedRange<Decimal>)
    }
    
    private enum ArrayStorage {
        case minimumCount(Int)
        case maximumCount(Int)
        case countRange(ClosedRange<Int>)
        case exactCount(Int)
        case element(Any) // Stores GenerationGuide<Element>
    }
    
    private enum GenericStorage {
        case neverArray(ArrayStorage)
    }
    
    // Private initializer
    private init(storage: Storage) {
        self.storage = storage
    }
    
    // Internal method to support schema generation
    internal func applyToSchema(_ schema: inout [String: Any]) {
        switch storage {
        case .string(let stringStorage):
            switch stringStorage {
            case .constant(let value):
                schema["const"] = value
            case .anyOf(let values):
                schema["enum"] = values
            case .pattern(let pattern):
                schema["pattern"] = pattern
            }
        case .int(let intStorage):
            switch intStorage {
            case .minimum(let value):
                schema["minimum"] = value
            case .maximum(let value):
                schema["maximum"] = value
            case .range(let range):
                schema["minimum"] = range.lowerBound
                schema["maximum"] = range.upperBound
            }
        case .float(let floatStorage):
            switch floatStorage {
            case .minimum(let value):
                schema["minimum"] = value
            case .maximum(let value):
                schema["maximum"] = value
            case .range(let range):
                schema["minimum"] = range.lowerBound
                schema["maximum"] = range.upperBound
            }
        case .double(let doubleStorage):
            switch doubleStorage {
            case .minimum(let value):
                schema["minimum"] = value
            case .maximum(let value):
                schema["maximum"] = value
            case .range(let range):
                schema["minimum"] = range.lowerBound
                schema["maximum"] = range.upperBound
            }
        case .decimal(let decimalStorage):
            switch decimalStorage {
            case .minimum(let value):
                schema["minimum"] = value
            case .maximum(let value):
                schema["maximum"] = value
            case .range(let range):
                schema["minimum"] = range.lowerBound
                schema["maximum"] = range.upperBound
            }
        case .array(let arrayStorage):
            switch arrayStorage {
            case .minimumCount(let count):
                schema["minItems"] = count
            case .maximumCount(let count):
                schema["maxItems"] = count
            case .countRange(let range):
                schema["minItems"] = range.lowerBound
                schema["maxItems"] = range.upperBound
            case .exactCount(let count):
                schema["minItems"] = count
                schema["maxItems"] = count
            case .element(_):
                // Element guides are handled separately
                break
            }
        case .generic(let genericStorage):
            switch genericStorage {
            case .neverArray(let arrayStorage):
                switch arrayStorage {
                case .minimumCount(let count):
                    schema["minItems"] = count
                case .maximumCount(let count):
                    schema["maxItems"] = count
                case .countRange(let range):
                    schema["minItems"] = range.lowerBound
                    schema["maxItems"] = range.upperBound
                case .exactCount(let count):
                    schema["minItems"] = count
                    schema["maxItems"] = count
                case .element(_):
                    break
                }
            }
        }
    }
}


extension GenerationGuide where Value == String {
    public static func constant(_ value: String) -> GenerationGuide<String> {
        return GenerationGuide<String>(storage: .string(.constant(value)))
    }
    
    public static func anyOf(_ values: [String]) -> GenerationGuide<String> {
        return GenerationGuide<String>(storage: .string(.anyOf(values)))
    }
    
    public static func pattern<Output>(_ regex: Regex<Output>) -> GenerationGuide<String> {
        return GenerationGuide<String>(storage: .string(.pattern(String(describing: regex))))
    }
}

extension GenerationGuide {
    public static func minimumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element] {
        return GenerationGuide<[Element]>(storage: .array(.minimumCount(count)))
    }
    
    public static func maximumCount<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element] {
        return GenerationGuide<[Element]>(storage: .array(.maximumCount(count)))
    }
    
    public static func count<Element>(_ range: ClosedRange<Int>) -> GenerationGuide<[Element]> where Value == [Element] {
        return GenerationGuide<[Element]>(storage: .array(.countRange(range)))
    }
    
    public static func count<Element>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element] {
        return GenerationGuide<[Element]>(storage: .array(.exactCount(count)))
    }
    
    public static func element<Element>(_ guide: GenerationGuide<Element>) -> GenerationGuide<[Element]> where Value == [Element] {
        return GenerationGuide<[Element]>(storage: .array(.element(guide)))
    }
}

extension GenerationGuide where Value == [Never] {
    public static func minimumCount(_ count: Int) -> GenerationGuide<Value> {
        return GenerationGuide<Value>(storage: .generic(.neverArray(.minimumCount(count))))
    }
    
    public static func maximumCount(_ count: Int) -> GenerationGuide<Value> {
        return GenerationGuide<Value>(storage: .generic(.neverArray(.maximumCount(count))))
    }
    
    public static func count(_ range: ClosedRange<Int>) -> GenerationGuide<Value> {
        return GenerationGuide<Value>(storage: .generic(.neverArray(.countRange(range))))
    }
    
    public static func count(_ count: Int) -> GenerationGuide<Value> {
        return GenerationGuide<Value>(storage: .generic(.neverArray(.exactCount(count))))
    }
}

extension GenerationGuide where Value == Decimal {
    public static func minimum(_ value: Decimal) -> GenerationGuide<Decimal> {
        return GenerationGuide<Decimal>(storage: .decimal(.minimum(value)))
    }
    
    public static func maximum(_ value: Decimal) -> GenerationGuide<Decimal> {
        return GenerationGuide<Decimal>(storage: .decimal(.maximum(value)))
    }
    
    public static func range(_ range: ClosedRange<Decimal>) -> GenerationGuide<Decimal> {
        return GenerationGuide<Decimal>(storage: .decimal(.range(range)))
    }
}

extension GenerationGuide where Value == Float {
    public static func minimum(_ value: Float) -> GenerationGuide<Float> {
        return GenerationGuide<Float>(storage: .float(.minimum(value)))
    }
    
    public static func maximum(_ value: Float) -> GenerationGuide<Float> {
        return GenerationGuide<Float>(storage: .float(.maximum(value)))
    }
    
    public static func range(_ range: ClosedRange<Float>) -> GenerationGuide<Float> {
        return GenerationGuide<Float>(storage: .float(.range(range)))
    }
}


extension GenerationGuide where Value == Int {
    public static func minimum(_ value: Int) -> GenerationGuide<Int> {
        return GenerationGuide<Int>(storage: .int(.minimum(value)))
    }
    
    public static func maximum(_ value: Int) -> GenerationGuide<Int> {
        return GenerationGuide<Int>(storage: .int(.maximum(value)))
    }
    
    public static func range(_ range: ClosedRange<Int>) -> GenerationGuide<Int> {
        return GenerationGuide<Int>(storage: .int(.range(range)))
    }
}

extension GenerationGuide where Value == Double {
    public static func minimum(_ value: Double) -> GenerationGuide<Double> {
        return GenerationGuide<Double>(storage: .double(.minimum(value)))
    }
    
    public static func maximum(_ value: Double) -> GenerationGuide<Double> {
        return GenerationGuide<Double>(storage: .double(.maximum(value)))
    }
    
    public static func range(_ range: ClosedRange<Double>) -> GenerationGuide<Double> {
        return GenerationGuide<Double>(storage: .double(.range(range)))
    }
}

// Type-erased wrapper for GenerationGuide
internal struct AnyGenerationGuide: @unchecked Sendable, Equatable {
    private let applyToSchemaImpl: (inout [String: Any]) -> Void
    
    internal init<T>(_ guide: GenerationGuide<T>) {
        self.applyToSchemaImpl = { schema in
            guide.applyToSchema(&schema)
        }
    }
    
    internal func applyToSchema(_ schema: inout [String: Any]) {
        applyToSchemaImpl(&schema)
    }
    
    static func ==(lhs: AnyGenerationGuide, rhs: AnyGenerationGuide) -> Bool {
        // Since we can't compare the actual guides, return true for simplicity
        // This is only used for Equatable conformance
        return true
    }
}


// MARK: - Helper Extensions

extension GenerationSchema.SchemaType {
    var jsonSchemaType: String {
        switch self {
        case .object:
            return "object"
        case .array:
            return "array"
        case .dictionary:
            return "object"
        case .generic(let type, _):
            return Self.jsonSchemaType(for: type)
        case .anyOf:
            return "object" // Default for complex types
        }
    }
    
    /// Helper function to determine if a type is Optional
    static func isOptionalType(_ type: any Generable.Type) -> Bool {
        let typeName = String(describing: type)
        return typeName.hasPrefix("Optional<")
    }
    
    static func jsonSchemaType(for type: any Generable.Type) -> String {
        let typeName = String(describing: type)
        switch typeName {
        case "String":
            return "string"
        case "Int", "Int8", "Int16", "Int32", "Int64",
             "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            return "integer"
        case "Float", "Double", "Decimal":
            return "number"
        case "Bool":
            return "boolean"
        case let t where t.contains("Array"):
            return "array"
        case let t where t.contains("Dictionary"):
            return "object"
        default:
            // For complex types, check if it's an enum or object
            if typeName.contains("Optional") {
                // Extract wrapped type and recurse
                return "object" // Simplified for Optional
            }
            return "object" // Default for custom types
        }
    }
    
    func toJSONSchema(description: String? = nil) -> [String: Any] {
        var result: [String: Any] = [:]
        
        if let description = description {
            result["description"] = description
        }
        
        switch self {
        case .object(let properties):
            result["type"] = "object"
            if !properties.isEmpty {
                var props: [String: Any] = [:]
                var required: [String] = []
                
                for property in properties {
                    var propSchema = property.type.toJSONSchema(description: property.description)
                    // Remove description from nested schema if it was added at property level
                    if property.description != nil {
                        propSchema.removeValue(forKey: "description")
                        propSchema["description"] = property.description
                    }
                    
                    // If property is optional, modify schema to allow null
                    if property.isOptional {
                        if let baseType = propSchema["type"] as? String {
                            // Simple types: use array notation ["type", "null"]
                            propSchema["type"] = [baseType, "null"]
                        } else if propSchema["anyOf"] != nil || propSchema["enum"] != nil {
                            // Complex types with anyOf or enum: wrap with anyOf including null
                            let originalSchema = propSchema
                            propSchema = [
                                "anyOf": [originalSchema, ["type": "null"]]
                            ]
                            // Preserve description at the top level
                            if let desc = property.description {
                                propSchema["description"] = desc
                            }
                        }
                    }
                    
                    props[property.name] = propSchema
                    
                    // Check if the property is optional using PropertyInfo's isOptional field
                    if !property.isOptional {
                        required.append(property.name)
                    }
                }
                
                result["properties"] = props
                if !required.isEmpty {
                    result["required"] = required
                }
            }
            
        case .dictionary(let valueType):
            result["type"] = "object"
            result["additionalProperties"] = valueType.toJSONSchema()
            
        case .array(let element, let minItems, let maxItems):
            result["type"] = "array"
            result["items"] = element.toJSONSchema()
            if let min = minItems { result["minItems"] = min }
            if let max = maxItems { result["maxItems"] = max }
            
        case .anyOf(let types):
            // Check if all types are simple string constants
            var enumValues: [String] = []
            var isSimpleEnum = true
            
            for schemaType in types {
                if case .generic(let type, let guides) = schemaType,
                   type == String.self,
                   guides.count == 1 {
                    // Try to extract constant value
                    var tempSchema: [String: Any] = [:]
                    guides[0].applyToSchema(&tempSchema)
                    if let constValue = tempSchema["const"] as? String {
                        enumValues.append(constValue)
                    } else {
                        isSimpleEnum = false
                        break
                    }
                } else {
                    isSimpleEnum = false
                    break
                }
            }
            
            if isSimpleEnum && !enumValues.isEmpty {
                result["type"] = "string"
                result["enum"] = enumValues
            } else {
                result["anyOf"] = types.map { $0.toJSONSchema() }
            }
            
        case .generic(let type, let guides):
            // Use type casting for more robust type detection
            let jsonType: String
            switch type {
            case is String.Type:
                jsonType = "string"
            case is Bool.Type:
                jsonType = "boolean"
            case is any FixedWidthInteger.Type:
                // Covers Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64
                jsonType = "integer"
            case is any BinaryFloatingPoint.Type:
                // Covers Float, Double, Float80 (if available)
                jsonType = "number"
            case is Decimal.Type:
                jsonType = "number"
            default:
                // Check for Optional types
                let typeName = String(describing: type)
                if typeName.hasPrefix("Optional<") {
                    // For Optional types, try to determine inner type
                    // This is a simplified approach; could be enhanced
                    if typeName.contains("String") {
                        jsonType = "string"
                    } else if typeName.contains("Int") || typeName.contains("UInt") {
                        jsonType = "integer"
                    } else if typeName.contains("Float") || typeName.contains("Double") || typeName.contains("Decimal") {
                        jsonType = "number"
                    } else if typeName.contains("Bool") {
                        jsonType = "boolean"
                    } else {
                        jsonType = "object"
                    }
                } else {
                    // For complex Generable types, treat as objects
                    // Note: This avoids infinite recursion with self-referential types
                    jsonType = "object"
                }
            }
            
            result["type"] = jsonType
            
            // Apply generation guides
            for guide in guides {
                guide.applyToSchema(&result)
            }
        }
        
        return result
    }
}

extension GenerationSchema {
    public struct Property: Sendable {
        internal let name: String
        
        internal let type: any Generable.Type
        
        internal let description: String?
        
        internal let regexPatterns: [String]
        
        internal let guides: [AnyGenerationGuide]
        
        public init<Value>(name: String, description: String? = nil, type: Value.Type, guides: [GenerationGuide<Value>] = []) where Value: Generable {
            self.name = name
            self.description = description
            self.type = type
            self.regexPatterns = []
            self.guides = guides.map(AnyGenerationGuide.init)
        }
        
        
        public init<RegexOutput>(name: String, description: String? = nil, type: String.Type, guides: [Regex<RegexOutput>] = []) {
            self.name = name
            self.description = description
            self.type = type
            self.regexPatterns = guides.map { String(describing: $0) }
            self.guides = []
        }
        
        
        internal init(
            name: String,
            description: String?,
            type: any Generable.Type,
            guides: [AnyGenerationGuide] = [],
            regexPatterns: [String] = []
        ) {
            self.name = name
            self.description = description
            self.type = type
            self.guides = guides
            self.regexPatterns = regexPatterns
        }
        
        internal var typeDescription: String {
            return String(describing: type)
        }
        
        internal var propertyDescription: String {
            return description ?? ""
        }
    }
}

extension GenerationSchema {
    
    public func encode(to encoder: Encoder) throws {
        // Convert to JSON Schema format using toSchemaDictionary()
        let jsonSchema = self.toSchemaDictionary()
        
        // Directly encode the schema dictionary using AnyCodable
        var container = encoder.singleValueContainer()
        let encodableDict = AnyCodable(jsonSchema)
        try container.encode(encodableDict)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Decode as generic JSON structure
        let jsonDict = try container.decode(AnyCodable.self)
        
        guard let dict = jsonDict.value as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected dictionary for GenerationSchema"
                )
            )
        }
        
        // Parse JSON Schema format
        if let type = dict["type"] as? String {
            switch type {
            case "object":
                self.schemaType = .object(properties: Self.parsePropertiesUnified(from: dict))
            case "string":
                if let enumValues = dict["enum"] as? [String] {
                    // Create anyOf with string constants
                    let schemas = enumValues.map { value in
                        SchemaType.generic(
                            type: String.self,
                            guides: [AnyGenerationGuide(GenerationGuide<String>.constant(value))]
                        )
                    }
                    self.schemaType = .anyOf(schemas)
                } else {
                    self.schemaType = .generic(type: String.self, guides: [])
                }
            case "integer":
                self.schemaType = .generic(type: Int.self, guides: [])
            case "number":
                self.schemaType = .generic(type: Double.self, guides: [])
            case "boolean":
                self.schemaType = .generic(type: Bool.self, guides: [])
            case "array":
                let element: SchemaType
                if let items = dict["items"] as? [String: Any] {
                    // Recursively parse item schema
                    let itemData = try JSONSerialization.data(withJSONObject: items)
                    let itemSchema = try JSONDecoder().decode(GenerationSchema.self, from: itemData)
                    element = itemSchema.schemaType
                } else {
                    element = .generic(type: String.self, guides: [])
                }
                let minItems = dict["minItems"] as? Int
                let maxItems = dict["maxItems"] as? Int
                self.schemaType = .array(element: element, minItems: minItems, maxItems: maxItems)
            default:
                // Try to infer type
                let generableType: any Generable.Type = switch type {
                case "string": String.self
                case "integer": Int.self
                case "number": Double.self
                case "boolean": Bool.self
                default: String.self
                }
                self.schemaType = .generic(type: generableType, guides: [])
            }
        } else if dict["anyOf"] != nil {
            // Handle union types - for now treat as object
            self.schemaType = .object(properties: [])
        } else {
            // Set default values before throwing
            self.schemaType = .object(properties: [])
            self._description = nil
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to determine schema type from JSON"
                )
            )
        }
        
        self._description = dict["description"] as? String
    }
    
    // Helper method to parse properties from JSON Schema (unified)
    private static func parsePropertiesUnified(from dict: [String: Any]) -> [PropertyInfo] {
        guard let properties = dict["properties"] as? [String: [String: Any]] else {
            return []
        }
        
        let required = dict["required"] as? [String] ?? []
        
        return properties.compactMap { key, value in
            // Create a GenerationSchema for each property
            let propSchema: GenerationSchema
            do {
                let propData = try JSONSerialization.data(withJSONObject: value)
                propSchema = try JSONDecoder().decode(GenerationSchema.self, from: propData)
            } catch {
                // Fallback to string type
                propSchema = GenerationSchema(
                    schemaType: .generic(type: String.self, guides: []),
                    description: value["description"] as? String
                )
            }
            
            return PropertyInfo(
                name: key,
                description: value["description"] as? String,
                type: propSchema.schemaType,
                isOptional: !required.contains(key)  // Check if in required array
            )
        }.sorted { $0.name < $1.name }
    }
    
    // Helper to infer type from JSON Schema
    private static func inferTypeFromSchema(_ schema: [String: Any]) -> any Generable.Type {
        guard let type = schema["type"] as? String else {
            return String.self
        }
        
        switch type {
        case "string":
            return String.self
        case "integer":
            return Int.self
        case "number":
            return Double.self
        case "boolean":
            return Bool.self
        case "array":
            return [String].self // Default array type
        case "object":
            return [String: String].self // Default object type
        default:
            return String.self
        }
    }
    
}

extension GenerationSchema.Property: Codable {
    private enum CodingKeys: String, CodingKey {
        case name, description, typeString, regexPatterns, isOptional
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(String(describing: type), forKey: .typeString)
        try container.encode(regexPatterns, forKey: .regexPatterns)
        // Note: guides are not encoded as they are type-erased
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        let _ = try container.decode(String.self, forKey: .typeString)
        self.type = String.self // Default type as we cannot reconstruct the actual type
        self.regexPatterns = try container.decode([String].self, forKey: .regexPatterns)
        self.guides = [] // Guides cannot be reconstructed from encoded data
    }
}

// MARK: - AnyCodable Helper

/// A type-erased Codable value for handling [String: Any] in Codable contexts
internal struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode AnyCodable"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Unable to encode AnyCodable"
                )
            )
        }
    }
}

extension GenerationSchema {
    public enum SchemaError: Error, LocalizedError {
        case duplicateProperty(schema: String, property: String, context: Context)
        
        case duplicateType(schema: String?, type: String, context: Context)
        
        case emptyTypeChoices(schema: String, context: Context)
        
        case undefinedReferences(schema: String?, references: [String], context: Context)
        
        public struct Context: Sendable {
            public let debugDescription: String
            
            public init(debugDescription: String) {
                self.debugDescription = debugDescription
            }
            
            internal init(location: String, additionalInfo: [String: String] = [:]) {
                var desc = "Context(location: \(location)"
                if !additionalInfo.isEmpty {
                    desc += ", info: \(additionalInfo)"
                }
                desc += ")"
                self.debugDescription = desc
            }
        }
        
        public var errorDescription: String? {
            switch self {
            case .duplicateProperty(let schema, let property, let context):
                return "Duplicate property '\(property)' found in schema '\(schema)': \(context.debugDescription)"
            case .duplicateType(let schema, let type, let context):
                return "Duplicate type '\(type)' found\(schema.map { " in schema '\($0)'" } ?? ""): \(context.debugDescription)"
            case .emptyTypeChoices(let schema, let context):
                return "Empty type choices in anyOf schema '\(schema)': \(context.debugDescription)"
            case .undefinedReferences(let schema, let references, let context):
                return "Undefined references \(references) found\(schema.map { " in schema '\($0)'" } ?? ""): \(context.debugDescription)"
            }
        }
        
        public var recoverySuggestion: String? {
            switch self {
            case .duplicateProperty(_, let property, _):
                return "Ensure each property name '\(property)' is unique within the schema"
            case .duplicateType(_, let type, _):
                return "Ensure each type name '\(type)' is unique across all schemas"
            case .emptyTypeChoices(let schema, _):
                return "Provide at least one type choice for the anyOf schema '\(schema)'"
            case .undefinedReferences(_, let references, _):
                return "Define the referenced schemas: \(references.joined(separator: ", "))"
            }
        }
    }
}
