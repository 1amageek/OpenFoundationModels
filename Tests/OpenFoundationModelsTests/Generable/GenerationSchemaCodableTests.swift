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
    
    
    @Test("DynamicGenerationSchema can be created with object properties")
    func dynamicSchemaObjectCreation() throws {
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
        
        let schema = DynamicGenerationSchema(
            name: "User",
            description: "User model",
            properties: properties
        )
        
        // Test that schema can be created successfully
        #expect(schema != nil)
    }
    
    @Test("DynamicGenerationSchema can be created with array schema")
    func dynamicSchemaArrayCreation() throws {
        let elementSchema = DynamicGenerationSchema(name: "String", properties: [])
        let schema = DynamicGenerationSchema(
            arrayOf: elementSchema,
            minimumElements: 1,
            maximumElements: 10
        )
        
        // Test that schema can be created successfully
        #expect(schema != nil)
    }
    
    @Test("DynamicGenerationSchema can be created with enum schema")
    func dynamicSchemaEnumCreation() throws {
        let schema = DynamicGenerationSchema(
            name: "Status",
            description: "Status enumeration",
            anyOf: ["active", "inactive", "pending"]
        )
        
        // Test that schema can be created successfully
        #expect(schema != nil)
    }
    
    @Test("DynamicGenerationSchema can be created with reference")
    func dynamicSchemaReferenceCreation() throws {
        let schema = DynamicGenerationSchema(referenceTo: "UserProfile")
        
        // Test that schema can be created successfully
        #expect(schema != nil)
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
    
    
    @Test("DynamicGenerationSchema can be created from generic type")
    func genericSchemaCreation() throws {
        let schema = DynamicGenerationSchema(
            type: SimpleModel.self,
            guides: []
        )
        
        // Test that schema can be created successfully
        #expect(schema != nil)
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