import Testing
import Foundation
@testable import OpenFoundationModelsCore

@Suite("DynamicGenerationSchema Tests")
struct DynamicGenerationSchemaTests {
    
    @Test("DynamicGenerationSchema with properties encodes correctly")
    func dynamicSchemaWithPropertiesEncodesCorrectly() throws {
        // Create DynamicGenerationSchema
        let dynamic = DynamicGenerationSchema(
            name: "User",
            description: "User model",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "User name",
                    schema: DynamicGenerationSchema(type: String.self),
                    isOptional: false
                ),
                DynamicGenerationSchema.Property(
                    name: "age",
                    description: "User age",
                    schema: DynamicGenerationSchema(type: Int.self),
                    isOptional: false
                ),
                DynamicGenerationSchema.Property(
                    name: "email",
                    description: "Email address",
                    schema: DynamicGenerationSchema(type: String.self),
                    isOptional: true
                )
            ]
        )
        
        // Convert to GenerationSchema
        let schema = try GenerationSchema(root: dynamic, dependencies: [])
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        
        // Print for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("\n=== DynamicGenerationSchema Encoded JSON ===")
            print(jsonString)
            print("==========================================\n")
        }
        
        // Parse and verify
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Critical assertions
        #expect(json?["type"] as? String == "object")
        #expect(json?["description"] as? String == "User model")
        
        // THE MOST IMPORTANT CHECK - properties must exist
        let properties = json?["properties"] as? [String: Any]
        #expect(properties != nil, "Properties should be present in encoded JSON")
        
        if let properties = properties {
            #expect(properties.count == 3, "Should have 3 properties")
            
            // Check name property
            if let name = properties["name"] as? [String: Any] {
                #expect(name["type"] as? String == "string")
                #expect(name["description"] as? String == "User name")
            } else {
                Issue.record("name property not found")
            }
            
            // Check age property
            if let age = properties["age"] as? [String: Any] {
                #expect(age["type"] as? String == "integer")
                #expect(age["description"] as? String == "User age")
            } else {
                Issue.record("age property not found")
            }
            
            // Check email property
            if let email = properties["email"] as? [String: Any] {
                #expect(email["type"] as? String == "string")
                #expect(email["description"] as? String == "Email address")
            } else {
                Issue.record("email property not found")
            }
        }
        
        // Check required fields
        let required = json?["required"] as? [String]
        #expect(required != nil, "Required field should be present")
        if let required = required {
            #expect(required.contains("name"), "name should be required")
            #expect(required.contains("age"), "age should be required")
            #expect(!required.contains("email"), "email should not be required (optional)")
        }
    }
    
    @Test("DynamicGenerationSchema with array encodes correctly")
    func dynamicSchemaWithArrayEncodesCorrectly() throws {
        // Create DynamicGenerationSchema with array
        let itemSchema = DynamicGenerationSchema(type: String.self)
        let arraySchema = DynamicGenerationSchema(
            arrayOf: itemSchema,
            minimumElements: 1,
            maximumElements: 10
        )
        
        // Convert to GenerationSchema
        let schema = try GenerationSchema(root: arraySchema, dependencies: [])
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Verify
        #expect(json?["type"] as? String == "array")
        #expect(json?["minItems"] as? Int == 1)
        #expect(json?["maxItems"] as? Int == 10)
        
        if let items = json?["items"] as? [String: Any] {
            #expect(items["type"] as? String == "string")
        } else {
            Issue.record("items not found in array schema")
        }
    }
    
    @Test("DynamicGenerationSchema with reference resolves correctly")
    func dynamicSchemaWithReferenceResolvesCorrectly() throws {
        // Create referenced schema
        let addressSchema = DynamicGenerationSchema(
            name: "Address",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "street",
                    schema: DynamicGenerationSchema(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "city",
                    schema: DynamicGenerationSchema(type: String.self)
                )
            ]
        )
        
        // Create main schema with reference
        let userSchema = DynamicGenerationSchema(
            name: "User",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: DynamicGenerationSchema(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "address",
                    schema: DynamicGenerationSchema(referenceTo: "Address")
                )
            ]
        )
        
        // Convert with dependencies
        let schema = try GenerationSchema(root: userSchema, dependencies: [addressSchema])
        
        // Encode and verify
        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        #expect(json?["type"] as? String == "object")
        
        if let properties = json?["properties"] as? [String: Any] {
            #expect(properties["name"] != nil)
            #expect(properties["address"] != nil)
            
            // Address should be resolved to object type
            if let address = properties["address"] as? [String: Any] {
                #expect(address["type"] as? String == "object")
                
                if let addressProps = address["properties"] as? [String: Any] {
                    #expect(addressProps["street"] != nil)
                    #expect(addressProps["city"] != nil)
                }
            }
        }
    }
}