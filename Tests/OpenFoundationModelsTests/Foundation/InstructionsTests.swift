
import Foundation
import Testing
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore

@Suite("Instructions Tests", .tags(.foundation))
struct InstructionsTests {

    @Test("Instructions creation with string")
    func instructionsStringCreation() {
        let instructions = Instructions("Write a short story")

        #expect(instructions.components == [.text(Instructions.Text(value: "Write a short story"))])
    }

    @Test("Instructions creation with empty string")
    func instructionsEmptyCreation() {
        let instructions = Instructions("")

        #expect(instructions.components == [.text(Instructions.Text(value: ""))])
    }

    @Test("Instructions text property access")
    func instructionsTextAccess() {
        let text = "Generate a user profile with name and age"
        let instructions = Instructions(text)

        #expect(instructions.components == [.text(Instructions.Text(value: text))])
    }

    @Test("String conforms to InstructionsRepresentable")
    func stringInstructionsRepresentable() {
        let text = "Test instructions"
        let instructions = text.instructionsRepresentation

        #expect(instructions.components == [.text(Instructions.Text(value: text))])
    }

    @Test("GeneratedContent conforms to InstructionsRepresentable")
    func generatedContentInstructionsRepresentable() {
        let content = GeneratedContent("Generated instructions")
        let instructions = content.instructionsRepresentation

        guard case .text(let t) = instructions.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value == "\"Generated instructions\"")
    }

    @Test("InstructionsBuilder with single component")
    func instructionsBuilderSingle() {
        @InstructionsBuilder
        func build() -> Instructions {
            "Write a detailed description"
        }

        let instructions = build()
        #expect(instructions.components == [.text(Instructions.Text(value: "Write a detailed description"))])
    }

    @Test("InstructionsBuilder with multiple components")
    func instructionsBuilderMultiple() {
        @InstructionsBuilder
        func build() -> Instructions {
            "First instruction line"
            "Second instruction line"
            "Third instruction line"
        }

        let instructions = build()
        #expect(instructions.components == [
            .text(Instructions.Text(value: "First instruction line")),
            .text(Instructions.Text(value: "Second instruction line")),
            .text(Instructions.Text(value: "Third instruction line"))
        ])
    }

    @Test("InstructionsBuilder with mixed types")
    func instructionsBuilderMixedTypes() {
        let dynamicContent = GeneratedContent("Dynamic content")

        @InstructionsBuilder
        func build() -> Instructions {
            "Static instruction"
            dynamicContent
            "Another static instruction"
        }

        let instructions = build()
        #expect(instructions.components.count == 3)
        guard case .text(let t0) = instructions.components[0],
              case .text(let t1) = instructions.components[1],
              case .text(let t2) = instructions.components[2] else {
            Issue.record("Expected text components"); return
        }
        #expect(t0.value == "Static instruction")
        #expect(t1.value == "\"Dynamic content\"")
        #expect(t2.value == "Another static instruction")
    }

    @Test("InstructionsBuilder buildArray method")
    func instructionsBuilderArray() {
        let items = ["First component", "Second component", "Third component"]
        let instructions = InstructionsBuilder.buildArray(items)

        #expect(instructions.components == [
            .text(Instructions.Text(value: "First component")),
            .text(Instructions.Text(value: "Second component")),
            .text(Instructions.Text(value: "Third component"))
        ])
    }

    @Test("InstructionsBuilder buildBlock method")
    func instructionsBuilderBlock() {
        let instructions = InstructionsBuilder.buildBlock(
            "Component 1",
            "Component 2",
            "Component 3"
        )
        #expect(instructions.components == [
            .text(Instructions.Text(value: "Component 1")),
            .text(Instructions.Text(value: "Component 2")),
            .text(Instructions.Text(value: "Component 3"))
        ])
    }

    @Test("InstructionsBuilder buildEither first")
    func instructionsBuilderEitherFirst() {
        let condition = true

        @InstructionsBuilder
        func build() -> Instructions {
            if condition {
                "First branch"
            } else {
                "Second branch"
            }
        }

        #expect(build().components == [.text(Instructions.Text(value: "First branch"))])
    }

    @Test("InstructionsBuilder buildEither second")
    func instructionsBuilderEitherSecond() {
        let condition = false

        @InstructionsBuilder
        func build() -> Instructions {
            if condition {
                "First branch"
            } else {
                "Second branch"
            }
        }

        #expect(build().components == [.text(Instructions.Text(value: "Second branch"))])
    }

    @Test("InstructionsBuilder buildExpression")
    func instructionsBuilderExpression() {
        let expression = "Test expression"
        let result = InstructionsBuilder.buildExpression(expression)

        #expect(result.instructionsRepresentation.components == [.text(Instructions.Text(value: expression))])
    }

    @Test("InstructionsBuilder buildOptional with value")
    func instructionsBuilderOptionalWithValue() {
        let optional = Instructions("Optional content")
        let instructions = InstructionsBuilder.buildOptional(optional)

        #expect(instructions.components == [.text(Instructions.Text(value: "Optional content"))])
    }

    @Test("InstructionsBuilder buildOptional with nil")
    func instructionsBuilderOptionalNil() {
        let instructions = InstructionsBuilder.buildOptional(nil)

        #expect(instructions.components.isEmpty)
    }

    @Test("InstructionsBuilder buildLimitedAvailability")
    func instructionsBuilderLimitedAvailability() {
        let component = "Limited availability content"
        let instructions = InstructionsBuilder.buildLimitedAvailability(component)

        #expect(instructions.components == [.text(Instructions.Text(value: component))])
    }

    @Test("Instructions creation with @InstructionsBuilder initializer")
    func instructionsBuilderInitializer() {
        let instructions1 = Instructions {
            "You are a helpful assistant."
        }
        #expect(instructions1.components == [.text(Instructions.Text(value: "You are a helpful assistant."))])

        let instructions2 = Instructions {
            "You are a code review assistant."
            "Focus on code quality and best practices."
            "Provide constructive feedback."
        }
        #expect(instructions2.components == [
            .text(Instructions.Text(value: "You are a code review assistant.")),
            .text(Instructions.Text(value: "Focus on code quality and best practices.")),
            .text(Instructions.Text(value: "Provide constructive feedback."))
        ])
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

        #expect(instructions.components == [
            .text(Instructions.Text(value: "You are a technical documentation writer.")),
            .text(Instructions.Text(value: "Provide detailed explanations for all concepts."))
        ])
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

        #expect(instructions.components == [
            .text(Instructions.Text(value: "Review the code focusing on:")),
            .text(Instructions.Text(value: "- performance")),
            .text(Instructions.Text(value: "- security")),
            .text(Instructions.Text(value: "- maintainability")),
            .text(Instructions.Text(value: "Provide specific recommendations."))
        ])
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

        #expect(instructions.components.count == 3)
        guard case .text(let t0) = instructions.components[0],
              case .text(let t1) = instructions.components[1],
              case .text(let t2) = instructions.components[2] else {
            Issue.record("Expected text components"); return
        }
        #expect(t0.value == "Base system instructions")
        #expect(t1.value == "\"Additional context from generation\"")
        #expect(t2.value == "Final instructions")
    }

    @Test("Instructions builder with nested builders")
    func instructionsBuilderNested() {
        let nested = Instructions {
            "Nested instruction set"
            "With multiple lines"
        }

        let instructions = Instructions {
            "Main instructions"
            nested
            "After nested"
        }

        #expect(instructions.components == [
            .text(Instructions.Text(value: "Main instructions")),
            .text(Instructions.Text(value: "Nested instruction set")),
            .text(Instructions.Text(value: "With multiple lines")),
            .text(Instructions.Text(value: "After nested"))
        ])
    }

    @Test("Instructions builder with optional content")
    func instructionsBuilderOptional() {
        let optionalGuideline: String? = "Optional guideline"
        let nilGuideline: String? = nil

        let instructions = Instructions {
            "Core instructions"
            if let g = optionalGuideline { g }
            if let g = nilGuideline { g }
            "End of instructions"
        }

        #expect(instructions.components == [
            .text(Instructions.Text(value: "Core instructions")),
            .text(Instructions.Text(value: "Optional guideline")),
            .text(Instructions.Text(value: "End of instructions"))
        ])
    }

    @Test("Instructions builder with switch statements")
    func instructionsBuilderSwitch() {
        enum ModelRole { case assistant, reviewer, translator }

        let role = ModelRole.reviewer

        let instructions = Instructions {
            "You are acting as a:"
            switch role {
            case .assistant:  "General purpose assistant providing helpful responses"
            case .reviewer:   "Code reviewer focusing on quality and best practices"
            case .translator: "Language translator ensuring accuracy and context"
            }
        }

        #expect(instructions.components == [
            .text(Instructions.Text(value: "You are acting as a:")),
            .text(Instructions.Text(value: "Code reviewer focusing on quality and best practices"))
        ])
    }

    @Test("Instructions builder matching Apple's example")
    func instructionsBuilderAppleExample() {
        let instructions = Instructions {
            "Suggest related topics. Keep them concise (three to seven words) and"
            "make sure they build naturally from the person's topic."
        }

        #expect(instructions.components == [
            .text(Instructions.Text(value: "Suggest related topics. Keep them concise (three to seven words) and")),
            .text(Instructions.Text(value: "make sure they build naturally from the person's topic."))
        ])
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

        #expect(instructions.components == [
            .text(Instructions.Text(value: "You are an experienced Apple platforms developer.")),
            .text(Instructions.Text(value: "When answering questions:")),
            .text(Instructions.Text(value: "- You may discuss Swift")),
            .text(Instructions.Text(value: "- You may discuss iOS")),
            .text(Instructions.Text(value: "- You may discuss macOS")),
            .text(Instructions.Text(value: "Keep responses under 500 words.")),
            .text(Instructions.Text(value: "Be concise and to the point."))
        ])
    }

    @Test("InstructionsBuilder with conditionals and optionals")
    func instructionsBuilderComplexScenario() {
        let includeExample = true
        let optionalContext: String? = "Additional context"

        @InstructionsBuilder
        func build() -> Instructions {
            "Base instruction"
            if includeExample {
                "Example: Generate a user profile"
            }
            if let context = optionalContext {
                context
            }
            "Final instruction"
        }

        #expect(build().components == [
            .text(Instructions.Text(value: "Base instruction")),
            .text(Instructions.Text(value: "Example: Generate a user profile")),
            .text(Instructions.Text(value: "Additional context")),
            .text(Instructions.Text(value: "Final instruction"))
        ])
    }

    @Test("InstructionsBuilder with array of components")
    func instructionsBuilderWithArray() {
        let steps = [
            "Step 1: Analyze the input",
            "Step 2: Generate structure",
            "Step 3: Validate output"
        ]

        @InstructionsBuilder
        func build() -> Instructions {
            "Process Overview:"
            for step in steps { step }
            "Complete the process carefully."
        }

        #expect(build().components == [
            .text(Instructions.Text(value: "Process Overview:")),
            .text(Instructions.Text(value: "Step 1: Analyze the input")),
            .text(Instructions.Text(value: "Step 2: Generate structure")),
            .text(Instructions.Text(value: "Step 3: Validate output")),
            .text(Instructions.Text(value: "Complete the process carefully."))
        ])
    }

    @Test("Instructions with very long text")
    func instructionsLongText() {
        let longText = String(repeating: "A", count: 10000)
        let instructions = Instructions(longText)

        guard case .text(let t) = instructions.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.count == 10000)
        #expect(t.value.allSatisfy { $0 == "A" })
    }

    @Test("Instructions with special characters")
    func instructionsSpecialCharacters() {
        let specialText = "Instructions with émojis 🚀, ñewlines\n, tabs\t, and \"quotes\""
        let instructions = Instructions(specialText)

        #expect(instructions.components == [.text(Instructions.Text(value: specialText))])
    }

    @Test("Instructions with Unicode characters")
    func instructionsUnicodeCharacters() {
        let unicodeText = "Unicode: 日本語, العربية, русский, 中文"
        let instructions = Instructions(unicodeText)

        #expect(instructions.components == [.text(Instructions.Text(value: unicodeText))])
    }

    @Test("Instructions creation performance", .timeLimit(.minutes(1)))
    func instructionsCreationPerformance() {
        let text = "Performance test instruction"

        for _ in 0..<1000 {
            let instructions = Instructions(text)
            #expect(instructions.components == [.text(Instructions.Text(value: text))])
        }
    }

    @Test("InstructionsBuilder performance with many components", .timeLimit(.minutes(1)))
    func instructionsBuilderPerformance() {
        let items = (1...100).map { "Component \($0)" }

        @InstructionsBuilder
        func build() -> Instructions {
            for item in items { item }
        }

        let instructions = build()
        #expect(instructions.components.count == 100)
        guard case .text(let first) = instructions.components.first,
              case .text(let last) = instructions.components.last else {
            Issue.record("Expected text components"); return
        }
        #expect(first.value == "Component 1")
        #expect(last.value == "Component 100")
    }
}
