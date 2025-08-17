import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore
import OpenFoundationModelsMacros

@Suite("GenerationSchema JSON Schema Tests", .tags(.schema, .unit))
struct GenerationSchemaJSONSchemaTests {
    
    @Generable
    struct TestModel {
        let name: String
        let age: Int
        let isActive: Bool?
    }
    
    @Generable
    enum TestEnum: String {
        case option1 = "option1"
        case option2 = "option2"
        case option3 = "option3"
    }
    
    @Test("Struct schema encodes as JSON Schema")
    func structSchemaEncodesAsJSONSchema() throws {
        // Create schema from @Generable struct
        let schema = TestModel.generationSchema
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(schema)
        
        // Parse JSON
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Verify JSON Schema format
        #expect(json?["type"] as? String == "object")
        #expect(json?["properties"] as? [String: Any] != nil)
        
        // Check properties
        if let properties = json?["properties"] as? [String: [String: Any]] {
            #expect(properties["name"] != nil)
            #expect(properties["name"]?["type"] as? String == "string")
            
            #expect(properties["age"] != nil)
            #expect(properties["age"]?["type"] as? String == "integer")
            
            #expect(properties["isActive"] != nil)
            #expect(properties["isActive"]?["type"] as? String == "boolean")
        }
        
        // Check required fields
        if let required = json?["required"] as? [String] {
            #expect(required.contains("name"))
            #expect(required.contains("age"))
            #expect(!required.contains("isActive")) // Optional field
        } else {
            Issue.record("No required field found in JSON")
        }
    }
    
    @Test("Enum schema encodes as JSON Schema")
    func enumSchemaEncodesAsJSONSchema() throws {
        // Create schema from @Generable enum
        let schema = TestEnum.generationSchema
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        
        // Parse JSON
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Verify JSON Schema format for enum
        #expect(json?["type"] as? String == "string")
        
        // Check enum values
        if let enumValues = json?["enum"] as? [String] {
            #expect(enumValues.count == 3)
            #expect(enumValues.contains("option1"))
            #expect(enumValues.contains("option2"))
            #expect(enumValues.contains("option3"))
        }
    }
    
    @Test("Primitive types encode as JSON Schema")
    func primitiveTypesEncodeAsJSONSchema() throws {
        // Test String
        let stringSchema = GenerationSchema(
            type: String.self,
            description: "A string value",
            properties: []
        )
        
        let stringData = try JSONEncoder().encode(stringSchema)
        let stringJson = try JSONSerialization.jsonObject(with: stringData) as? [String: Any]
        #expect(stringJson?["type"] as? String == "string")
        #expect(stringJson?["description"] as? String == "A string value")
        
        // Test Int
        let intSchema = GenerationSchema(
            type: Int.self,
            description: "An integer value",
            properties: []
        )
        
        let intData = try JSONEncoder().encode(intSchema)
        let intJson = try JSONSerialization.jsonObject(with: intData) as? [String: Any]
        #expect(intJson?["type"] as? String == "integer")
        
        // Test Bool
        let boolSchema = GenerationSchema(
            type: Bool.self,
            description: "A boolean value",
            properties: []
        )
        
        let boolData = try JSONEncoder().encode(boolSchema)
        let boolJson = try JSONSerialization.jsonObject(with: boolData) as? [String: Any]
        #expect(boolJson?["type"] as? String == "boolean")
    }
    
    @Test("Schema round-trip encoding and decoding")
    func schemaRoundTrip() throws {
        // Create original schema
        let originalSchema = GenerationSchema(
            type: TestModel.self,
            description: "Test model for round-trip",
            properties: [
                GenerationSchema.Property(
                    name: "name",
                    description: "User name",
                    type: String.self
                ),
                GenerationSchema.Property(
                    name: "age",
                    description: "User age",
                    type: Int.self
                ),
                GenerationSchema.Property(
                    name: "isActive",
                    description: "Active status",
                    type: Bool?.self
                )
            ]
        )
        
        // Encode and decode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSchema)
        
        let decoder = JSONDecoder()
        let decodedSchema = try decoder.decode(GenerationSchema.self, from: data)
        
        // Verify the decoded schema maintains the structure
        #expect(decodedSchema != nil)
        
        // Re-encode and compare JSON
        let reEncodedData = try encoder.encode(decodedSchema)
        let originalJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let reEncodedJson = try JSONSerialization.jsonObject(with: reEncodedData) as? [String: Any]
        
        #expect(originalJson?["type"] as? String == reEncodedJson?["type"] as? String)
        #expect(originalJson?["description"] as? String == reEncodedJson?["description"] as? String)
    }
    
    @Test("GenerationSchema encodes to valid JSON Schema format")
    func generationSchemaEncodesToValidJSONSchema() throws {
        // Test that GenerationSchema encodes to correct JSON Schema format
        let schema = TestModel.generationSchema
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(schema)
        
        // Parse as dictionary
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Verify structure
        #expect(dict?["type"] as? String == "object")
        #expect(dict?["properties"] as? [String: Any] != nil)
        #expect(dict?["required"] as? [String] != nil)
        
        // Verify it's valid JSON Schema format
        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString != nil)
        if let jsonString = jsonString {
            #expect(jsonString.contains("\"type\""))
            #expect(jsonString.contains("\"properties\""))
        }
    }
}