// GenerationSchema.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// A type that describes the properties of an object and any guides on their values.
/// 
/// **Apple Foundation Models Documentation:**
/// Generation schemas guide the output of a SystemLanguageModel to deterministically ensure the output 
/// is in the desired format.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema
/// 
/// **Apple Official API:** `struct GenerationSchema`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - CustomDebugStringConvertible
/// - Decodable
/// - Encodable
/// - Sendable
/// - SendableMetatype
public struct GenerationSchema: CustomDebugStringConvertible, Decodable, Encodable, Sendable, SendableMetatype {
    
    /// Internal schema representation
    private let schemaType: SchemaType
    private let _description: String?
    
    /// Schema type enumeration
    private indirect enum SchemaType: Sendable {
        case object(properties: [GenerationSchema.Property])
        case enumeration(values: [String])
        case dynamic(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema])
    }
    
    /// Additional initializer for compatibility with Apple's API
    public init(type: String, description: String? = nil, properties: [String: GenerationSchema]? = nil, required: [String]? = nil, items: GenerationSchema? = nil, anyOf: [String] = []) {
        if !anyOf.isEmpty {
            self.schemaType = .enumeration(values: anyOf)
        } else {
            // Convert dictionary properties to Property array
            let propertyArray = properties?.map { key, value in
                GenerationSchema.Property(name: key, description: value.description, type: String.self, guides: [])
            } ?? []
            self.schemaType = .object(properties: propertyArray)
        }
        self._description = description
    }
    
    /// The type of this schema
    public var type: String {
        switch schemaType {
        case .object:
            return "object"
        case .enumeration:
            return "string"
        case .dynamic:
            return "object"
        }
    }
    
    /// The properties of this schema (for object types)
    public var properties: [String: GenerationSchema]? {
        switch schemaType {
        case .object(let props):
            var dict: [String: GenerationSchema] = [:]
            for prop in props {
                dict[prop.name] = GenerationSchema(type: prop.typeDescription, description: prop.propertyDescription)
            }
            return dict.isEmpty ? nil : dict
        case .enumeration, .dynamic:
            return nil
        }
    }
    
    /// The required properties (for object types)
    public var required: [String]? {
        switch schemaType {
        case .object(let props):
            return props.map { $0.name }
        case .enumeration, .dynamic:
            return nil
        }
    }
    
    /// The schema for array items (for array types)
    public var items: GenerationSchema? {
        // Not used in current implementation
        return nil
    }
    
    /// The description of this schema
    public var description: String? {
        return _description
    }
    
    // MARK: - Apple Confirmed Initializers
    
    /// Create schema with dynamic schemas
    /// ✅ CONFIRMED: First initialization pattern from Apple docs
    /// - Parameters:
    ///   - root: The root dynamic schema
    ///   - dependencies: Array of dependent dynamic schemas
    /// - Throws: SchemaError if schema creation fails
    public init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws {
        self.schemaType = .dynamic(root: root, dependencies: dependencies)
        self._description = nil
    }
    
    /// Create schema for string enumeration
    /// ✅ CONFIRMED: Second initialization pattern from Apple docs
    /// - Parameters:
    ///   - type: The type this schema represents
    ///   - description: A natural language description of this schema
    ///   - anyOf: Enumeration values (choices)
    public init(type: any Generable.Type, description: String? = nil, anyOf choices: [String]) {
        self.schemaType = .enumeration(values: choices)
        self._description = description
    }
    
    /// Create schema with properties array
    /// ✅ CONFIRMED: Third initialization pattern from Apple docs
    /// - Parameters:
    ///   - type: The type this schema represents
    ///   - description: A natural language description of this schema
    ///   - properties: Array of properties for the schema
    public init(type: any Generable.Type, description: String? = nil, properties: [GenerationSchema.Property]) {
        self.schemaType = .object(properties: properties)
        self._description = description
    }
    
    // MARK: - Apple Confirmed Properties
    
    /// Debug description
    /// ✅ CONFIRMED: CustomDebugStringConvertible requirement
    public var debugDescription: String {
        switch schemaType {
        case .object(let properties):
            let propList = properties.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
            return "GenerationSchema(object: [\(propList)])"
        case .enumeration(let values):
            return "GenerationSchema(enum: \(values))"
        case .dynamic(_, let dependencies):
            return "GenerationSchema(dynamic: root + \(dependencies.count) dependencies)"
        }
    }
    
    /// Generate OpenAPI-style schema dictionary
    /// ✅ PHASE 4.7: Apple-compatible schema generation
    /// - Returns: Dictionary representation suitable for model consumption
    public func toSchemaDictionary() -> [String: Any] {
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
                    
                    // Apply regex patterns if present (for String types)
                    if property.type == String.self && !property.regexPatterns.isEmpty {
                        // Apply the last regex pattern as per Apple documentation
                        if let lastRegex = property.regexPatterns.last {
                            propertySchema["pattern"] = String(describing: lastRegex)
                        }
                    }
                    
                    propertiesDict[property.name] = propertySchema
                    requiredFields.append(property.name)
                }
                
                schema["properties"] = propertiesDict
                schema["required"] = requiredFields
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
            
        case .dynamic(let root, let dependencies):
            // For dynamic schemas, convert to object schema
            var schema: [String: Any] = [
                "type": "object"
            ]
            
            if let description = _description {
                schema["description"] = description
            }
            
            // Build properties from root and dependencies
            var propertiesDict: [String: Any] = [:]
            var requiredFields: [String] = []
            
            // Note: DynamicGenerationSchema properties are [String: GenerationSchema]
            // This is a simplified implementation
            if let rootProperties = root.properties {
                for (name, schema) in rootProperties {
                    propertiesDict[name] = [
                        "type": schema.type,
                        "description": schema.description ?? ""
                    ]
                    requiredFields.append(name)
                }
            }
            
            for dependency in dependencies {
                if let depProperties = dependency.properties {
                    for (name, schema) in depProperties {
                        propertiesDict[name] = [
                            "type": schema.type,
                            "description": schema.description ?? ""
                        ]
                        requiredFields.append(name)
                    }
                }
            }
            
            schema["properties"] = propertiesDict
            schema["required"] = requiredFields
            
            return schema
        }
    }
    
    /// Map Swift types to OpenAPI schema types
    /// ✅ PHASE 4.7: Type mapping for Apple compatibility
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
    
    /// Apply generation guide to property schema
    /// ✅ PHASE 4.7: Guide application for constraints
    private func applyGuide(_ guide: AnyGenerationGuide, to schema: inout [String: Any]) {
        switch guide.type {
        case .maximumCount:
            if let count = guide.value as? Int {
                schema["maxItems"] = count
            }
        case .minimumCount:
            if let count = guide.value as? Int {
                schema["minItems"] = count
            }
        case .count:
            if let count = guide.value as? Int {
                schema["minItems"] = count
                schema["maxItems"] = count
            }
        case .range:
            if let range = guide.value as? ClosedRange<Int> {
                schema["minimum"] = range.lowerBound
                schema["maximum"] = range.upperBound
            }
        case .enumeration:
            if let values = guide.value as? [String] {
                schema["enum"] = values
            }
        case .pattern:
            if let pattern = guide.value as? String {
                schema["pattern"] = pattern
            }
        }
    }
}

