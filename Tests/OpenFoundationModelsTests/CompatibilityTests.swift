import Foundation
import Testing
@testable import OpenFoundationModels
@_spi(Internal) @testable import OpenFoundationModelsCore

@Suite("Apple API Compatibility Tests")
struct CompatibilityTests {

    @Test("ConvertibleToGeneratedContent inherits from InstructionsRepresentable and PromptRepresentable")
    func testProtocolInheritance() {
        struct TestContent: ConvertibleToGeneratedContent {
            var generatedContent: GeneratedContent { GeneratedContent("test") }
            var instructionsRepresentation: Instructions { Instructions("test") }
            var promptRepresentation: Prompt { Prompt("test") }
        }

        let content = TestContent()
        #expect(content.generatedContent.text == "test")
    }

    @Test("Optional<Generable> has PartiallyGenerated typealias")
    func testOptionalPartiallyGenerated() {
        typealias OptionalStringPartial = Optional<String>.PartiallyGenerated
        let _: OptionalStringPartial = "test"
        #expect(Bool(true))
    }

    @Test("Optional conforms to ConvertibleToGeneratedContent")
    func testOptionalConvertibleToGeneratedContent() {
        let someString: String? = "hello"
        let noneString: String? = nil

        let someContent = someString.generatedContent
        let noneContent = noneString.generatedContent

        #expect(someContent.text == "hello")

        switch noneContent.kind {
        case .null:
            #expect(Bool(true))
        default:
            #expect(Bool(false))
        }
    }

    @Test("Optional conforms to PromptRepresentable")
    func testOptionalPromptRepresentable() {
        let someString: String? = "hello"
        let noneString: String? = nil

        let somePrompt = someString.promptRepresentation
        let nonePrompt = noneString.promptRepresentation

        guard case .text(let t) = somePrompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("hello"))
        // nil produces "null" text via ConvertibleToGeneratedContent default implementation
        guard case .text(let nullText) = nonePrompt.components.first else {
            Issue.record("Expected text component for nil"); return
        }
        #expect(nullText.value == "null")
    }

    @Test("Optional conforms to InstructionsRepresentable")
    func testOptionalInstructionsRepresentable() {
        let someString: String? = "hello"
        let noneString: String? = nil

        let someInstructions = someString.instructionsRepresentation
        let noneInstructions = noneString.instructionsRepresentation

        guard case .text(let t) = someInstructions.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("hello"))
        // nil produces "null" text via ConvertibleToGeneratedContent default implementation
        guard case .text(let nullText) = noneInstructions.components.first else {
            Issue.record("Expected text component for nil"); return
        }
        #expect(nullText.value == "null")
    }

    @Test("Transcript.ToolDefinition has parameters property")
    func testToolDefinitionParameters() {
        let schema = GenerationSchema(
            type: String.self,
            description: "Test",
            properties: []
        )

        let toolDef = Transcript.ToolDefinition(
            name: "test",
            description: "test tool",
            parameters: schema
        )

        #expect(toolDef.name == "test")
        #expect(toolDef.description == "test tool")
        #expect(toolDef.parameters.debugDescription.contains("GenerationSchema"))
    }
}
