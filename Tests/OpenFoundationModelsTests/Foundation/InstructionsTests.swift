
import Foundation
import Testing
@testable import OpenFoundationModels

@Suite("Instructions Tests", .tags(.foundation))
struct InstructionsTests {
    
    
    @Test("Instructions creation with string")
    func instructionsStringCreation() {
        let instructions = Instructions("Write a short story")
        
        #expect(instructions.content == "Write a short story")
        #expect(!instructions.content.isEmpty)
    }
    
    @Test("Instructions creation with empty string")
    func instructionsEmptyCreation() {
        let instructions = Instructions("")
        
        #expect(instructions.content == "")
        #expect(instructions.content.isEmpty)
    }
    
    @Test("Instructions text property access")
    func instructionsTextAccess() {
        let text = "Generate a user profile with name and age"
        let instructions = Instructions(text)
        
        #expect(instructions.content == text)
    }
    
    
    @Test("String conforms to InstructionsRepresentable")
    func stringInstructionsRepresentable() {
        let text = "Test instructions"
        let instructions = text.instructionsRepresentation
        
        #expect(instructions.content == text)
    }
    
    @Test("GeneratedContent conforms to InstructionsRepresentable")
    func generatedContentInstructionsRepresentable() {
        let content = GeneratedContent("Generated instructions")
        let instructions = content.instructionsRepresentation
        
        #expect(instructions.content == "Generated instructions")
    }
    
    
    @Test("InstructionsBuilder with single component")
    func instructionsBuilderSingle() {
        @InstructionsBuilder
        func buildInstructions() -> Instructions {
            "Write a detailed description"
        }
        
        let instructions = buildInstructions()
        #expect(instructions.content == "Write a detailed description")
    }
    
    @Test("InstructionsBuilder with multiple components")
    func instructionsBuilderMultiple() {
        @InstructionsBuilder
        func buildInstructions() -> Instructions {
            "First instruction line"
            "Second instruction line"
            "Third instruction line"
        }
        
        let instructions = buildInstructions()
        let expected = "First instruction line\nSecond instruction line\nThird instruction line"
        #expect(instructions.content == expected)
    }
    
    @Test("InstructionsBuilder with mixed types")
    func instructionsBuilderMixedTypes() {
        let dynamicContent = GeneratedContent("Dynamic content")
        
        @InstructionsBuilder
        func buildInstructions() -> Instructions {
            "Static instruction"
            dynamicContent
            "Another static instruction"
        }
        
        let instructions = buildInstructions()
        let expected = "Static instruction\nDynamic content\nAnother static instruction"
        #expect(instructions.content == expected)
    }
    
    @Test("InstructionsBuilder buildArray method")
    func instructionsBuilderArray() {
        let components = [
            "First component",
            "Second component",
            "Third component"
        ]
        
        let instructions = InstructionsBuilder.buildArray(components)
        let expected = "First component\nSecond component\nThird component"
        #expect(instructions.content == expected)
    }
    
    @Test("InstructionsBuilder buildBlock method")
    func instructionsBuilderBlock() {
        let instructions = InstructionsBuilder.buildBlock(
            "Component 1",
            "Component 2",
            "Component 3"
        )
        let expected = "Component 1\nComponent 2\nComponent 3"
        #expect(instructions.content == expected)
    }
    
    @Test("InstructionsBuilder buildEither first")
    func instructionsBuilderEitherFirst() {
        let condition = true
        
        @InstructionsBuilder
        func buildConditional() -> Instructions {
            if condition {
                "First branch"
            } else {
                "Second branch"
            }
        }
        
        let instructions = buildConditional()
        #expect(instructions.content == "First branch")
    }
    
    @Test("InstructionsBuilder buildEither second")
    func instructionsBuilderEitherSecond() {
        let condition = false
        
        @InstructionsBuilder
        func buildConditional() -> Instructions {
            if condition {
                "First branch"
            } else {
                "Second branch"
            }
        }
        
        let instructions = buildConditional()
        #expect(instructions.content == "Second branch")
    }
    
    @Test("InstructionsBuilder buildExpression")
    func instructionsBuilderExpression() {
        let expression = "Test expression"
        let result = InstructionsBuilder.buildExpression(expression)

        #expect(result.instructionsRepresentation.content == expression)
    }
    
    @Test("InstructionsBuilder buildOptional with value")
    func instructionsBuilderOptionalWithValue() {
        let optionalInstructions = Instructions("Optional content")
        let instructions = InstructionsBuilder.buildOptional(optionalInstructions)
        
        #expect(instructions.content == "Optional content")
    }
    