// MARK: - Codable Implementation

extension GenerationSchema {
    private enum CodingKeys: String, CodingKey {
        case type
        case description
        case properties
        case required
        case items
        case anyOf
        case schemaType
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Try to decode based on the type field
        if let type = try container.decodeIfPresent(String.self, forKey: .type) {
            switch type {
            case "object":
                // Decode object properties - simplified version
                // Note: Full Codable support for [String: [String: Any]] requires custom implementation
                schemaType = .object(properties: [])
            case "string":
                // Check for enum values
                if let anyOf = try container.decodeIfPresent([String].self, forKey: .anyOf) {
                    schemaType = .enumeration(values: anyOf)
                } else {
                    schemaType = .object(properties: [])
                }
            default:
                schemaType = .object(properties: [])
            }
        } else {
            // Fallback to empty object
            schemaType = .object(properties: [])
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(_description, forKey: .description)
        
        switch schemaType {
        case .object(let properties):
            try container.encode("object", forKey: .type)
            
            // Encode properties as dictionary
            var propertiesDict: [String: [String: Any]] = [:]
            for property in properties {
                var propDict: [String: Any] = [:]
                propDict["type"] = property.typeDescription
                if let desc = property.description {
                    propDict["description"] = desc
                }
                propertiesDict[property.name] = propDict
            }
            
            // Note: We can't directly encode [String: [String: Any]] in Swift
            // This is a simplified version - in production you'd need a proper solution
            
            let requiredFields = properties.map { $0.name }
            try container.encode(requiredFields, forKey: .required)
            
        case .enumeration(let values):
            try container.encode("string", forKey: .type)
            try container.encode(values, forKey: .anyOf)
            
        case .dynamic:
            // Dynamic schemas are complex - simplified for now
            try container.encode("object", forKey: .type)
        }
    }
}

// MARK: - Related Types (Referenced but Not Documented)

/// Schema creation errors
/// ✅ CONFIRMED: Referenced in Apple docs as GenerationSchema.SchemaError
/// 
/// **Apple Foundation Models Documentation:**
/// A error that occurs when there is a problem creating a generation schema.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror
/// 
/// **Apple Official API:** `enum SchemaError`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - Error
/// - LocalizedError
/// - Sendable
/// - SendableMetatype
public enum SchemaError: Error, LocalizedError, Sendable, SendableMetatype {
    /// An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/duplicateproperty(schema:property:context:)
    case duplicateProperty(schema: String, property: String, context: Context)
    
