import Testing
@testable import OpenFoundationModels

/// Tests for GenerationSchema functionality
/// 
/// **Focus:** Validates GenerationSchema creation, properties, and accuracy
/// according to Apple's Foundation Models specification.
///
/// **Apple Foundation Models Documentation:**
/// GenerationSchema describes the properties of an object and any guides on their values.
/// Schemas guide the output of a SystemLanguageModel to deterministically ensure 
/// the output is in the desired format.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/generationschema
@Suite("Generation Schema Tests", .tags(.schema, .unit))
struct GenerationSchemaTests {
    
    @Test("GenerationSchema initializes with object type")
    func generationSchemaObjectInitialization() {
        // Test object schema initialization using properties parameter
        let schema = GenerationSchema(
            type: "object", 
            description: "Test object",
            properties: [:] // Empty properties dictionary
        )
        
        #expect(schema.type == "object")
        #expect(schema.description == "Test object")
    }
    
    @Test("GenerationSchema initializes with enumeration")
    func generationSchemaEnumerationInitialization() {
        // Test enumeration schema initialization
        let schema = GenerationSchema(
            type: "string",
            description: "Test enumeration",
            anyOf: ["option1", "option2", "option3"]
        )
        
        #expect(schema.type == "string")
        #expect(schema.description == "Test enumeration")
    }
    
    @Test("GenerationSchema property creation")
    func generationSchemaProperty() {
        // Test Property creation using legacy initializer
        let property = GenerationSchema.Property(
            name: "testProperty",
            type: "string",
            description: "A test property"
        )
        
        #expect(property.name == "testProperty")
        #expect(property.typeDescription == "String")
        #expect(property.propertyDescription == "A test property")
    }
    
    @Test("GenerationSchema property with pattern constraint")
    func generationSchemaPropertyWithPattern() {
        // Test Property with pattern constraint using legacy initializer
        let property = GenerationSchema.Property(
            name: "username",
            type: "string",
            description: "Username with alphanumeric characters",
            pattern: "[a-zA-Z0-9]+"
        )
        
        #expect(property.name == "username")
        #expect(!property.regexPatterns.isEmpty)
        #expect(property.regexPatterns.first == "[a-zA-Z0-9]+")
    }
    
    @Test("GenerationSchema debug description")
    func generationSchemaDebugDescription() {
        // Test debug description functionality
        let schema = GenerationSchema(
            type: "object",
            description: "Test schema",
            anyOf: []
        )
        
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
}