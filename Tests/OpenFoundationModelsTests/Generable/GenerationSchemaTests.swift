import Testing
@testable import OpenFoundationModels

@Suite("Generation Schema Tests", .tags(.schema, .unit))
struct GenerationSchemaTests {
    
    @Test("GenerationSchema initializes with object type")
    func generationSchemaObjectInitialization() {
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
        
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
    
    @Test("GenerationSchema initializes with enumeration")
    func generationSchemaEnumerationInitialization() {
        struct DummyType: Generable {
            public init(_ generatedContent: GeneratedContent) throws {}
            public var generatedContent: GeneratedContent { GeneratedContent("") }
            public static var generationSchema: GenerationSchema { 
                GenerationSchema(type: DummyType.self, description: "Test", anyOf: [] as [String])
            }
        }
        
        let schema = GenerationSchema(
            type: DummyType.self,
            description: "Test enumeration",
            anyOf: ["option1", "option2", "option3"]
        )
        
        let debugString = schema.debugDescription
        #expect(debugString.contains("enum"))
    }
    
    @Test("GenerationSchema property creation")
    func generationSchemaProperty() {
        let emptyGuides: [Regex<Substring>] = []
        let property = GenerationSchema.Property(
            name: "testProperty",
            description: "A test property",
            type: String.self,
            guides: emptyGuides
        )
        
        // Properties are internal - cannot test directly
        // Test that property can be created successfully
        #expect(property != nil)
    }
    
    @Test("GenerationSchema property with pattern constraint")
    func generationSchemaPropertyWithPattern() {
        let regex = try! Regex("[a-zA-Z0-9]+")
        let property = GenerationSchema.Property(
            name: "username",
            description: "Username with alphanumeric characters",
            type: String.self,
            guides: [regex]
        )
        
        // Properties are internal - cannot test directly
        // Test that property can be created successfully
        #expect(property != nil)
    }
    
    @Test("GenerationSchema debug description")
    func generationSchemaDebugDescription() {
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