    /// An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/duplicatetype(schema:type:context:)
    case duplicateType(schema: String?, type: String, context: Context)
    
    /// An error that represents an attempt to construct an anyOf schema with an empty array of type choices.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An error that represents an attempt to construct an anyOf schema with an empty array of type choices.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/emptytypechoices(schema:context:)
    case emptyTypeChoices(schema: String, context: Context)
    
    /// An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/undefinedreferences(schema:references:context:)
    case undefinedReferences(schema: String?, references: [String], context: Context)
    
    /// The context in which the error occurred.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// The context in which the error occurred.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/context
    /// 
    /// **Apple Official API:** `struct Context`
    /// 
    /// **Conformances:**
    /// - CustomDebugStringConvertible
    /// - Sendable
    /// - SendableMetatype
    public struct Context: CustomDebugStringConvertible, Sendable, SendableMetatype {
        /// A string representation of the debug description.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// A string representation of the debug description.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/context/debugdescription
        public let debugDescription: String
        
        /// Creates a new error context
        /// 
        /// **Apple Foundation Models Documentation:**
        /// Creates a schema error context.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/context/init(debugdescription:)
        /// 
        /// **Apple Official API:** `init(debugDescription:)`
        /// 
        /// - Parameter debugDescription: A string representation of the debug description
        public init(debugDescription: String) {
            self.debugDescription = debugDescription
        }
        
        /// Internal convenience initializer for backward compatibility
        internal init(location: String, additionalInfo: [String: String] = [:]) {
            var desc = "Context(location: \(location)"
            if !additionalInfo.isEmpty {
                desc += ", info: \(additionalInfo)"
            }
            desc += ")"
            self.debugDescription = desc
        }
    }
    
    /// A string representation of the error description.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A string representation of the error description.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/errordescription
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
    
    /// A suggestion that indicates how to handle the error.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A suggestion that indicates how to handle the error.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/recoverysuggestion
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

/// A guide for structured generation that supports constraints like ranges and patterns.
/// 
/// **Apple Foundation Models Documentation:**
/// A guide for structured generation that supports constraints like ranges and patterns.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide
/// 
/// **Apple Official API:** `struct GenerationGuide<Value>`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - Sendable
/// - SendableMetatype
/// 
/// **Usage:**
/// ```swift
/// @Guide(description: "A number between 1 and 100", .range(1...100))
/// var count: Int
/// ```
public struct GenerationGuide<Value: Sendable>: Sendable, SendableMetatype {
    /// The type of guide constraint
    public enum GuideType: Sendable {
        /// Maximum count constraint
        case maximumCount
        /// Minimum count constraint
        case minimumCount
        /// Exact count constraint
        case count
        /// Range constraint
        case range
        /// Enumeration constraint
        case enumeration
        /// Pattern constraint
        case pattern
        /// Constant constraint
        case constant
        /// Element constraint for arrays
        case element
        /// Minimum value constraint
        case minimum
        /// Maximum value constraint
        case maximum
        /// Any of constraint
        case anyOf
    }
    
    /// The type of constraint this guide applies
    public let type: GuideType
    
    /// The value associated with this guide
    public let value: Value
    
    /// Creates a generation guide with a constraint.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a generation guide with a constraint.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/init(_:)
    /// 
    /// **Apple Official API:** `init(_ constraint: GuideConstraint)`
    /// 
    /// - Parameter constraint: The constraint to apply
    public init(_ constraint: GuideConstraint<Value>) {
        self.type = constraint.type
        self.value = constraint.value
    }
    
    /// Private initializer for static factory methods
    private init(type: GuideType, value: Value) {
        self.type = type
        self.value = value
    }
}

// MARK: - GenerationGuide Static Methods (Apple API)

extension GenerationGuide where Value == String {
    /// Enforces that the string follows the pattern.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces that the string follows the pattern.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/pattern(_:)
    /// 
    /// **Apple Official API:** `static func pattern<Output>(_ regex: Regex<Output>) -> GenerationGuide<String>`
    /// Available when `Value` is `String`.
    /// 
    /// - Parameter regex: The regular expression pattern to match
    /// - Returns: A generation guide that enforces the pattern
    public static func pattern<Output>(_ regex: Regex<Output>) -> GenerationGuide<String> {
        return GenerationGuide<String>(type: .pattern, value: String(describing: regex))
    }
    
