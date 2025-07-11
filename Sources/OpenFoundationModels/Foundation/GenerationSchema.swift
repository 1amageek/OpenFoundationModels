// GenerationSchema.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// Apple's schema system for structured generation
/// 
/// ✅ CONFIRMED: From Apple Developer Documentation
/// - Guides SystemLanguageModel output to deterministically ensure desired format
/// - Three distinct initialization patterns
/// - Protocol conformances: CustomDebugStringConvertible, Sendable, SendableMetatype
/// 
/// 🚨 CRITICAL: Apple uses GenerationSchema, NOT JSONSchema
public struct GenerationSchema: CustomDebugStringConvertible, Sendable, SendableMetatype {
    
    /// Internal schema representation
    private let schemaType: SchemaType
    private let description: String?
    private let properties: [Property]
    
    /// Schema type enumeration
    private enum SchemaType: Sendable {
        case object(properties: [Property])
        case enumeration(values: [String])
        case dynamic(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema])
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
        self.description = nil
        self.properties = []
    }
    
    /// Create schema for string enumeration
    /// ✅ CONFIRMED: Second initialization pattern from Apple docs
    /// - Parameters:
    ///   - type: The enumeration type
    ///   - description: Optional description
    ///   - anyOf: Enumeration values
    public init(type: String, description: String?, anyOf: [String]) {
        self.schemaType = .enumeration(values: anyOf)
        self.description = description
        self.properties = []
    }
    
    /// Create schema with properties array
    /// ✅ CONFIRMED: Third initialization pattern from Apple docs
    /// - Parameters:
    ///   - type: The Generable type
    ///   - description: Optional description
    ///   - properties: Array of properties for the schema
    public init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property]) {
        self.schemaType = .object(properties: properties)
        self.description = description
        self.properties = properties
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
        case .dynamic(let root, let dependencies):
            return "GenerationSchema(dynamic: root + \(dependencies.count) dependencies)"
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
    public let description: String
    
    /// Generation guides for this property
    public let guides: [GenerationGuide]
    
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
    public init(name: String, type: String, description: String, guides: [GenerationGuide] = [], pattern: String? = nil) {
        self.name = name
        self.type = type
        self.description = description
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

/// Dynamic schema construction
/// ✅ CONFIRMED: Referenced in Apple docs for dynamic initialization
/// ❌ STRUCTURE UNKNOWN: Type structure not documented  
public struct DynamicGenerationSchema: Sendable {
    /// Schema type
    internal let type: String
    
    /// Properties for the schema
    internal let properties: [Property]
    
    /// Initialize with type and properties
    public init(type: String, properties: [Property] = []) {
        self.type = type
        self.properties = properties
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