    @Test("InstructionsBuilder buildOptional with nil")
    func instructionsBuilderOptionalNil() {
        let instructions = InstructionsBuilder.buildOptional(nil)
        
        #expect(instructions.content == "")
    }
    
    @Test("InstructionsBuilder buildLimitedAvailability")
    func instructionsBuilderLimitedAvailability() {
        let component = "Limited availability content"
        let instructions = InstructionsBuilder.buildLimitedAvailability(component)
        
        #expect(instructions.content == component)
    }
    
    
    @Test("Instructions creation with @InstructionsBuilder initializer")
    func instructionsBuilderInitializer() {
        let instructions1 = Instructions {
            "You are a helpful assistant."
        }
        #expect(instructions1.content == "You are a helpful assistant.")
        
        let instructions2 = Instructions {
            "You are a code review assistant."
            "Focus on code quality and best practices."
            "Provide constructive feedback."
        }
        #expect(instructions2.content.contains("code review assistant"))
        #expect(instructions2.content.contains("code quality"))
        #expect(instructions2.content.contains("constructive feedback"))
    }
    
    @Test("Instructions builder with conditional content")
    func instructionsBuilderConditional() {
        let shouldBeVerbose = true
        let shouldIncludeExamples = false
        
        let instructions = Instructions {
            "You are a technical documentation writer."
            if shouldBeVerbose {
                "Provide detailed explanations for all concepts."
            }
            if shouldIncludeExamples {
                "Include code examples for each topic."
            }
        }
        
        #expect(instructions.content.contains("technical documentation writer"))
        #expect(instructions.content.contains("detailed explanations"))
        #expect(!instructions.content.contains("code examples"))
    }
    
    @Test("Instructions builder with loops")
    func instructionsBuilderWithLoops() {
        let topics = ["performance", "security", "maintainability"]
        
        let instructions = Instructions {
            "Review the code focusing on:"
            for topic in topics {
                "- \(topic)"
            }
            "Provide specific recommendations."
        }
        
        #expect(instructions.content.contains("Review the code"))
        #expect(instructions.content.contains("- performance"))
        #expect(instructions.content.contains("- security"))
        #expect(instructions.content.contains("- maintainability"))
        #expect(instructions.content.contains("specific recommendations"))
    }
    
    @Test("Instructions builder with InstructionsRepresentable types")
    func instructionsBuilderWithInstructionsRepresentable() {
        let baseInstructions = "Base system instructions"
        let additionalContext = GeneratedContent("Additional context from generation")
        
        let instructions = Instructions {
            baseInstructions
            additionalContext
            "Final instructions"
        }
        
        #expect(instructions.content.contains("Base system instructions"))
        #expect(instructions.content.contains("Additional context from generation"))
        #expect(instructions.content.contains("Final instructions"))
    }
    
    @Test("Instructions builder with nested builders")
    func instructionsBuilderNested() {
        let nestedInstructions = Instructions {
            "Nested instruction set"
            "With multiple lines"
        }
        
        let instructions = Instructions {
            "Main instructions"
            nestedInstructions
            "After nested"
        }
        
        #expect(instructions.content.contains("Main instructions"))
        #expect(instructions.content.contains("Nested instruction set"))
        #expect(instructions.content.contains("With multiple lines"))
        #expect(instructions.content.contains("After nested"))
    }
    
    @Test("Instructions builder with optional content")
    func instructionsBuilderOptional() {
        let optionalGuideline: String? = "Optional guideline"
        let nilGuideline: String? = nil
        
        let instructions = Instructions {
            "Core instructions"
            if let guideline = optionalGuideline {
                guideline
            }
            if let guideline = nilGuideline {
                guideline
            }
            "End of instructions"
        }
        
        #expect(instructions.content.contains("Core instructions"))
        #expect(instructions.content.contains("Optional guideline"))
        #expect(instructions.content.contains("End of instructions"))
    }
    
    @Test("Instructions builder with switch statements")
    func instructionsBuilderSwitch() {
        enum ModelRole {
            case assistant, reviewer, translator
        }
        
        let role = ModelRole.reviewer
        
        let instructions = Instructions {
            "You are acting as a:"
            switch role {
            case .assistant:
                "General purpose assistant providing helpful responses"
            case .reviewer:
                "Code reviewer focusing on quality and best practices"
            case .translator:
                "Language translator ensuring accuracy and context"
            }
        }
        
        #expect(instructions.content.contains("You are acting as"))
        #expect(instructions.content.contains("Code reviewer"))
        #expect(!instructions.content.contains("General purpose assistant"))
        #expect(!instructions.content.contains("Language translator"))
    }
    
