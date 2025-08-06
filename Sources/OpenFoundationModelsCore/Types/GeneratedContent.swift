// GeneratedContent.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// A type that represents structured, generated content.
/// 
/// **Apple Foundation Models Documentation:**
/// Generated content may contain a single value, an ordered collection of properties,
/// or an ordered collection of values.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/generatedcontent
/// 
/// **Apple Official API:** `struct GeneratedContent`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - ConvertibleFromGeneratedContent
/// - ConvertibleToGeneratedContent
/// - CustomDebugStringConvertible
/// - Equatable
/// - Generable
/// - InstructionsRepresentable
/// - PromptRepresentable
/// - Sendable
/// - SendableMetatype
public struct GeneratedContent: Sendable, Equatable, CustomDebugStringConvertible {
    
    // MARK: - Public Types
    
    /// A representation of the different types of content that can be stored in GeneratedContent.
    /// ✅ CONFIRMED: From Apple documentation
    /// - Source: https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum
    public enum Kind: Sendable, Equatable {
        /// Represents a null value
        case null
        /// Represents a boolean value
        case bool(Bool)
        /// Represents a numeric value
        case number(Double)
        /// Represents a string value
        case string(String)
        /// Represents an array of GeneratedContent elements
        case array([GeneratedContent])
        /// Represents a structured object with key-value pairs
        case structure(properties: [String: GeneratedContent], orderedKeys: [String])
        /// Represents partial/incomplete JSON (for streaming)
        case partial(json: String)
    }
    
    // MARK: - Internal Data Structure
    
    /// Internal content representation (legacy, will be migrated to Kind)
    private enum Content: Sendable, Equatable {
        case string(String)
        case array([GeneratedContent])
        case dictionary([String: GeneratedContent])
        case null
    }
    
    /// The actual content data
    private let content: Content
    
    /// Optional generation ID for tracking
    private let generationID: GenerationID?
    
    // MARK: - Initialization
    
    /// Creates an object with the content you specify.
    /// ✅ CONFIRMED: init(_:) from Apple docs
    /// - Parameter string: The string content
    public init(_ string: String) {
        // If string looks like JSON, try to parse it first
        if (string.hasPrefix("{") && string.hasSuffix("}")) || (string.hasPrefix("[") && string.hasSuffix("]")) {
            if let data = string.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let parsedContent = try? Self.parseJSONObject(jsonObject) {
                self.content = parsedContent
                self.generationID = nil
                return
            }
        }
        
        self.content = .string(string)
        self.generationID = nil
    }
    
    /// Creates an object with an array of elements you specify.
    /// ✅ CONFIRMED: init(elements:id:) from Apple docs
    /// - Parameters:
    ///   - elements: A collection of elements conforming to ConvertibleToGeneratedContent
    ///   - id: Optional generation ID for tracking
    public init<C: Collection>(elements: C, id: GenerationID? = nil) where C.Element: ConvertibleToGeneratedContent {
        let generatedElements = elements.map { $0.generatedContent }
        self.content = .array(generatedElements)
        self.generationID = id
    }
    
    /// Creates an object with the properties you specify.
    /// ✅ CONFIRMED: init(properties:id:) from Apple docs
    /// - Parameters:
    ///   - properties: Key-value pairs of properties
    ///   - id: Optional generation ID for tracking
    public init(properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>, id: GenerationID? = nil) {
        var dict: [String: GeneratedContent] = [:]
        for (key, value) in properties {
            dict[key] = value.generatedContent
        }
        self.content = .dictionary(dict)
        self.generationID = id
    }
    
    /// Creates generated content from another ConvertibleToGeneratedContent value.
    /// ✅ CONFIRMED: init(_:) from Apple docs for ConvertibleToGeneratedContent types
    /// - Parameter content: A value that can be converted to GeneratedContent
    public init(_ content: some ConvertibleToGeneratedContent) {
        self = content.generatedContent
    }
    
    /// Creates content that contains a single value with a custom generation ID.
    /// ✅ CONFIRMED: init(_:id:) from Apple docs
    /// - Parameters:
    ///   - content: A value that can be converted to GeneratedContent
    ///   - id: Generation ID for tracking
    public init(_ content: some ConvertibleToGeneratedContent, id: GenerationID) {
        let generated = content.generatedContent
        self.content = generated.content
        self.generationID = id
    }
    
