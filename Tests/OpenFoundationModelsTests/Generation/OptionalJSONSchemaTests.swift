import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore

// Test structures defined at module level
@Generable
fileprivate struct TestStruct {
    var optionalString: String?
    var requiredString: String
}

@Generable
fileprivate struct TestNumbers {
    var optionalInt: Int?
    var optionalDouble: Double?
    var optionalBool: Bool?
}

@Generable
fileprivate struct ToolArguments {
    var startedAfter: Date?
    var startedBefore: Date?
    var requiredParam: String
}

@Generable
fileprivate struct Inner {
    var value: String
}

@Generable
fileprivate struct Outer {
    var optionalInner: Inner?
    var requiredInner: Inner
}

@Generable
fileprivate struct TestEncodingStruct {
    var optionalField: String?
}

@Suite("Optional JSON Schema Generation Tests")
struct OptionalJSONSchemaTests {
    
    @Test("Optional string property generates type array with null")
    func optionalStringSchema() throws {
        let schema = TestStruct.generationSchema
        let jsonSchema = schema.toSchemaDictionary()
        
        // Check properties
        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found in schema")
            return
        }
        
        // Check optional string has ["string", "null"] type
        guard let optionalProp = properties["optionalString"] as? [String: Any],
              let optionalType = optionalProp["type"] as? [String] else {
            Issue.record("Optional string property type not found or not an array")
            return
        }
        
        #expect(optionalType.contains("string"))
        #expect(optionalType.contains("null"))
        #expect(optionalType.count == 2)
        
        // Check required string has simple "string" type
        guard let requiredProp = properties["requiredString"] as? [String: Any],
              let requiredType = requiredProp["type"] as? String else {
            Issue.record("Required string property type not found")
            return
        }
        
        #expect(requiredType == "string")
        
        // Check required array
        guard let required = jsonSchema["required"] as? [String] else {
            Issue.record("Required array not found")
            return
        }
        
