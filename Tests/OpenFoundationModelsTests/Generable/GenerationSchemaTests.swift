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
        // Create a dummy Generable type for testing
        struct DummyType: Generable {
            public init(_ generatedContent: GeneratedContent) throws {}
            public var generatedContent: GeneratedContent { GeneratedContent("") }
            public static var generationSchema: GenerationSchema { 
                GenerationSchema(type: DummyType.self, description: "Test", properties: [])
            }
        }
        
        let schema = GenerationSchema(
            type: DummyType.self, 
            description: "Test object",
            properties: [] // Empty properties array
        )
        
        // Since type and description are internal, we can only verify creation succeeded
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
    
    @Test("GenerationSchema initializes with enumeration")
    func generationSchemaEnumerationInitialization() {
        // Test enumeration schema initialization using String type with anyOf
        // Create a dummy Generable type for testing
        struct DummyType: Generable {
            public init(_ generatedContent: GeneratedContent) throws {}
            public var generatedContent: GeneratedContent { GeneratedContent("") }
            public static var generationSchema: GenerationSchema { 
                GenerationSchema(type: DummyType.self, description: "Test", anyOf: [])
            }
        }
        
        let schema = GenerationSchema(
            type: DummyType.self,
            description: "Test enumeration",
            anyOf: ["option1", "option2", "option3"]
        )
        
        // Since type and description are internal, we can only verify creation succeeded
        let debugString = schema.debugDescription
        #expect(debugString.contains("enum"))
    }
    
    @Test("GenerationSchema property creation")
    func generationSchemaProperty() {
        // Test Property creation using Apple spec initializer
        // Since we need a specific RegexOutput type, let's use Substring as the output type
        let emptyGuides: [Regex<Substring>] = []
        let property = GenerationSchema.Property(
            name: "testProperty",
            description: "A test property",
            type: String.self,
            guides: emptyGuides
        )
        
        #expect(property.name == "testProperty")
        #expect(property.description == "A test property")
        // type and other properties are internal, verify creation succeeded
    }
    
    @Test("GenerationSchema property with pattern constraint")
    func generationSchemaPropertyWithPattern() {
        // Test Property with pattern constraint using Apple spec initializer
        let regex = try! Regex("[a-zA-Z0-9]+")
        let property = GenerationSchema.Property(
            name: "username",
            description: "Username with alphanumeric characters",
            type: String.self,
            guides: [regex]
        )
        
        #expect(property.name == "username")
        #expect(property.description == "Username with alphanumeric characters")
        // regexPatterns and type info are internal, verify creation succeeded
    }
    
    @Test("GenerationSchema debug description")
    func generationSchemaDebugDescription() {
        // Test debug description functionality
        // Create a dummy Generable type for testing
        struct DummyType: Generable {
            public init(_ generatedContent: GeneratedContent) throws {}
            public var generatedContent: GeneratedContent { GeneratedContent("") }
            public static var generationSchema: GenerationSchema { 
                GenerationSchema(type: DummyType.self, description: "Test", properties: [])
            }
        }
        
        let schema = GenerationSchema(
            type: DummyType.self,
            description: "Test schema",
            properties: []
        )
        
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
}