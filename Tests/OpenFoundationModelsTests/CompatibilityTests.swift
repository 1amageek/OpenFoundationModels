import Foundation
import Testing
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore

@Suite("Apple API Compatibility Tests")
struct CompatibilityTests {
    
    @Test("ConvertibleToGeneratedContent inherits from InstructionsRepresentable and PromptRepresentable")
    func testProtocolInheritance() {
        // This test verifies that the protocol inheritance is correct
        // If this compiles, the inheritance is working
        struct TestContent: ConvertibleToGeneratedContent {
            var generatedContent: GeneratedContent {
                return GeneratedContent("test")
            }
            
            var instructionsRepresentation: Instructions {
                return Instructions("test")
            }
            
            var promptRepresentation: Prompt {
                return Prompt("test")
            }
        }
        
        let content = TestContent()
        #expect(content.generatedContent.text == "test")
    }
    
    @Test("Optional<Generable> has PartiallyGenerated typealias")
    func testOptionalPartiallyGenerated() {
        // Test that Optional<String> has PartiallyGenerated
        typealias OptionalStringPartial = Optional<String>.PartiallyGenerated
        
        // This should be String (not Optional<String>)
        let _: OptionalStringPartial = "test"
        
        #expect(true) // If it compiles, it works
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
        
        #expect(somePrompt.content.contains("hello"))
        #expect(nonePrompt.content == "")
    }
    
    @Test("Optional conforms to InstructionsRepresentable")
    func testOptionalInstructionsRepresentable() {
        let someString: String? = "hello"
        let noneString: String? = nil
        
        let someInstructions = someString.instructionsRepresentation
        let noneInstructions = noneString.instructionsRepresentation
        
        #expect(someInstructions.content.contains("hello"))
        #expect(noneInstructions.content == "")
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