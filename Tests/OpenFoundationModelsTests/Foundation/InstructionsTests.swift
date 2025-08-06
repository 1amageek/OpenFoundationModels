// InstructionsTests.swift
// OpenFoundationModelsTests
//
// ✅ APPLE OFFICIAL: Tests for Apple Foundation Models Instructions system

import Foundation
import Testing
@testable import OpenFoundationModels

/// Tests for Instructions and InstructionsBuilder
/// 
/// **Focus:** Validates Instructions structure and InstructionsBuilder functionality
/// according to Apple's Foundation Models specification.
///
/// **Apple Foundation Models Documentation:**
/// Instructions provide context and guidance to language models for generating responses.
/// InstructionsBuilder enables result builder syntax for composing instructions.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/instructions
@Suite("Instructions Tests", .tags(.foundation))
struct InstructionsTests {
    
    // MARK: - Basic Instructions Tests
    
    @Test("Instructions creation with string")
    func instructionsStringCreation() {
        let instructions = Instructions("Write a short story")
        
        #expect(instructions.description == "Write a short story")
        #expect(!instructions.description.isEmpty)
    }
    
    @Test("Instructions creation with empty string")
    func instructionsEmptyCreation() {
        let instructions = Instructions("")
        
        #expect(instructions.description == "")
        #expect(instructions.description.isEmpty)
    }
    
    @Test("Instructions text property access")
    func instructionsTextAccess() {
        let text = "Generate a user profile with name and age"
        let instructions = Instructions(text)
        
        #expect(instructions.description == text)
    }
    
    // MARK: - InstructionsRepresentable Tests
    
    @Test("String conforms to InstructionsRepresentable")
    func stringInstructionsRepresentable() {
        let text = "Test instructions"
        let instructions = text.instructionsRepresentation
        
        #expect(instructions.description == text)
    }
    
    @Test("GeneratedContent conforms to InstructionsRepresentable")
    func generatedContentInstructionsRepresentable() {
        let content = GeneratedContent("Generated instructions")
        let instructions = content.instructionsRepresentation
        
        #expect(instructions.description == "Generated instructions")
    }
    
    // MARK: - InstructionsBuilder Tests
    
    @Test("InstructionsBuilder with single component")
    func instructionsBuilderSingle() {
        @InstructionsBuilder
        func buildInstructions() -> Instructions {
            "Write a detailed description"
        }
        
        let instructions = buildInstructions()
        #expect(instructions.description == "Write a detailed description")
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
        #expect(instructions.description == expected)
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
        #expect(instructions.description == expected)
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
        #expect(instructions.description == expected)
    }
    
    @Test("InstructionsBuilder buildBlock method")
    func instructionsBuilderBlock() {
        let instructions = InstructionsBuilder.buildBlock(
            "Component 1",
            "Component 2",
            "Component 3"
        )
        let expected = "Component 1\nComponent 2\nComponent 3"
        #expect(instructions.description == expected)
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
        #expect(instructions.description == "First branch")
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
        #expect(instructions.description == "Second branch")
    }
    
    @Test("InstructionsBuilder buildExpression")
    func instructionsBuilderExpression() {
        let expression = "Test expression"
        let instructions = InstructionsBuilder.buildExpression(expression)
        
        #expect(instructions.description == expression)
    }
    
    @Test("InstructionsBuilder buildOptional with value")
    func instructionsBuilderOptionalWithValue() {
        let optionalInstructions = Instructions("Optional content")
        let instructions = InstructionsBuilder.buildOptional(optionalInstructions)
        
        #expect(instructions.description == "Optional content")
    }
    
    @Test("InstructionsBuilder buildOptional with nil")
    func instructionsBuilderOptionalNil() {
        let instructions = InstructionsBuilder.buildOptional(nil)
        
        #expect(instructions.description == "")
    }
    
    @Test("InstructionsBuilder buildLimitedAvailability")
    func instructionsBuilderLimitedAvailability() {
        let component = "Limited availability content"
        let instructions = InstructionsBuilder.buildLimitedAvailability(component)
        
        #expect(instructions.description == component)
    }
    
    // MARK: - Complex InstructionsBuilder Scenarios
    
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
        #expect(instructions.description == expected)
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
        #expect(instructions.description == expected)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Instructions with very long text")
    func instructionsLongText() {
        let longText = String(repeating: "A", count: 10000)
        let instructions = Instructions(longText)
        
        #expect(instructions.description.count == 10000)
        #expect(instructions.description.allSatisfy { $0 == "A" })
    }
    
    @Test("Instructions with special characters")
    func instructionsSpecialCharacters() {
        let specialText = "Instructions with émojis 🚀, ñewlines\n, tabs\t, and \"quotes\""
        let instructions = Instructions(specialText)
        
        #expect(instructions.description == specialText)
        #expect(instructions.description.contains("🚀"))
        #expect(instructions.description.contains("\n"))
        #expect(instructions.description.contains("\t"))
    }
    
    @Test("Instructions with Unicode characters")
    func instructionsUnicodeCharacters() {
        let unicodeText = "Unicode: 日本語, العربية, русский, 中文"
        let instructions = Instructions(unicodeText)
        
        #expect(instructions.description == unicodeText)
        #expect(instructions.description.contains("日本語"))
        #expect(instructions.description.contains("العربية"))
    }
    
    // MARK: - Performance Tests
    
    @Test("Instructions creation performance", .timeLimit(.minutes(1)))
    func instructionsCreationPerformance() {
        let text = "Performance test instruction"
        
        for _ in 0..<1000 {
            let instructions = Instructions(text)
            #expect(instructions.description == text)
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
        #expect(instructions.description.contains("Component 1"))
        #expect(instructions.description.contains("Component 100"))
        #expect(!instructions.description.isEmpty)
    }
}