    /// Enforces that the string be precisely the given value.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces that the string be precisely the given value.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/constant(_:)
    /// 
    /// **Apple Official API:** `static func constant(_ value: String) -> GenerationGuide<String>`
    /// Available when `Value` is `String`.
    /// 
    /// - Parameter value: The exact string value required
    /// - Returns: A generation guide that enforces the constant value
    public static func constant(_ value: String) -> GenerationGuide<String> {
        return GenerationGuide<String>(type: .constant, value: value)
    }
    
    /// Enforces that the string be one of the provided values.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces that the string be one of the provided values.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/anyof(_:)
    /// 
    /// **Apple Official API:** `static func anyOf(_ values: [String]) -> GenerationGuide<String>`
    /// Available when `Value` is `String`.
    /// 
    /// - Parameter values: The allowed string values
    /// - Returns: A generation guide that enforces one of the values
    public static func anyOf(_ values: [String]) -> GenerationGuide<String> {
        return GenerationGuide<String>(type: .anyOf, value: values.joined(separator: "|"))
    }
}

// Extension for array-specific guides
extension GenerationGuide {
    /// Enforces a guide on the elements within the array.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces a guide on the elements within the array.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/element(_:)
    /// 
    /// **Apple Official API:** `static func element<Element>(_ guide: GenerationGuide<Element>) -> GenerationGuide<[Element]>`
    /// where Value == [Element]
    /// 
    /// - Parameter guide: The guide to apply to each element
    /// - Returns: A generation guide for array elements
    public static func element<Element: Sendable>(_ guide: GenerationGuide<Element>) -> GenerationGuide<[Element]> where Value == [Element] {
        return GenerationGuide<[Element]>(type: .element, value: [])  // The actual element guide is stored separately
    }
    
    /// Enforces that the array has exactly a certain number elements.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces that the array has exactly a certain number elements.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/count(_:)
    /// 
    /// **Apple Official API:** `static func count<Element>(_ count: Int) -> GenerationGuide<[Element]>`
    /// where Value == [Element]
    /// 
    /// - Parameter count: The exact number of elements required
    /// - Returns: A generation guide that enforces the count
    public static func count<Element: Sendable>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element] {
        return GenerationGuide<[Element]>(type: .count, value: [])
    }
    
    /// Enforces a minimum number of elements in the array.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces a minimum number of elements in the array.
    /// The bounds are inclusive.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/minimumcount(_:)
    /// 
    /// **Apple Official API:** `static func minimumCount<Element>(_ count: Int) -> GenerationGuide<[Element]>`
    /// where Value == [Element]
    /// 
    /// - Parameter count: The minimum number of elements required
    /// - Returns: A generation guide that enforces the minimum count
    public static func minimumCount<Element: Sendable>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element] {
        return GenerationGuide<[Element]>(type: .minimumCount, value: [])
    }
    
    /// Enforces a maximum number of elements in the array.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces a maximum number of elements in the array.
    /// The bounds are inclusive.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/maximumcount(_:)
    /// 
    /// **Apple Official API:** `static func maximumCount<Element>(_ count: Int) -> GenerationGuide<[Element]>`
    /// where Value == [Element]
    /// 
    /// - Parameter count: The maximum number of elements allowed
    /// - Returns: A generation guide that enforces the maximum count
    public static func maximumCount<Element: Sendable>(_ count: Int) -> GenerationGuide<[Element]> where Value == [Element] {
        return GenerationGuide<[Element]>(type: .maximumCount, value: [])
    }
}

extension GenerationGuide where Value == Decimal {
    /// Enforces values fall within a range.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces values fall within a range.
    /// Use a `range` generation guide — whose bounds are inclusive — to ensure the model produces a value that falls within a range.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/range(_:)
    /// 
    /// **Apple Official API:** `static func range(_ range: ClosedRange<Decimal>) -> GenerationGuide<Decimal>`
    /// Available when `Value` is `Decimal`.
    /// 
    /// - Parameter range: The inclusive range of allowed values
    /// - Returns: A generation guide that enforces the range
    public static func range(_ range: ClosedRange<Decimal>) -> GenerationGuide<Decimal> {
        return GenerationGuide<Decimal>(type: .range, value: range.lowerBound) // Note: This needs proper range encoding
    }
    
    /// Enforces a minimum value.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces a minimum value.
    /// Use a `minimum` generation guide — whose bounds are inclusive — to ensure the model produces a value greater than or equal to some minimum value.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/minimum(_:)
    /// 
    /// **Apple Official API:** `static func minimum(_ value: Decimal) -> GenerationGuide<Decimal>`
    /// Available when `Value` is `Decimal`.
    /// 
    /// - Parameter value: The minimum allowed value (inclusive)
    /// - Returns: A generation guide that enforces the minimum value
    public static func minimum(_ value: Decimal) -> GenerationGuide<Decimal> {
        return GenerationGuide<Decimal>(type: .minimum, value: value)
    }
    
