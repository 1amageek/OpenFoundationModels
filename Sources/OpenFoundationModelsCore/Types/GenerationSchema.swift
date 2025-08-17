import Foundation

public struct GenerationSchema: Sendable, Equatable, CustomDebugStringConvertible {
    private let schemaType: SchemaType
    private let _description: String?
    private indirect enum SchemaType: Sendable, Equatable {
        case object(properties: [GenerationSchema.Property])
        case enumeration(values: [String])
        case dynamic(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema])
        case array(items: GenerationSchema?)
        case primitive(type: String)
    }
    internal var type: String {
        switch schemaType {
        case .object:
            return "object"
        case .enumeration:
            return "string"
        case .dynamic:
            return "object"
        case .array:
            return "array"
        case .primitive(type: let type):
            return type
        }
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
            let props: [GenerationSchema.Property] = (properties ?? [:]).map { (name, schema) in
                let isOptional = !(required?.contains(name) ?? false)
                return GenerationSchema.Property(
                    name: name,
                    description: schema._description,
                    type: String.self, // Default type, as we can't infer the actual type
                    guides: [],
                    regexPatterns: [],
                    isOptional: isOptional
                )
            }.sorted { $0.name < $1.name }
            self.schemaType = .object(properties: props)
        } else if type == "array" {
            self.schemaType = .array(items: items)
        } else if type == "string" && !anyOf.isEmpty {
            let values = anyOf.compactMap { schema -> String? in
                return nil // Simplified for now
            }
            self.schemaType = .enumeration(values: values)
        } else {
            self.schemaType = .primitive(type: type)
        }
    }
    
    
    public init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws {
        self.schemaType = .dynamic(root: root, dependencies: dependencies)
        self._description = nil
    }
    
    public init(type: any Generable.Type, description: String? = nil, anyOf choices: [String]) {
        self.schemaType = .enumeration(values: choices)
        self._description = description
    }
    
    public init(type: any Generable.Type, description: String? = nil, properties: [GenerationSchema.Property]) {
        self.schemaType = .object(properties: properties)
        self._description = description
    }
    
    private init(schemaType: SchemaType, description: String? = nil) {
        self.schemaType = schemaType
        self._description = description
    }
    
    
    public var debugDescription: String {
        switch schemaType {
        case .object(let properties):
            let propList = properties.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
            return "GenerationSchema(object: [\(propList)])"
        case .enumeration(let values):
            return "GenerationSchema(enum: \(values))"
        case .dynamic(_, let dependencies):
            return "GenerationSchema(dynamic: root + \(dependencies.count) dependencies)"
        case .array(let items):
            if let items = items {
                return "GenerationSchema(array of: \(items.debugDescription))"
            } else {
                return "GenerationSchema(array)"
            }
        case .primitive(type: let type):
            return "GenerationSchema(\(type))"
        }
    }
    
    internal func toSchemaDictionary() -> [String: Any] {
        switch schemaType {
        case .object(let properties):
            var schema: [String: Any] = [
                "type": "object"
            ]
            
            if let description = _description {
                schema["description"] = description
            }
            
            if !properties.isEmpty {
                var propertiesDict: [String: Any] = [:]
                var requiredFields: [String] = []
                
                for property in properties {
                    var propertySchema: [String: Any] = [
                        "type": mapPropertyType(property.typeDescription)
                    ]
                    
                    if !property.propertyDescription.isEmpty {
                        propertySchema["description"] = property.propertyDescription
                    }
                    
                    if property.type == String.self && !property.regexPatterns.isEmpty {
                        if let lastRegex = property.regexPatterns.last {
                            propertySchema["pattern"] = String(describing: lastRegex)
                        }
                    }
                    
                    for guide in property.guides {
                        applyGuide(guide, to: &propertySchema)
                    }
                    
                    propertiesDict[property.name] = propertySchema
                    if !property.isOptional {
                        requiredFields.append(property.name)
                    }
                }
                
                schema["properties"] = propertiesDict
                if !requiredFields.isEmpty {
                    schema["required"] = requiredFields
                }
            }
            
            return schema
            
        case .enumeration(let values):
            var schema: [String: Any] = [
                "type": "string",
                "enum": values
            ]
            
            if let description = _description {
                schema["description"] = description
            }
            
            return schema
            
        case .dynamic(_, _):
            var schema: [String: Any] = [
                "type": "object"
            ]
            
            if let description = _description {
                schema["description"] = description
            }
            
            return schema
            
        case .array(let items):
            var schema: [String: Any] = [
                "type": "array"
            ]
            if let description = _description {
                schema["description"] = description
            }
            if let items = items {
                schema["items"] = items.toSchemaDictionary()
            }
            return schema
            
        case .primitive(type: let type):
            var schema: [String: Any] = [
                "type": type
            ]
            if let description = _description {
                schema["description"] = description
            }
            return schema
        }
    }
    
    private func mapPropertyType(_ type: String) -> String {
        switch type.lowercased() {
        case "string":
            return "string"
        case "int", "integer":
            return "integer"
        case "double", "float":
            return "number"
        case "bool", "boolean":
            return "boolean"
        case let t where t.contains("array") || t.contains("["):
            return "array"
        case let t where t.contains("dictionary") || t.contains("["):
            return "object"
        default:
            return "string"
        }
    }
    
    private func applyGuide(_ guide: AnyGenerationGuide, to schema: inout [String: Any]) {
        guide.applyToSchema(&schema)
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


extension GenerationSchema {
    public struct Property: Sendable {
        public let name: String
        
        public let type: any Sendable.Type
        
        public let description: String?
        
        internal let regexPatterns: [String]
        
        internal let guides: [AnyGenerationGuide]
        
        public let isOptional: Bool
        
        public init<Value>(name: String, description: String? = nil, type: Value.Type, guides: [GenerationGuide<Value>] = []) where Value: Generable, Value: Sendable {
            self.name = name
            self.description = description
            self.type = type
            self.regexPatterns = []
            self.guides = guides.map(AnyGenerationGuide.init)
            self.isOptional = false
        }
        
        public init<Value>(name: String, description: String? = nil, type: Value?.Type, guides: [GenerationGuide<Value>] = []) where Value: Generable, Value: Sendable {
            self.name = name
            self.description = description
            self.type = type
            self.regexPatterns = []
            self.guides = guides.map(AnyGenerationGuide.init)
            self.isOptional = true
        }
        
        public init<RegexOutput>(name: String, description: String? = nil, type: String.Type, guides: [Regex<RegexOutput>] = []) {
            self.name = name
            self.description = description
            self.type = type
            self.regexPatterns = guides.map { String(describing: $0) }
            self.guides = []
            self.isOptional = false
        }
        
        public init<RegexOutput>(name: String, description: String? = nil, type: String?.Type, guides: [Regex<RegexOutput>] = []) {
            self.name = name
            self.description = description
            self.type = type
            self.regexPatterns = guides.map { String(describing: $0) }
            self.guides = []
            self.isOptional = true
        }
        
        internal init(
            name: String,
            description: String?,
            type: any Sendable.Type,
            guides: [AnyGenerationGuide] = [],
            regexPatterns: [String] = [],
            isOptional: Bool
        ) {
            self.name = name
            self.description = description
            self.type = type
            self.guides = guides
            self.regexPatterns = regexPatterns
            self.isOptional = isOptional
        }
        
        internal var typeDescription: String {
            return String(describing: type)
        }
        
        internal var propertyDescription: String {
            return description ?? ""
        }
    }
}

extension GenerationSchema.Property: Equatable {
    public static func ==(lhs: GenerationSchema.Property, rhs: GenerationSchema.Property) -> Bool {
        return lhs.name == rhs.name && 
               String(describing: lhs.type) == String(describing: rhs.type) &&
               lhs.description == rhs.description &&
               lhs.guides == rhs.guides &&
               lhs.regexPatterns == rhs.regexPatterns &&
               lhs.isOptional == rhs.isOptional
    }
}

extension GenerationSchema {
    public enum SchemaError: Error, LocalizedError, Sendable {
        case duplicateProperty(schema: String, property: String, context: Context)
        
        case duplicateType(schema: String?, type: String, context: Context)
        
        case emptyTypeChoices(schema: String, context: Context)
        
        case undefinedReferences(schema: String?, references: [String], context: Context)
        
        public struct Context: CustomDebugStringConvertible, Sendable {
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
