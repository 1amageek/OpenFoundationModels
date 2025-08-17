import Testing
import OpenFoundationModelsCore
import OpenFoundationModels

@Test
func testOptionalConvertibleFromGeneratedContent() throws {
    // Test nil case
    let nullContent = GeneratedContent(kind: .null)
    let nilValue: String? = try Optional<String>(nullContent)
    #expect(nilValue == nil)
    
    // Test some case
    let stringContent = GeneratedContent(kind: .string("hello"))
    let someValue: String? = try Optional<String>(stringContent)
    #expect(someValue == "hello")
}

@Test
func testOptionalConvertibleToGeneratedContent() throws {
    // Test nil case
    let nilValue: String? = nil
    let nilContent = nilValue.generatedContent
    #expect(nilContent.kind == .null)
    
    // Test some case
    let someValue: String? = "world"
    let someContent = someValue.generatedContent
    switch someContent.kind {
    case .string(let s):
        #expect(s == "world")
    default:
        #expect(Bool(false), "Expected string kind")
    }
}

@Test
func testOptionalPartiallyGenerated() throws {
    // The PartiallyGenerated type should match the wrapped type's PartiallyGenerated
    typealias OptionalString = String?
    typealias PartialString = OptionalString.PartiallyGenerated
    
    // This should compile - verifying the typealias works
    let _: PartialString = "test"
    #expect(true) // If it compiles, the typealias is correct
}

@Test
func testOptionalPromptRepresentable() {
    // Test nil case
    let nilValue: String? = nil
    let nilPrompt = nilValue.promptRepresentation
    // nil should produce empty prompt
    #expect(nilPrompt.promptRepresentation.description == "")
    
    // Test some case
    let someValue: String? = "prompt text"
    let somePrompt = someValue.promptRepresentation
    #expect(somePrompt.promptRepresentation.description.contains("prompt text"))
}

@Test
func testOptionalInstructionsRepresentable() {
    // Test nil case  
    let nilValue: String? = nil
    let nilInstructions = nilValue.instructionsRepresentation
    // nil should produce empty instructions
    #expect(nilInstructions.instructionsRepresentation.description == "")
    
    // Test some case
    let someValue: String? = "instruction text"
    let someInstructions = someValue.instructionsRepresentation
    #expect(someInstructions.instructionsRepresentation.description.contains("instruction text"))
}

@Test
func testNestedOptionals() throws {
    // Test Optional<Optional<String>>
    let doubleNil: String?? = nil
    let doubleNilContent = doubleNil.generatedContent
    #expect(doubleNilContent.kind == .null)
    
    let innerNil: String?? = .some(nil)
    let innerNilContent = innerNil.generatedContent
    #expect(innerNilContent.kind == .null)
    
    let someValue: String?? = .some(.some("nested"))
    let someContent = someValue.generatedContent
    switch someContent.kind {
    case .string(let s):
        #expect(s == "nested")
    default:
        #expect(Bool(false), "Expected string kind")
    }
}

@Test
func testOptionalArrays() throws {
    // Test Optional<Array<String>>
    let nilArray: [String]? = nil
    let nilArrayContent = nilArray.generatedContent
    #expect(nilArrayContent.kind == .null)
    
    let emptyArray: [String]? = []
    let emptyArrayContent = emptyArray.generatedContent
    switch emptyArrayContent.kind {
    case .array(let arr):
        #expect(arr.isEmpty)
    default:
        #expect(Bool(false), "Expected array kind")
    }
    
    let someArray: [String]? = ["a", "b", "c"]
    let someArrayContent = someArray.generatedContent
    switch someArrayContent.kind {
    case .array(let arr):
        #expect(arr.count == 3)
    default:
        #expect(Bool(false), "Expected array kind")
    }
}