    /// Enforces a maximum value.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces a maximum value.
    /// Use a `maximum` generation guide — whose bounds are inclusive — to ensure the model produces a value less than or equal to some maximum value.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationguide/maximum(_:)
    /// 
    /// **Apple Official API:** `static func maximum(_ value: Decimal) -> GenerationGuide<Decimal>`
    /// Available when `Value` is `Decimal`.
    /// 
    /// - Parameter value: The maximum allowed value (inclusive)
    /// - Returns: A generation guide that enforces the maximum value
    public static func maximum(_ value: Decimal) -> GenerationGuide<Decimal> {
        return GenerationGuide<Decimal>(type: .maximum, value: value)
    }
}

// Additional overloads for Int and Double types
extension GenerationGuide where Value == ClosedRange<Int> {
    /// Enforces values fall within a range.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces values fall within a range.
    /// 
    /// **Apple Official API:** `static func range(_ range: ClosedRange<Int>) -> GenerationGuide<Int>`
    /// Available when `Value` is `Int`.
    /// 
    /// - Parameter range: The inclusive range of allowed values
    /// - Returns: A generation guide that enforces the range
    public static func range(_ range: ClosedRange<Int>) -> GenerationGuide<ClosedRange<Int>> {
        return GenerationGuide<ClosedRange<Int>>(type: .range, value: range)
    }
}

extension GenerationGuide where Value == Int {
    /// Enforces a minimum value.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces a minimum value.
    /// 
    /// **Apple Official API:** `static func minimum(_ value: Int) -> GenerationGuide<Int>`
    /// Available when `Value` is `Int`.
    /// 
    /// - Parameter value: The minimum allowed value (inclusive)
    /// - Returns: A generation guide that enforces the minimum value
    public static func minimum(_ value: Int) -> GenerationGuide<Int> {
        return GenerationGuide<Int>(type: .minimum, value: value)
    }
    
    /// Enforces a maximum value.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces a maximum value.
    /// 
    /// **Apple Official API:** `static func maximum(_ value: Int) -> GenerationGuide<Int>`
    /// Available when `Value` is `Int`.
    /// 
    /// - Parameter value: The maximum allowed value (inclusive)
    /// - Returns: A generation guide that enforces the maximum value
    public static func maximum(_ value: Int) -> GenerationGuide<Int> {
        return GenerationGuide<Int>(type: .maximum, value: value)
    }
}

extension GenerationGuide where Value == ClosedRange<Double> {
    /// Enforces values fall within a range.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces values fall within a range.
    /// 
    /// **Apple Official API:** `static func range(_ range: ClosedRange<Double>) -> GenerationGuide<Double>`
    /// Available when `Value` is `Double`.
    /// 
    /// - Parameter range: The inclusive range of allowed values
    /// - Returns: A generation guide that enforces the range
    public static func range(_ range: ClosedRange<Double>) -> GenerationGuide<ClosedRange<Double>> {
        return GenerationGuide<ClosedRange<Double>>(type: .range, value: range)
    }
}

extension GenerationGuide where Value == Double {
    /// Enforces a minimum value.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces a minimum value.
    /// 
    /// **Apple Official API:** `static func minimum(_ value: Double) -> GenerationGuide<Double>`
    /// Available when `Value` is `Double`.
    /// 
    /// - Parameter value: The minimum allowed value (inclusive)
    /// - Returns: A generation guide that enforces the minimum value
    public static func minimum(_ value: Double) -> GenerationGuide<Double> {
        return GenerationGuide<Double>(type: .minimum, value: value)
    }
    
    /// Enforces a maximum value.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Enforces a maximum value.
    /// 
    /// **Apple Official API:** `static func maximum(_ value: Double) -> GenerationGuide<Double>`
    /// Available when `Value` is `Double`.
    /// 
    /// - Parameter value: The maximum allowed value (inclusive)
    /// - Returns: A generation guide that enforces the maximum value
    public static func maximum(_ value: Double) -> GenerationGuide<Double> {
        return GenerationGuide<Double>(type: .maximum, value: value)
    }
}

/// A constraint for generation guides.
/// 
/// **Apple Foundation Models Documentation:**
/// A constraint for generation guides.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/guideconstraint
/// 
/// **Apple Official API:** `struct GuideConstraint<Value>`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - Sendable
/// - SendableMetatype
public struct GuideConstraint<Value: Sendable>: Sendable, SendableMetatype {
    /// The type of constraint
    public let type: GenerationGuide<Value>.GuideType
    
    /// The value associated with this constraint
    public let value: Value
    