    /// Creates new generated content from the key-value pairs in the given sequence,
    /// using a combining closure to determine the value for any duplicate keys.
    /// ✅ CONFIRMED: init(properties:id:uniquingKeysWith:) from Apple docs
    public init<S: Sequence>(
        properties: S,
        id: GenerationID? = nil,
        uniquingKeysWith combine: (any ConvertibleToGeneratedContent, any ConvertibleToGeneratedContent) throws -> any ConvertibleToGeneratedContent
    ) rethrows where S.Element == (String, any ConvertibleToGeneratedContent) {
        var dict: [String: GeneratedContent] = [:]
        for (key, value) in properties {
            if let existing = dict[key] {
                let combined = try combine(existing, value)
                dict[key] = combined.generatedContent
            } else {
                dict[key] = value.generatedContent
            }
        }
        self.content = .dictionary(dict)
        self.generationID = id
    }
    
    /// Creates equivalent content from a JSON string.
    /// ✅ CONFIRMED: init(json:) throws from Apple docs
    /// - Parameter json: The JSON string to parse
    /// - Throws: GeneratedContentError.invalidJSON if the JSON is malformed
    public init(json: String) throws {
        guard let data = json.data(using: .utf8) else {
            throw GeneratedContentError.invalidJSON("Unable to convert string to data")
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        self.content = try Self.parseJSONObject(jsonObject)
        self.generationID = nil
    }
    
    /// Private initializer for internal use
    private init(content: Content, id: GenerationID? = nil) {
        self.content = content
        self.generationID = id
    }
    
    /// Creates a new GeneratedContent instance with the specified kind and generation ID.
    /// ✅ CONFIRMED: init(kind:id:) from Apple docs
    /// - Parameters:
    ///   - kind: The kind of content
    ///   - id: Optional generation ID for tracking
    public init(kind: Kind, id: GenerationID? = nil) {
        // Convert Kind to Content for backward compatibility
        switch kind {
        case .null:
            self.content = .null
        case .bool(let value):
            self.content = .string(value ? "true" : "false")
        case .number(let value):
            self.content = .string(String(value))
        case .string(let value):
            self.content = .string(value)
        case .array(let elements):
            self.content = .array(elements)
        case .structure(let properties, _):
            self.content = .dictionary(properties)
        case .partial(let json):
            // Try to parse partial JSON, fallback to string if invalid
            if let data = json.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let parsedContent = try? Self.parseJSONObject(jsonObject) {
                self.content = parsedContent
            } else {
                self.content = .string(json)
            }
        }
        self.generationID = id
    }
    
    // MARK: - Public Properties
    
    /// The kind representation of this generated content.
    /// ✅ CONFIRMED: From Apple documentation
    public var kind: Kind {
        switch content {
        case .null:
            return .null
        case .string(let str):
            // Try to detect bool/number from string
            if str == "true" {
                return .bool(true)
            } else if str == "false" {
                return .bool(false)
            } else if let number = Double(str) {
                return .number(number)
            } else {
                return .string(str)
            }
        case .array(let elements):
            return .array(elements)
        case .dictionary(let dict):
            let keys = dict.keys.sorted()
            return .structure(properties: dict, orderedKeys: keys)
        }
    }
    
    /// A Boolean that indicates whether the generated content is completed.
    /// ✅ CONFIRMED: From Apple documentation
    public var isComplete: Bool {
        switch kind {
        case .partial:
            return false
        case .structure(let properties, _):
            // Check if all nested content is complete
            return properties.values.allSatisfy { $0.isComplete }
        case .array(let elements):
            // Check if all elements are complete
            return elements.allSatisfy { $0.isComplete }
        case .null, .bool, .number, .string:
            // Primitive types are always complete
            return true
        }
    }
    
    /// Returns a JSON string representation of the generated content.
    /// ✅ CONFIRMED: From Apple documentation
    public var jsonString: String {
        do {
            let jsonObject = try toJSONObject()
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            // Fallback for invalid JSON
            return stringValue
        }
    }
    
    /// A unique id that is stable for the duration of a generated response.
    /// ✅ CONFIRMED: From Apple documentation
    public var id: GenerationID? {
        return generationID
    }
    
    // MARK: - Data Access
    
    /// Reads the properties of a top level object
    /// ✅ CONFIRMED: properties() throws from Apple docs
    /// - Returns: Dictionary of property names to GeneratedContent values
    /// - Throws: GeneratedContentError.dictionaryExpected if content is not a dictionary
    public func properties() throws -> [String: GeneratedContent] {
        guard case .dictionary(let dict) = content else {
            throw GeneratedContentError.dictionaryExpected
        }
        return dict
    }
    
    /// Reads a top level array of content.
    /// ✅ CONFIRMED: elements() throws from Apple docs
    /// - Returns: Array of GeneratedContent elements
    /// - Throws: GeneratedContentError.arrayExpected if content is not an array
    public func elements() throws -> [GeneratedContent] {
        guard case .array(let array) = content else {
            throw GeneratedContentError.arrayExpected
        }
        return array
    }
    
    /// Reads a top level, concrete partially generable type.
    /// ✅ CONFIRMED: value(_:) throws from Apple docs
    /// - Parameter type: The type to decode the content into
    /// - Returns: The decoded value
    /// - Throws: GeneratedContentError if the content cannot be decoded to the specified type
    public func value<Value>(_ type: Value.Type) throws -> Value {
        // Special handling for basic types
        if type == String.self {
            guard case .string(let str) = content else {
                throw GeneratedContentError.typeMismatch(expected: "String", actual: describeContentType())
            }
            return str as! Value
        }
        
        if type == Bool.self {
            guard case .string(let str) = content else {
                throw GeneratedContentError.typeMismatch(expected: "Bool", actual: describeContentType())
            }
            guard let bool = Bool(str) else {
                throw GeneratedContentError.typeMismatch(expected: "Bool", actual: "String(\(str))")
            }
            return bool as! Value
        }
        
        if type == Int.self {
            guard case .string(let str) = content else {
                throw GeneratedContentError.typeMismatch(expected: "Int", actual: describeContentType())
            }
            guard let int = Int(str) else {
                throw GeneratedContentError.typeMismatch(expected: "Int", actual: "String(\(str))")
            }
            return int as! Value
        }
        
        if type == Double.self {
            guard case .string(let str) = content else {
                throw GeneratedContentError.typeMismatch(expected: "Double", actual: describeContentType())
            }
            guard let double = Double(str) else {
                throw GeneratedContentError.typeMismatch(expected: "Double", actual: "String(\(str))")
            }
            return double as! Value
        }
        
        if type == Float.self {
            guard case .string(let str) = content else {
                throw GeneratedContentError.typeMismatch(expected: "Float", actual: describeContentType())
            }
            guard let float = Float(str) else {
                throw GeneratedContentError.typeMismatch(expected: "Float", actual: "String(\(str))")
            }
            return float as! Value
        }
        
        // For ConvertibleFromGeneratedContent types
        if let convertibleType = type as? any ConvertibleFromGeneratedContent.Type {
            return try convertibleType.init(self) as! Value
        }
        
        throw GeneratedContentError.typeMismatch(expected: String(describing: type), actual: describeContentType())
    }
    
    /// Reads a concrete generable type from named property.
    /// ✅ CONFIRMED: value(_:forProperty:) from Apple docs
    /// - Parameters:
    ///   - type: The type to decode the property value into
    ///   - property: The property name to read
    /// - Returns: The decoded value
    /// - Throws: GeneratedContentError if the property doesn't exist or cannot be decoded
    public func value<Value>(_ type: Value.Type, forProperty property: String) throws -> Value {
        let properties = try self.properties()
        guard let propertyContent = properties[property] else {
            throw GeneratedContentError.missingProperty(property)
        }
        return try propertyContent.value(type)
    }
    
    /// Reads an optional concrete generable type from named property.
    /// ✅ CONFIRMED: value(_:forProperty:) from Apple docs - Optional version
    /// - Parameters:
    ///   - type: The optional type to decode the property value into
    ///   - property: The property name to read
    /// - Returns: The decoded value or nil if the property doesn't exist
    /// - Throws: GeneratedContentError if the property exists but cannot be decoded
    public func value<Value>(_ type: Value?.Type, forProperty property: String) throws -> Value? {
        let properties = try self.properties()
        guard let propertyContent = properties[property] else {
            return nil
        }
        return try propertyContent.value(Value.self)
    }
    
    // MARK: - Properties
    
    /// A representation of this instance.
    /// ✅ CONFIRMED: generatedContent property from Apple docs
    public var generatedContent: GeneratedContent {
        return self
    }
    
    /// Get content as string (compatibility)
    public var stringValue: String {
        switch content {
        case .string(let str):
            return str
        case .array(let array):
            return array.map { $0.stringValue }.joined(separator: ", ")
        case .dictionary(let dict):
            let pairs = dict.map { "\($0.key): \($0.value.stringValue)" }
            return "{\(pairs.joined(separator: ", "))}"
        case .null:
            return "null"
        }
    }
    
    /// Get content as text (alias for stringValue)
    /// ✅ PHASE 2.1: Text property for compatibility
    public var text: String {
        return stringValue
    }
    
    // MARK: - CustomDebugStringConvertible
    
    /// A string representation for the debug description.
    /// ✅ CONFIRMED: debugDescription from Apple docs
    public var debugDescription: String {
        switch content {
        case .string(let str):
            return "GeneratedContent(\"\(str)\")"
        case .array(let array):
            return "GeneratedContent([\(array.map { $0.debugDescription }.joined(separator: ", "))])"
        case .dictionary(let dict):
            let pairs = dict.map { "\($0.key): \($0.value.debugDescription)" }
            return "GeneratedContent({\(pairs.joined(separator: ", "))})"
        case .null:
            return "GeneratedContent(null)"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Parse JSON object into Content
    private static func parseJSONObject(_ object: Any) throws -> Content {
        if let string = object as? String {
            return .string(string)
        } else if let array = object as? [Any] {
            let elements = try array.map { try GeneratedContent(content: parseJSONObject($0)) }
            return .array(elements)
        } else if let dict = object as? [String: Any] {
            var generatedDict: [String: GeneratedContent] = [:]
            for (key, value) in dict {
                generatedDict[key] = GeneratedContent(content: try parseJSONObject(value))
            }
            return .dictionary(generatedDict)
        } else if object is NSNull {
            return .null
        } else if let bool = object as? Bool {
            // Convert boolean to string "true" or "false"
            return .string(bool ? "true" : "false")
        } else {
            // Convert numbers and other values to strings
            return .string(String(describing: object))
        }
    }
    
    /// Describe the content type for error messages
    private func describeContentType() -> String {
        switch content {
        case .string: return "String"
        case .array: return "Array"
        case .dictionary: return "Dictionary"
        case .null: return "Null"
        }
    }
    
    /// Convert content to JSON object for serialization
    private func toJSONObject() throws -> Any {
        switch content {
        case .null:
            return NSNull()
        case .string(let str):
            // Check if it's a boolean or number
            if str == "true" {
                return true
            } else if str == "false" {
                return false
            } else if let number = Double(str) {
                return number
            } else {
                return str
            }
        case .array(let elements):
            return try elements.map { try $0.toJSONObject() }
        case .dictionary(let dict):
            var jsonDict: [String: Any] = [:]
            for (key, value) in dict {
                jsonDict[key] = try value.toJSONObject()
            }
            return jsonDict
        }
    }
}

// MARK: - Protocol Conformances

/// ✅ CONFIRMED: GeneratedContent conforms to ConvertibleFromGeneratedContent
extension GeneratedContent: ConvertibleFromGeneratedContent {
    /// Creates an instance with the content.
    /// ✅ CONFIRMED: Required by ConvertibleFromGeneratedContent
    public init(_ content: GeneratedContent) throws {
        self = content
    }
}

/// ✅ CONFIRMED: GeneratedContent conforms to ConvertibleToGeneratedContent
extension GeneratedContent: ConvertibleToGeneratedContent {
    // generatedContent property already defined in main struct
    // instructionsRepresentation and promptRepresentation are provided by extensions in main module
}

// Note: Generable conformance is implemented in ProtocolConformances.swift

// MARK: - Codable Support

extension GeneratedContent: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self.content = .string(string)
        } else if let array = try? container.decode([GeneratedContent].self) {
            self.content = .array(array)
        } else if let dict = try? container.decode([String: GeneratedContent].self) {
            self.content = .dictionary(dict)
        } else if container.decodeNil() {
            self.content = .null
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode GeneratedContent")
        }
        self.generationID = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch content {
        case .string(let str):
            try container.encode(str)
        case .array(let array):
            try container.encode(array)
        case .dictionary(let dict):
            try container.encode(dict)
        case .null:
            try container.encodeNil()
        }
    }
}

// MARK: - Supporting Types

/// Generation content error types
/// ✅ PHASE 4.8: Error handling for generation operations
public enum GeneratedContentError: Error, Sendable {
    case invalidSchema
    case typeMismatch(expected: String, actual: String)
    case missingProperty(String)
    case invalidJSON(String)
    case arrayExpected
    case dictionaryExpected
    
    public var localizedDescription: String {
        switch self {
        case .invalidSchema:
            return "Invalid generation schema"
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected \(expected), got \(actual)"
        case .missingProperty(let property):
            return "Missing required property: \(property)"
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        case .arrayExpected:
            return "Expected array content"
        case .dictionaryExpected:
            return "Expected dictionary content"
        }
    }
}