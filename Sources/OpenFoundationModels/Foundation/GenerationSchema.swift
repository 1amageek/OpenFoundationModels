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
/// - Sendable
/// - SendableMetatype
public struct GenerationSchema: CustomDebugStringConvertible, Sendable, SendableMetatype {
    
    /// Internal schema representation
    private let schemaType: SchemaType
    private let _description: String?
    
    /// Schema type enumeration
    private indirect enum SchemaType: Sendable {
        case object(properties: [Property])
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
                Property(name: key, type: value.type, description: value.description ?? "", guides: [])
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
                dict[prop.name] = GenerationSchema(type: prop.type, description: prop.propertyDescription)
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
    ///   - type: The enumeration type
    ///   - description: Optional description
    ///   - anyOf: Enumeration values
    public init(type: String, description: String?, anyOf: [String]) {
        self.schemaType = .enumeration(values: anyOf)
        self._description = description
    }
    
    /// Create schema with properties array
    /// ✅ CONFIRMED: Third initialization pattern from Apple docs
    /// - Parameters:
    ///   - type: The Generable type
    ///   - description: Optional description
    ///   - properties: Array of properties for the schema
    public init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property]) {
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
        case .dynamic(let _, let dependencies):
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
                        "type": mapPropertyType(property.type)
                    ]
                    
                    if !property.propertyDescription.isEmpty {
                        propertySchema["description"] = property.propertyDescription
                    }
                    
                    // Apply pattern constraint if present
                    if let pattern = property.pattern {
                        propertySchema["pattern"] = pattern
                    }
                    
                    // Apply generation guides
                    for guide in property.guides {
                        applyGuide(guide, to: &propertySchema)
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

// MARK: - Related Types (Referenced but Not Documented)

/// Property structure for GenerationSchema
/// ✅ CONFIRMED: Referenced in Apple docs as GenerationSchema.Property
/// ❌ STRUCTURE UNKNOWN: Nested type documentation not accessible
public struct Property: Sendable {
    /// Property name
    public let name: String
    
    /// Property type description
    public let type: String
    
    /// Human-readable description
    public let propertyDescription: String
    
    /// Generation guides for this property
    public let guides: [AnyGenerationGuide]
    
    /// Regular expression pattern constraint
    /// ✅ APPLE SPEC: Pattern constraint from @Guide(.pattern(...))
    public let pattern: String?
    
    /// Initialize a schema property
    /// - Parameters:
    ///   - name: Property name
    ///   - type: Property type
    ///   - description: Property description
    ///   - guides: Optional generation guides
    ///   - pattern: Optional regex pattern constraint
    public init(name: String, type: String, description: String, guides: [AnyGenerationGuide] = [], pattern: String? = nil) {
        self.name = name
        self.type = type
        self.propertyDescription = description
        self.guides = guides
        self.pattern = pattern
    }
}

/// Schema creation errors
/// ✅ CONFIRMED: Referenced in Apple docs as GenerationSchema.SchemaError
/// ❌ CASES UNKNOWN: Error cases not documented
public enum SchemaError: Error {
    // ❌ IMPLEMENTATION NEEDED: Error cases not documented
    case notImplemented
    
    public var localizedDescription: String {
        switch self {
        case .notImplemented:
            return "GenerationSchema.SchemaError not implemented"
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
        }
        self.value = guide.value
    }
}

/// A generation schema that you can create at runtime.
/// 
/// **Apple Foundation Models Documentation:**
/// A generation schema that you can create at runtime.
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
    /// The type of data this schema represents
    public let type: String
    
    /// The properties of the schema (for object types)
    public let properties: [String: GenerationSchema]?
    
    /// The required properties (for object types)
    public let required: [String]?
    
    /// The schema for array items (for array types)
    public let items: GenerationSchema?
    
    /// A description of what this schema represents
    private let _description: String?
    
    /// Computed property for description
    public var description: String? {
        return _description
    }
    
    /// Creates a dynamic generation schema.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a dynamic generation schema with the specified properties.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(type:properties:required:items:description:)
    /// 
    /// **Apple Official API:** `init(type:properties:required:items:description:)`
    /// 
    /// - Parameters:
    ///   - type: The type of data this schema represents
    ///   - properties: The properties of the schema (for object types)
    ///   - required: The required properties (for object types)
    ///   - items: The schema for array items (for array types)
    ///   - description: A description of what this schema represents
    public init(
        type: String,
        properties: [String: GenerationSchema]? = nil,
        required: [String]? = nil,
        items: GenerationSchema? = nil,
        description: String? = nil
    ) {
        self.type = type
        self.properties = properties
        self.required = required
        self.items = items
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
        self.type = schema.type
        self.properties = schema.properties
        self.required = schema.required
        self.items = schema.items
        self._description = schema.description
    }
}

// MARK: - DynamicGenerationSchema Extensions
// Note: Codable conformance removed as GenerationSchema is not Codable in Apple's API

extension DynamicGenerationSchema: CustomDebugStringConvertible {
    /// String representation of the dynamic generation schema
    public var debugDescription: String {
        return "DynamicGenerationSchema(type: \(type), properties: \(properties?.count ?? 0), required: \(required?.count ?? 0))"
    }
}

// MARK: - Extension for Nested Types
extension GenerationSchema {
    /// Nested Property type
    /// ✅ CONFIRMED: Exists as GenerationSchema.Property in Apple docs
    public typealias Property = OpenFoundationModels.Property
    
    /// Nested SchemaError type
    /// ✅ CONFIRMED: Exists as GenerationSchema.SchemaError in Apple docs
    public typealias SchemaError = OpenFoundationModels.SchemaError
}

// MARK: - Legacy JSONSchema Warning
// 🚨 WARNING: The following JSONSchema implementation is INCOMPATIBLE with Apple's API
// JSONSchema will be removed - Apple uses GenerationSchema exclusively

/*
❌ INCOMPATIBLE: Apple does NOT use JSONSchema
❌ INCOMPATIBLE: Apple uses GenerationSchema with Property arrays
❌ INCOMPATIBLE: Apple uses different initialization patterns
❌ INCOMPATIBLE: Apple uses different protocol conformances

All code using JSONSchema must be migrated to GenerationSchema
*/