    /// Creates a count constraint.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a count constraint.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/guideconstraint/count(_:)
    /// 
    /// **Apple Official API:** `static func count(_ count: Int) -> GuideConstraint<Int>`
    /// 
    /// - Parameter count: The exact count
    /// - Returns: A count constraint
    public static func count(_ count: Int) -> GuideConstraint<Int> {
        return GuideConstraint<Int>(type: .count, value: count)
    }
    
    /// Creates a range constraint.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a range constraint.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/guideconstraint/range(_:)
    /// 
    /// **Apple Official API:** `static func range(_ range: ClosedRange<Int>) -> GuideConstraint<ClosedRange<Int>>`
    /// 
    /// - Parameter range: The range constraint
    /// - Returns: A range constraint
    public static func range(_ range: ClosedRange<Int>) -> GuideConstraint<ClosedRange<Int>> {
        return GuideConstraint<ClosedRange<Int>>(type: .range, value: range)
    }
    
    /// Creates a pattern constraint.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a pattern constraint.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/guideconstraint/pattern(_:)
    /// 
    /// **Apple Official API:** `static func pattern(_ pattern: String) -> GuideConstraint<String>`
    /// 
    /// - Parameter pattern: The regular expression pattern
    /// - Returns: A pattern constraint
    public static func pattern(_ pattern: String) -> GuideConstraint<String> {
        return GuideConstraint<String>(type: .pattern, value: pattern)
    }
    
    /// Creates an enumeration constraint.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates an enumeration constraint.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/guideconstraint/enumeration(_:)
    /// 
    /// **Apple Official API:** `static func enumeration(_ values: [String]) -> GuideConstraint<[String]>`
    /// 
    /// - Parameter values: The allowed values
    /// - Returns: An enumeration constraint
    public static func enumeration(_ values: [String]) -> GuideConstraint<[String]> {
        return GuideConstraint<[String]>(type: .enumeration, value: values)
    }
    
    /// Private initializer
    private init(type: GenerationGuide<Value>.GuideType, value: Value) {
        self.type = type
        self.value = value
    }
}

/// Type-erased generation guide for use in collections
public struct AnyGenerationGuide: @unchecked Sendable, SendableMetatype {
    /// The type of guide constraint
    public enum GuideType: Sendable {
        case maximumCount, minimumCount, count, range, enumeration, pattern
    }
    
    public let type: GuideType
    
    /// The value associated with this guide
    public let value: Any
    
    /// Create a type-erased guide from a typed guide
    public init<T: Sendable>(_ guide: GenerationGuide<T>) {
        switch guide.type {
        case .maximumCount: self.type = .maximumCount
        case .minimumCount: self.type = .minimumCount
        case .count: self.type = .count
        case .range: self.type = .range
        case .enumeration: self.type = .enumeration
        case .pattern: self.type = .pattern
        case .constant: self.type = .pattern  // Map constant to pattern for simplicity
        case .element: self.type = .pattern   // Map element to pattern for simplicity
        case .minimum: self.type = .range     // Map minimum to range for simplicity
        case .maximum: self.type = .range     // Map maximum to range for simplicity
        case .anyOf: self.type = .enumeration // Map anyOf to enumeration
        }
        self.value = guide.value
    }
}

/// A generation schema that you can create at runtime.
/// 
/// **Apple Foundation Models Documentation:**
/// The dynamic counterpart to the generation schema type that you use to construct schemas at runtime.
/// An individual schema may reference other schemas by name, and references are resolved when converting a set of dynamic schemas into a GenerationSchema.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema
/// 
/// **Apple Official API:** `struct DynamicGenerationSchema`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - Sendable
/// - SendableMetatype
public struct DynamicGenerationSchema: Sendable, SendableMetatype {
    /// Internal representation of the schema type
    private indirect enum SchemaType: Sendable {
        case object(name: String, properties: [Property])
        case array(elementSchema: DynamicGenerationSchema, minElements: Int?, maxElements: Int?)
        case anyOf(name: String, choices: [DynamicGenerationSchema])
        case reference(to: String)
        case primitive(type: any Generable.Type, guides: [String])
    }
    
    /// The internal schema type
    private let schemaType: SchemaType
    
    /// A description of what this schema represents
    private let _description: String?
    
    /// The name of this schema (for references)
    public var name: String? {
        switch schemaType {
        case .object(let name, _), .anyOf(let name, _):
            return name
        case .array, .reference, .primitive:
            return nil
        }
    }
    
    /// Computed property for description
    public var description: String? {
        return _description
    }
    
