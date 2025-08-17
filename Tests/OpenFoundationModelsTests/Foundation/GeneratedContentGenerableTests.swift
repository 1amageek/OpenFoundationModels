import Testing
import OpenFoundationModelsCore
import OpenFoundationModels

@Test
func testGeneratedContentConformsToGenerable() throws {
    // Test that GeneratedContent conforms to Generable
    let content = GeneratedContent(kind: .string("test"))
    
    // Test that GeneratedContent has generationSchema
    let schema = GeneratedContent.generationSchema
    #expect(schema != nil)
    
    // Test init(_ content:) with throws
    let newContent = try GeneratedContent(content)
    #expect(newContent.text == "test")
}

@Test
func testPropertiesAndElementsArePublic() throws {
    // Test that properties() is public
    let structContent = GeneratedContent(properties: ["key": "value", "number": 42])
    let props = try structContent.properties()
    #expect(props["key"]?.text == "value")
    #expect(props["number"]?.text == "42")
    
    // Test that elements() is public
    let arrayContent = GeneratedContent(elements: ["a", "b", "c"])
    let elements = try arrayContent.elements()
    #expect(elements.count == 3)
    #expect(elements[0].text == "a")
    #expect(elements[1].text == "b")
    #expect(elements[2].text == "c")
}

@Test
func testSequenceInitializer() throws {
    // Test that the Sequence initializer works
    let sequence = ["one", "two", "three"]
    let content = GeneratedContent(elements: sequence)
    
    let elements = try content.elements()
    #expect(elements.count == 3)
    #expect(elements[0].text == "one")
    #expect(elements[1].text == "two")
    #expect(elements[2].text == "three")
}

@Test 
func testUniquingKeysInitializer() throws {
    // Test the uniquingKeysWith initializer
    let pairs = [
        ("name", "Alice"),
        ("age", "30"),
        ("name", "Bob")  // Duplicate key
    ]
    
    let content = GeneratedContent(
        properties: pairs, 
        uniquingKeysWith: { first, second in
            return second  // Take the second value for duplicates
        }
    )
    
    let props = try content.properties()
    #expect(props["name"]?.text == "Bob")  // Should have the second value
    #expect(props["age"]?.text == "30")
}

@Test
func testGenerableProtocolChain() throws {
    // Verify that Generable inherits from the correct protocols
    // GeneratedContent : Generable : ConvertibleFromGeneratedContent : SendableMetatype
    
    // This test verifies the protocol chain by compilation
    // If it compiles, the protocol chain is correct
    func requiresGenerable<T: Generable>(_ value: T) -> T { value }
    func requiresConvertibleFrom<T: ConvertibleFromGeneratedContent>(_ value: T) -> T { value }
    func requiresConvertibleTo<T: ConvertibleToGeneratedContent>(_ value: T) -> T { value }
    
    let content = GeneratedContent(kind: .string("test"))
    let _ = requiresGenerable(content)
    let _ = requiresConvertibleFrom(content)
    let _ = requiresConvertibleTo(content)
    
    #expect(true)  // If we get here, all protocol requirements are satisfied
}