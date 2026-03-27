import Testing
@_spi(Internal) import Generation
@testable import OpenFoundationModels

@Test
func testOptionalConvertibleFromGeneratedContent() throws {
    let nullContent = GeneratedContent(kind: .null)
    let nilValue: String? = try Optional<String>(nullContent)
    #expect(nilValue == nil)

    let stringContent = GeneratedContent(kind: .string("hello"))
    let someValue: String? = try Optional<String>(stringContent)
    #expect(someValue == "hello")
}

@Test
func testOptionalConvertibleToGeneratedContent() throws {
    let nilValue: String? = nil
    let nilContent = nilValue.generatedContent
    #expect(nilContent.kind == .null)

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
    typealias OptionalString = String?
    typealias PartialString = OptionalString.PartiallyGenerated
    let _: PartialString = "test"
    #expect(Bool(true))
}

@Test
func testOptionalPromptRepresentable() {
    let nilValue: String? = nil
    let nilPrompt = nilValue.promptRepresentation
    #expect(nilPrompt.components.isEmpty || {
        guard case .text(let t) = nilPrompt.components.first else { return true }
        return t.value.isEmpty
    }())

    let someValue: String? = "prompt text"
    let somePrompt = someValue.promptRepresentation
    guard case .text(let t) = somePrompt.components.first else {
        Issue.record("Expected text component"); return
    }
    #expect(t.value.contains("prompt text"))
}

@Test
func testOptionalInstructionsRepresentable() {
    let nilValue: String? = nil
    let nilInstructions = nilValue.instructionsRepresentation
    #expect(nilInstructions.components.isEmpty || {
        guard case .text(let t) = nilInstructions.components.first else { return true }
        return t.value.isEmpty
    }())

    let someValue: String? = "instruction text"
    let someInstructions = someValue.instructionsRepresentation
    guard case .text(let t) = someInstructions.components.first else {
        Issue.record("Expected text component"); return
    }
    #expect(t.value.contains("instruction text"))
}

@Test
func testNestedOptionals() throws {
    let doubleNil: String?? = nil
    #expect(doubleNil.generatedContent.kind == .null)

    let innerNil: String?? = .some(nil)
    #expect(innerNil.generatedContent.kind == .null)

    let someValue: String?? = .some(.some("nested"))
    switch someValue.generatedContent.kind {
    case .string(let s):
        #expect(s == "nested")
    default:
        #expect(Bool(false), "Expected string kind")
    }
}

@Test
func testOptionalArrays() throws {
    let nilArray: [String]? = nil
    #expect(nilArray.generatedContent.kind == .null)

    let emptyArray: [String]? = []
    switch emptyArray.generatedContent.kind {
    case .array(let arr):
        #expect(arr.isEmpty)
    default:
        #expect(Bool(false), "Expected array kind")
    }

    let someArray: [String]? = ["a", "b", "c"]
    switch someArray.generatedContent.kind {
    case .array(let arr):
        #expect(arr.count == 3)
    default:
        #expect(Bool(false), "Expected array kind")
    }
}