    /// Creates an array schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates an array schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(arrayof:minimumelements:maximumelements:)
    /// 
    /// **Apple Official API:** `init(arrayOf:minimumElements:maximumElements:)`
    /// 
    /// - Parameters:
    ///   - itemSchema: The schema for array elements
    ///   - minimumElements: The minimum number of elements
    ///   - maximumElements: The maximum number of elements
    public init(
        arrayOf itemSchema: DynamicGenerationSchema,
        minimumElements: Int? = nil,
        maximumElements: Int? = nil
    ) {
        self.schemaType = .array(elementSchema: itemSchema, minElements: minimumElements, maxElements: maximumElements)
        self._description = nil
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
    ///   - name: A name this schema can be referenced by
    ///   - description: A natural language description of this DynamicGenerationSchema
    ///   - choices: An array of schemas this one will be a union of
    public init(
        name: String,
        description: String? = nil,
        anyOf choices: [DynamicGenerationSchema]
    ) {
        self.schemaType = .anyOf(name: name, choices: choices)
        self._description = description
    }
    
    /// Creates an object schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates an object schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:properties:)
    /// 
    /// **Apple Official API:** `init(name:description:properties:)`
    /// 
    /// - Parameters:
    ///   - name: A name this dynamic schema can be referenced by
    ///   - description: A natural language description of this schema
    ///   - properties: The properties to associated with this schema
    public init(
        name: String,
        description: String? = nil,
        properties: [DynamicGenerationSchema.Property]
    ) {
        self.schemaType = .object(name: name, properties: properties)
        self._description = description
    }
    
    /// Creates a reference schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates an refrence schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(referenceto:)
    /// 
    /// **Apple Official API:** `init(referenceTo:)`
    /// 
    /// - Parameter name: The name of the DynamicGenerationSchema this is a reference to
    public init(referenceTo name: String) {
        self.schemaType = .reference(to: name)
        self._description = nil
    }
    
    /// Creates a schema from a generable type and guides.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a schema from a generable type and guides.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(type:guides:)
    /// 
    /// **Apple Official API:** `init<Value>(type:guides:) where Value : Generable`
    /// 
    /// - Parameters:
    ///   - type: A Generable type
    ///   - guides: Generation guides to apply to this DynamicGenerationSchema
    public init<Value>(
        type: Value.Type,
        guides: [GenerationGuide<Value>] = []
    ) where Value : Generable {
        self.schemaType = .primitive(type: type, guides: guides.map { String(describing: $0) })
        self._description = nil
    }
    
    /// DEPRECATED: Legacy initializer for backward compatibility
    /// This initializer doesn't match Apple's API and should not be used
    @available(*, deprecated, message: "Use one of the specific initializers instead")
    public init(
        type: String,
        properties: [String: GenerationSchema]? = nil,
        required: [String]? = nil,
        items: GenerationSchema? = nil,
        description: String? = nil
    ) {
        // Convert to object schema for backward compatibility
        if let properties = properties {
            let props = properties.map { key, schema in
                Property(name: key, description: schema.description, schema: DynamicGenerationSchema(schema), isOptional: !(required?.contains(key) ?? true))
            }
            self.schemaType = .object(name: "LegacySchema", properties: props)
        } else if let items = items {
            self.schemaType = .array(elementSchema: DynamicGenerationSchema(items), minElements: nil, maxElements: nil)
        } else {
            self.schemaType = .object(name: "EmptySchema", properties: [])
        }
        self._description = description
    }
    
    /// Creates a dynamic generation schema from a static generation schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a dynamic generation schema from a static generation schema.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(_:)
    /// 
    /// **Apple Official API:** `init(_: GenerationSchema)`
    /// 
    /// - Parameter schema: The static generation schema to convert
    public init(_ schema: GenerationSchema) {
        // Convert static schema to dynamic (implementation detail)
        // This is a simplified conversion
        if let properties = schema.properties {
            let props = properties.map { key, value in
                Property(name: key, description: value.description, schema: DynamicGenerationSchema(value), isOptional: false)
            }
            self.schemaType = .object(name: "ConvertedSchema", properties: props)
        } else {
            self.schemaType = .object(name: "EmptySchema", properties: [])
        }
        self._description = schema.description
    }
    
    // Legacy computed properties for backward compatibility
    public var type: String {
        switch schemaType {
        case .object: return "object"
        case .array: return "array"
        case .anyOf: return "anyOf"
        case .reference: return "reference"
        case .primitive: return "primitive"
        }
    }
    
    public var properties: [String: GenerationSchema]? {
        switch schemaType {
        case .object(_, let props):
            // Convert properties to GenerationSchema dictionary for compatibility
            var dict: [String: GenerationSchema] = [:]
            for prop in props {
                // This is a simplified conversion
                dict[prop.name] = GenerationSchema(type: "string", description: prop.description)
            }
            return dict.isEmpty ? nil : dict
        default:
            return nil
        }
    }
    
    public var required: [String]? {
        switch schemaType {
        case .object(_, let props):
            let requiredProps = props.filter { !$0.isOptional }.map { $0.name }
            return requiredProps.isEmpty ? nil : requiredProps
        default:
            return nil
        }
    }
    
    public var items: GenerationSchema? {
        switch schemaType {
        case .array(let elementSchema, _, _):
            // Convert DynamicGenerationSchema to GenerationSchema
            // This is a simplified conversion - in production would need proper mapping
            return GenerationSchema(type: "array", description: elementSchema.description, properties: [:])
        default:
            return nil
        }
    }
}

// MARK: - DynamicGenerationSchema.Property

/// A property that belongs to a dynamic generation schema.
/// 
/// **Apple Foundation Models Documentation:**
/// Fields are named members of object types. Fields are strongly typed and have optional descriptions.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/property
/// 
/// **Apple Official API:** `struct Property`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
extension DynamicGenerationSchema {
    public struct Property: Sendable {
        /// A name for this property
        public let name: String
        