        #expect(required.contains("requiredString"))
        #expect(!required.contains("optionalString"))
    }
    
    @Test("Optional numeric types generate correct null-allowing schemas")
    func optionalNumericSchema() throws {
        let schema = TestNumbers.generationSchema
        let jsonSchema = schema.toSchemaDictionary()
        
        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }
        
        // Check Int?
        if let intProp = properties["optionalInt"] as? [String: Any],
           let intType = intProp["type"] as? [String] {
            #expect(intType.contains("integer"))
            #expect(intType.contains("null"))
        } else {
            Issue.record("Optional int type not correctly formatted")
        }
        
        // Check Double?
        if let doubleProp = properties["optionalDouble"] as? [String: Any],
           let doubleType = doubleProp["type"] as? [String] {
            #expect(doubleType.contains("number"))
            #expect(doubleType.contains("null"))
        } else {
            Issue.record("Optional double type not correctly formatted")
        }
        
        // Check Bool?
        if let boolProp = properties["optionalBool"] as? [String: Any],
           let boolType = boolProp["type"] as? [String] {
            #expect(boolType.contains("boolean"))
            #expect(boolType.contains("null"))
        } else {
            Issue.record("Optional bool type not correctly formatted")
        }
        
        // All fields should be optional (not in required)
        let required = jsonSchema["required"] as? [String] ?? []
        #expect(required.isEmpty)
    }
    
    @Test("Tool arguments with optional dates generate correct schema")
    func toolArgumentsWithOptionalDates() throws {
        let schema = ToolArguments.generationSchema
        let jsonSchema = schema.toSchemaDictionary()
        
        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }
        
        // Check startedAfter allows null (Date is treated as object in this implementation)
        if let startedAfterProp = properties["startedAfter"] as? [String: Any],
           let startedAfterType = startedAfterProp["type"] as? [String] {
            #expect(startedAfterType.contains("object"))
            #expect(startedAfterType.contains("null"))
        } else {
            Issue.record("startedAfter not correctly formatted")
        }
        
        // Check startedBefore allows null (Date is treated as object in this implementation)
        if let startedBeforeProp = properties["startedBefore"] as? [String: Any],
           let startedBeforeType = startedBeforeProp["type"] as? [String] {
            #expect(startedBeforeType.contains("object"))
            #expect(startedBeforeType.contains("null"))
        } else {
            Issue.record("startedBefore not correctly formatted")
        }
        
        // Check required param
        if let requiredProp = properties["requiredParam"] as? [String: Any],
           let requiredType = requiredProp["type"] as? String {
            #expect(requiredType == "string")
        } else {
            Issue.record("requiredParam not correctly formatted")
        }
        
        // Check required array
        guard let required = jsonSchema["required"] as? [String] else {
            Issue.record("Required array not found")
            return
        }
        
        #expect(required.contains("requiredParam"))
        #expect(!required.contains("startedAfter"))
        #expect(!required.contains("startedBefore"))
    }
    
    @Test("Complex optional types with anyOf use correct null handling")
    func complexOptionalWithAnyOf() throws {
        // Create a schema with anyOf manually to test complex type handling
        let schema = GenerationSchema(
            schemaType: .object(properties: [
                GenerationSchema.PropertyInfo(
                    name: "complexField",
                    description: "A complex optional field",
                    type: .anyOf([
                        .generic(type: String.self, guides: []),
                        .generic(type: Int.self, guides: [])
                    ]),
                    isOptional: true
                )
            ]),
            description: "Test complex optional"
        )
        
        let jsonSchema = schema.toSchemaDictionary()
        
        guard let properties = jsonSchema["properties"] as? [String: Any],
              let complexProp = properties["complexField"] as? [String: Any] else {
            Issue.record("Complex property not found")
            return
        }
        
        // Should have anyOf at the top level with the original schema and null
        if let anyOf = complexProp["anyOf"] as? [[String: Any]] {
            // Should have original anyOf plus null type
            let hasNull = anyOf.contains { dict in
                if let type = dict["type"] as? String {
                    return type == "null"
                }
                return false
            }
            
            #expect(hasNull, "anyOf should include null type for optional")
            #expect(anyOf.count >= 2, "anyOf should have at least original schema and null")
        } else {
            Issue.record("anyOf not found in complex optional property")
        }
    }
    
    @Test("Nested optional types generate correct schemas")
    func nestedOptionalTypes() throws {
        let schema = Outer.generationSchema
        let jsonSchema = schema.toSchemaDictionary()
        
        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }
        
        // For nested Generable types, they become "object" type
        // Optional should make it ["object", "null"]
        if let optionalProp = properties["optionalInner"] as? [String: Any] {
            if let typeArray = optionalProp["type"] as? [String] {
                #expect(typeArray.contains("object"))
                #expect(typeArray.contains("null"))
            } else if let _ = optionalProp["anyOf"] {
                // Complex nested type might use anyOf
                // This is also acceptable
                #expect(true)
            } else {
                Issue.record("Optional nested type not correctly formatted")
            }
        }
        
        // Required nested type should be simple "object"
        if let requiredProp = properties["requiredInner"] as? [String: Any],
           let requiredType = requiredProp["type"] as? String {
            #expect(requiredType == "object")
        }
    }
    
    @Test("JSON Schema encoding preserves null-allowing types")
    func jsonSchemaEncodingPreservesNullTypes() throws {
        let schema = TestEncodingStruct.generationSchema
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(schema)
        
        // Decode back to verify structure
        let decoder = JSONDecoder()
        let decodedDict = try decoder.decode([String: AnyCodable].self, from: jsonData)
        
        // Navigate to the type field
        if let properties = decodedDict["properties"]?.value as? [String: Any],
           let optionalField = properties["optionalField"] as? [String: Any],
           let typeValue = optionalField["type"] {
            // Check if it's an array containing "string" and "null"
            if let typeArray = typeValue as? [String] {
                #expect(typeArray.contains("string"))
                #expect(typeArray.contains("null"))
            } else {
                Issue.record("Type should be an array for optional fields")
            }
        } else {
            Issue.record("Could not navigate to optionalField type in encoded JSON")
        }
    }
}

// Helper for JSON decoding
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
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
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Cannot encode value"))
        }
    }
}