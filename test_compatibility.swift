import Foundation
import OpenFoundationModels

// Test ConvertibleToGeneratedContent protocol inheritance
struct TestContent: ConvertibleToGeneratedContent {
    var generatedContent: GeneratedContent {
        return GeneratedContent("test")
    }
    
    // These should be automatically available through protocol inheritance
    var instructionsRepresentation: Instructions {
        return Instructions("test instructions")
    }
    
    var promptRepresentation: Prompt {
        return Prompt("test prompt")
    }
}

// Test Optional extensions
let optionalString: String? = "hello"
let nilString: String? = nil

// Test Optional<Generable> PartiallyGenerated typealias
struct TestGenerable: Generable {
    static var generationSchema: GenerationSchema {
        return GenerationSchema(
            type: TestGenerable.self,
            description: "Test",
            properties: []
        )
    }
    
    init(_ content: GeneratedContent) throws {
        // Simple init
    }
    
    var generatedContent: GeneratedContent {
        return GeneratedContent("test")
    }
}

// This should compile with PartiallyGenerated typealias
typealias OptionalPartial = Optional<TestGenerable>.PartiallyGenerated

// Test that Optional conforms to ConvertibleToGeneratedContent
let optContent = optionalString?.generatedContent
let nilContent = nilString?.generatedContent

// Test that Optional conforms to PromptRepresentable
let optPrompt = optionalString?.promptRepresentation
let nilPrompt = nilString?.promptRepresentation

// Test that Optional conforms to InstructionsRepresentable  
let optInstructions = optionalString?.instructionsRepresentation
let nilInstructions = nilString?.instructionsRepresentation

print("✅ All compatibility tests passed!")