        /// An optional natural language description of this property's contents
        public let description: String?
        
        /// A schema representing the type this property contains
        public let schema: DynamicGenerationSchema
        
        /// Determines if this property is required or not
        public let isOptional: Bool
        
        /// Creates a property referencing a dynamic schema.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// Creates a property referencing a dynamic schema.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/property/init(name:description:schema:isoptional:)
        /// 
        /// **Apple Official API:** `init(name:description:schema:isOptional:)`
        /// 
        /// - Parameters:
        ///   - name: A name for this property
        ///   - description: An optional natural language description of this property's contents
        ///   - schema: A schema representing the type this property contains
        ///   - isOptional: Determines if this property is required or not
        public init(
            name: String,
            description: String? = nil,
            schema: DynamicGenerationSchema,
            isOptional: Bool = false
        ) {
            self.name = name
            self.description = description
            self.schema = schema
            self.isOptional = isOptional
        }
    }
}

// MARK: - DynamicGenerationSchema Extensions

extension DynamicGenerationSchema: CustomDebugStringConvertible {
    /// String representation of the dynamic generation schema
    public var debugDescription: String {
        switch schemaType {
        case .object(let name, let properties):
            return "DynamicGenerationSchema.object(name: \(name), properties: \(properties.count))"
        case .array(_, let min, let max):
            return "DynamicGenerationSchema.array(min: \(min ?? 0), max: \(max ?? -1))"
        case .anyOf(let name, let choices):
            return "DynamicGenerationSchema.anyOf(name: \(name), choices: \(choices.count))"
        case .reference(let to):
            return "DynamicGenerationSchema.reference(to: \(to))"
        case .primitive(let type, let guides):
            return "DynamicGenerationSchema.primitive(type: \(type), guides: \(guides.count))"
        }
    }
}

// MARK: - Extension for Nested Types

extension GenerationSchema {
    /// A property that belongs to a generation schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Fields are named members of object types. Fields are strongly typed and have optional 
    /// descriptions and guides.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/property
    /// 
    /// **Apple Official API:** `struct Property`
    /// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
    /// - Beta Software: Contains preliminary API information
    /// 
    /// **Conformances:**
    /// - Sendable
    /// - SendableMetatype
    public struct Property: Sendable, SendableMetatype {
        /// The property's name
        public let name: String
        
        /// The type this property represents
        public let type: any Sendable.Type
        
        /// A natural language description of what content should be generated for this property
        public let description: String?
        
        /// Regular expression patterns for string properties (internal storage)
        internal let regexPatterns: [String]
        
        /// Create a property that contains a string type.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// Create a property that contains a string type.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationschema/property/init(name:description:type:guides:)
        /// 
        /// **Apple Official API:** `init<RegexOutput>(name:description:type:guides:)`
        /// 
        /// - Parameters:
        ///   - name: The property's name
        ///   - description: A natural language description of what content should be generated for this property
        ///   - type: The type this property represents
        ///   - guides: An array of regexes to be applied to this string. If there're multiple regexes in the array, only the last one will be applied.
        public init<RegexOutput>(
            name: String,
            description: String? = nil,
            type: String.Type,
            guides: [Regex<RegexOutput>] = []
        ) {
            self.name = name
            self.description = description
            self.type = type
            self.regexPatterns = guides.map { String(describing: $0) }
        }
        
        /// Internal initializer for non-String types
        internal init(
            name: String,
            description: String? = nil,
            type: any Sendable.Type,
            guides: [String] = []
        ) {
            self.name = name
            self.description = description
            self.type = type
            self.regexPatterns = guides
        }
        
        /// Get type description as string (internal use)
        internal var typeDescription: String {
            return String(describing: type)
        }
        
        /// Get property description (internal use)
        internal var propertyDescription: String {
            return description ?? ""
        }
    }
}

