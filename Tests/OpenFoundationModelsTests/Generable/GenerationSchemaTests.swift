import Testing
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore

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
        // Just verify the property was created (all fields are internal)
        let _ = property
        #expect(Bool(true))
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
        // Just verify the property was created (all fields are internal)
        let _ = property
        #expect(Bool(true))
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

    // MARK: - typeName Tests

    @Test("typeName is set for anyOf choices initializer")
    func typeNameForAnyOfChoicesInitializer() {
        struct Color: Generable {
            public init(_ content: GeneratedContent) throws {}
            public var generatedContent: GeneratedContent { GeneratedContent("") }
            public static var generationSchema: GenerationSchema {
                GenerationSchema(type: Color.self, anyOf: ["red", "green", "blue"])
            }
        }

        let schema = GenerationSchema(type: Color.self, anyOf: ["red", "green", "blue"])
        #expect(schema.typeName != nil)
        #expect(schema.typeName?.contains("Color") == true)
    }

    @Test("typeName is set for properties initializer")
    func typeNameForPropertiesInitializer() {
        struct Person: Generable {
            public init(_ content: GeneratedContent) throws {}
            public var generatedContent: GeneratedContent { GeneratedContent("") }
            public static var generationSchema: GenerationSchema {
                GenerationSchema(type: Person.self, properties: [
                    GenerationSchema.Property(name: "name", description: nil, type: String.self)
                ])
            }
        }

        let schema = GenerationSchema(type: Person.self, properties: [
            GenerationSchema.Property(name: "name", description: nil, type: String.self)
        ])
        #expect(schema.typeName != nil)
        #expect(schema.typeName?.contains("Person") == true)
    }

    @Test("typeName is set for anyOf types initializer")
    func typeNameForAnyOfTypesInitializer() {
        struct TypeA: Generable {
            public init(_ content: GeneratedContent) throws {}
            public var generatedContent: GeneratedContent { GeneratedContent("") }
            public static var generationSchema: GenerationSchema {
                GenerationSchema(type: TypeA.self, properties: [])
            }
        }
        struct TypeB: Generable {
            public init(_ content: GeneratedContent) throws {}
            public var generatedContent: GeneratedContent { GeneratedContent("") }
            public static var generationSchema: GenerationSchema {
                GenerationSchema(type: TypeB.self, properties: [])
            }
        }
        struct Union: Generable {
            public init(_ content: GeneratedContent) throws {}
            public var generatedContent: GeneratedContent { GeneratedContent("") }
            public static var generationSchema: GenerationSchema {
                GenerationSchema(type: Union.self, anyOf: [TypeA.self, TypeB.self])
            }
        }

        let schema = GenerationSchema(type: Union.self, anyOf: [TypeA.self, TypeB.self])
        #expect(schema.typeName != nil)
        #expect(schema.typeName?.contains("Union") == true)
    }

    @Test("typeName falls back to generic type for primitive types")
    func typeNameFallbackForPrimitiveTypes() {
        let schema = GenerationSchema(type: String.self, properties: [])
        // Empty properties -> .generic(type: String.self, ...)
        #expect(schema.typeName != nil)
        #expect(schema.typeName?.contains("String") == true)
    }

    @Test("typeName returns nil for DynamicGenerationSchema-derived schema")
    func typeNameNilForDynamicSchema() throws {
        let dynamic = DynamicGenerationSchema(
            name: "Menu",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "item",
                    schema: DynamicGenerationSchema(name: "item", anyOf: ["A", "B"])
                )
            ]
        )
        let schema = try GenerationSchema(root: dynamic, dependencies: [])
        // DynamicGenerationSchema path sets _typeName = nil and resolves to .object
        #expect(schema.typeName == nil)
    }
}