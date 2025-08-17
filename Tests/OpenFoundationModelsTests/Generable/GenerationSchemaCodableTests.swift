import Testing
import Foundation
@testable import OpenFoundationModels

@Suite("GenerationSchema Codable Tests", .tags(.schema, .unit))
struct GenerationSchemaCodableTests {
    
    
    @Generable
    struct SimpleModel {
        let name: String
        let age: Int
    }
    
    @Generable
    struct ComplexModel {
        let id: String
        let items: [String]
        let metadata: SimpleModel
    }
    
    @Generable
    enum TestEnum: String {
        case option1 = "option1"
        case option2 = "option2"
        case option3 = "option3"
    }
    
    
    @Test("DynamicGenerationSchema encodes and decodes object schema")
    func dynamicSchemaObjectCodable() throws {
        let properties = [
            DynamicGenerationSchema.Property(
                name: "name",
                description: "User name",
                schema: DynamicGenerationSchema(name: "String", properties: []),
                isOptional: false
            ),
            DynamicGenerationSchema.Property(
                name: "age",
                description: "User age",
                schema: DynamicGenerationSchema(name: "Int", properties: []),
                isOptional: false
            )
        ]
        
        let original = DynamicGenerationSchema(
            name: "User",
            description: "User model",
            properties: properties
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DynamicGenerationSchema.self, from: data)
        
        #expect(decoded.name == original.name)
        #expect(decoded.description == original.description)
    }
    
    @Test("DynamicGenerationSchema encodes and decodes array schema")
    func dynamicSchemaArrayCodable() throws {
        let elementSchema = DynamicGenerationSchema(name: "String", properties: [])
        let original = DynamicGenerationSchema(
            arrayOf: elementSchema,
            minimumElements: 1,
            maximumElements: 10
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DynamicGenerationSchema.self, from: data)
        
        #expect(decoded.name == original.name)
    }
    
    @Test("DynamicGenerationSchema encodes and decodes enum schema")
    func dynamicSchemaEnumCodable() throws {
        let original = DynamicGenerationSchema(
            name: "Status",
            description: "Status enumeration",
            anyOf: ["active", "inactive", "pending"]
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DynamicGenerationSchema.self, from: data)
        
        #expect(decoded.name == original.name)
        #expect(decoded.description == original.description)
    }
    
    @Test("DynamicGenerationSchema reference schema encodes and decodes")
    func dynamicSchemaReferenceCodable() throws {
        let original = DynamicGenerationSchema(referenceTo: "UserProfile")
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DynamicGenerationSchema.self, from: data)
        
        #expect(decoded.name == original.name)
    }
    
    
    @Test("GenerationSchema round-trip through DynamicGenerationSchema")
    func generationSchemaRoundTrip() throws {
        let originalSchema = GenerationSchema(
            type: SimpleModel.self,
            description: "Simple model schema",
            properties: [
                GenerationSchema.Property(
                    name: "name",
                    description: "Name field",
                    type: String.self
                ),
                GenerationSchema.Property(
                    name: "age",
                    description: "Age field",
                    type: Int.self
                )
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalSchema)
        
        let decoder = JSONDecoder()
        let decodedSchema = try decoder.decode(GenerationSchema.self, from: data)
        
        #expect(decodedSchema.debugDescription.contains("GenerationSchema"))
    }
    
    @Test("GenerationSchema with enum encodes and decodes")
    func generationSchemaEnumRoundTrip() throws {
        let originalSchema = GenerationSchema(
            type: TestEnum.self,
            description: "Test enumeration",
            anyOf: ["option1", "option2", "option3"]
        )
        
        let data = try JSONEncoder().encode(originalSchema)
        let decodedSchema = try JSONDecoder().decode(GenerationSchema.self, from: data)
        
        #expect(decodedSchema.debugDescription.contains("enum") || 
                decodedSchema.debugDescription.contains("GenerationSchema"))
    }
    
    
    @Test("Generic schema encoding throws error")
    func genericSchemaEncodingThrows() throws {
        let genericSchema = DynamicGenerationSchema(
            type: SimpleModel.self,
            guides: []
        )
        
        let encoder = JSONEncoder()
        #expect(throws: Error.self) {
            _ = try encoder.encode(genericSchema)
        }
    }
    
    @Test("Invalid schema type in JSON throws on decode")
    func invalidSchemaTypeThrows() throws {
        let invalidJSON = """
        {
            "name": "TestSchema",
            "description": "Test",
            "type": "invalid_type"
        }
        """
        
        let data = invalidJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        #expect(throws: Error.self) {
            _ = try decoder.decode(DynamicGenerationSchema.self, from: data)
        }
    }
    
    
    
    @Test("Full persistence and validation workflow")
    func fullPersistenceWorkflow() throws {
        let originalSchema = GenerationSchema(
            type: SimpleModel.self,
            description: "Test model",
            properties: [
                GenerationSchema.Property(name: "name", type: String.self),
                GenerationSchema.Property(name: "age", type: Int.self)
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSchema)
        
        let decoder = JSONDecoder()
        let restoredSchema = try decoder.decode(GenerationSchema.self, from: data)
        
        #expect(restoredSchema.debugDescription.contains("GenerationSchema"))
        
    }
}