    @Test("Instructions builder matching Apple's example")
    func instructionsBuilderAppleExample() {
        let instructions = Instructions {
            "Suggest related topics. Keep them concise (three to seven words) and"
            "make sure they build naturally from the person's topic."
        }
        
        #expect(instructions.content.contains("Suggest related topics"))
        #expect(instructions.content.contains("three to seven words"))
        #expect(instructions.content.contains("build naturally"))
    }
    
    @Test("Instructions builder with complex dynamic content")
    func instructionsBuilderComplexDynamic() {
        let includePersona = true
        let maxResponseLength = 500
        let allowedTopics = ["Swift", "iOS", "macOS"]
        
        let instructions = Instructions {
            if includePersona {
                "You are an experienced Apple platforms developer."
            }
            
            "When answering questions:"
            for topic in allowedTopics {
                "- You may discuss \(topic)"
            }
            
            "Keep responses under \(maxResponseLength) words."
            
            if maxResponseLength < 1000 {
                "Be concise and to the point."
            }
        }
        
        #expect(instructions.content.contains("experienced Apple platforms developer"))
        #expect(instructions.content.contains("You may discuss Swift"))
        #expect(instructions.content.contains("You may discuss iOS"))
        #expect(instructions.content.contains("You may discuss macOS"))
        #expect(instructions.content.contains("Keep responses under 500 words"))
        #expect(instructions.content.contains("Be concise"))
    }
    
    
    @Test("InstructionsBuilder with conditionals and optionals")
    func instructionsBuilderComplexScenario() {
        let includeExample = true
        let optionalContext: String? = "Additional context"
        
        @InstructionsBuilder
        func buildComplexInstructions() -> Instructions {
            "Base instruction"
            
            if includeExample {
                "Example: Generate a user profile"
            }
            
            if let context = optionalContext {
                context
            }
            
            "Final instruction"
        }
        
        let instructions = buildComplexInstructions()
        let expected = "Base instruction\nExample: Generate a user profile\nAdditional context\nFinal instruction"
        #expect(instructions.content == expected)
    }
    
    @Test("InstructionsBuilder with array of components")
    func instructionsBuilderWithArray() {
        let steps = [
            "Step 1: Analyze the input",
            "Step 2: Generate structure",
            "Step 3: Validate output"
        ]
        
        @InstructionsBuilder
        func buildInstructionsWithArray() -> Instructions {
            "Process Overview:"
            for step in steps {
                step
            }
            "Complete the process carefully."
        }
        
        let instructions = buildInstructionsWithArray()
        let expectedSteps = steps.joined(separator: "\n")
        let expected = "Process Overview:\n\(expectedSteps)\nComplete the process carefully."
        #expect(instructions.content == expected)
    }
    
    
    @Test("Instructions with very long text")
    func instructionsLongText() {
        let longText = String(repeating: "A", count: 10000)
        let instructions = Instructions(longText)
        
        #expect(instructions.content.count == 10000)
        #expect(instructions.content.allSatisfy { $0 == "A" })
    }
    
    @Test("Instructions with special characters")
    func instructionsSpecialCharacters() {
        let specialText = "Instructions with émojis 🚀, ñewlines\n, tabs\t, and \"quotes\""
        let instructions = Instructions(specialText)
        
        #expect(instructions.content == specialText)
        #expect(instructions.content.contains("🚀"))
        #expect(instructions.content.contains("\n"))
        #expect(instructions.content.contains("\t"))
    }
    
    @Test("Instructions with Unicode characters")
    func instructionsUnicodeCharacters() {
        let unicodeText = "Unicode: 日本語, العربية, русский, 中文"
        let instructions = Instructions(unicodeText)
        
        #expect(instructions.content == unicodeText)
        #expect(instructions.content.contains("日本語"))
        #expect(instructions.content.contains("العربية"))
    }
    
    
    @Test("Instructions creation performance", .timeLimit(.minutes(1)))
    func instructionsCreationPerformance() {
        let text = "Performance test instruction"
        
        for _ in 0..<1000 {
            let instructions = Instructions(text)
            #expect(instructions.content == text)
        }
    }
    
    @Test("InstructionsBuilder performance with many components", .timeLimit(.minutes(1)))
    func instructionsBuilderPerformance() {
        let components = (1...100).map { "Component \($0)" }
        
        @InstructionsBuilder
        func buildManyInstructions() -> Instructions {
            for component in components {
                component
            }
        }
        
        let instructions = buildManyInstructions()
        #expect(instructions.content.contains("Component 1"))
        #expect(instructions.content.contains("Component 100"))
        #expect(!instructions.content.isEmpty)
    }
}