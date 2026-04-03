
import Foundation
import Testing
@testable import OpenFoundationModels
@_spi(Internal) @testable import OpenFoundationModelsCore

@Suite("Prompt Tests", .tags(.foundation))
struct PromptTests {

    @Test("Prompt creation with string")
    func promptStringCreation() {
        let prompt = Prompt("What is the weather like today?")

        #expect(prompt.components.count == 1)
        guard case .text(let t) = prompt.components[0] else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value == "What is the weather like today?")
    }

    @Test("Prompt creation with empty string")
    func promptEmptyCreation() {
        let prompt = Prompt("")

        #expect(prompt.components.count == 1)
        guard case .text(let t) = prompt.components[0] else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.isEmpty)
    }

    @Test("Prompt text property access")
    func promptTextAccess() {
        let text = "Generate a detailed user profile"
        let prompt = Prompt(text)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value == text)
    }

    @Test("String conforms to PromptRepresentable")
    func stringPromptRepresentable() {
        let text = "Test prompt"
        let prompt = text.promptRepresentation

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value == text)
    }

    @Test("Prompt complex queries")
    func promptComplexQueries() {
        let complexQuery = """
        Generate a JSON structure for a user profile with the following requirements:
        1. Name (string, required)
        2. Age (integer, 18-100)
        3. Email (string, valid email format)
        4. Preferences (array of strings)

        Ensure the output follows proper JSON formatting.
        """

        let prompt = Prompt(complexQuery)

        #expect(prompt.components.count == 1)
        guard case .text(let t) = prompt.components[0] else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value == complexQuery)
        #expect(t.value.contains("JSON structure"))
        #expect(t.value.contains("requirements:"))
        #expect(t.value.contains("proper JSON formatting"))
    }

    @Test("Prompt with structured content")
    func promptStructuredContent() {
        let structuredPrompt = """
        TASK: Generate a weather report

        INPUT:
        - Location: Tokyo, Japan
        - Date: Today
        - Include: Temperature, humidity, conditions

        OUTPUT FORMAT:
        - Clear, concise summary
        - Include units (Celsius, percentage)
        - Mention any weather warnings
        """

        let prompt = Prompt(structuredPrompt)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("TASK:"))
        #expect(t.value.contains("INPUT:"))
        #expect(t.value.contains("OUTPUT FORMAT:"))
        #expect(t.value.contains("Tokyo, Japan"))
    }

    @Test("Prompt with special formatting")
    func promptSpecialFormatting() {
        let formattedPrompt = """
        Please generate code in the following format:

        ```swift
        struct User {
            let name: String
            let age: Int
        }
        ```

        Ensure proper Swift syntax and conventions.
        """

        let prompt = Prompt(formattedPrompt)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("```swift"))
        #expect(t.value.contains("struct User"))
        #expect(t.value.contains("Swift syntax"))
    }

    @Test("Prompt with markdown-like content")
    func promptMarkdownContent() {
        let markdownPrompt = """
        # Task Description

        Generate a **detailed** analysis of the following:

        - *Item 1*: Performance metrics
        - *Item 2*: User feedback
        - *Item 3*: Recommendations

        ## Output Requirements

        1. Use clear headings
        2. Include bullet points
        3. Provide specific examples
        """

        let prompt = Prompt(markdownPrompt)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("# Task Description"))
        #expect(t.value.contains("**detailed**"))
        #expect(t.value.contains("*Item 1*"))
        #expect(t.value.contains("## Output Requirements"))
    }

    @Test("Prompt with international characters")
    func promptInternationalCharacters() {
        let internationalPrompt = """
        Generate responses in multiple languages:

        English: Hello, how are you?
        Spanish: Hola, ¿cómo estás?
        French: Bonjour, comment allez-vous?
        Japanese: こんにちは、元気ですか？
        Arabic: مرحبا، كيف حالك؟
        Russian: Привет, как дела?
        Chinese: 你好，你好吗？
        """

        let prompt = Prompt(internationalPrompt)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("Hello, how are you?"))
        #expect(t.value.contains("¿cómo estás?"))
        #expect(t.value.contains("comment allez-vous?"))
        #expect(t.value.contains("こんにちは"))
        #expect(t.value.contains("مرحبا"))
        #expect(t.value.contains("Привет"))
        #expect(t.value.contains("你好"))
    }

    @Test("Prompt with emojis and symbols")
    func promptEmojisAndSymbols() {
        let emojiPrompt = """
        Create a fun description with emojis:

        🌟 Features: Amazing functionality
        🚀 Performance: Lightning fast
        💡 Innovation: Cutting-edge technology
        🎯 Goal: User satisfaction
        ✅ Quality: Thoroughly tested

        Use symbols: ©, ®, ™, §, ¶, †, ‡
        Math symbols: ∑, ∆, π, ∞, ≤, ≥, ≠
        """

        let prompt = Prompt(emojiPrompt)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("🌟"))
        #expect(t.value.contains("🚀"))
        #expect(t.value.contains("💡"))
        #expect(t.value.contains("©"))
        #expect(t.value.contains("∑"))
        #expect(t.value.contains("π"))
    }

    @Test("Prompt with very long content")
    func promptLongContent() {
        let longContent = String(repeating: "This is a test sentence. ", count: 100)
        let prompt = Prompt(longContent)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.count > 2000)
        #expect(t.value.hasPrefix("This is a test sentence."))
        #expect(t.value.hasSuffix("This is a test sentence. "))
    }

    @Test("Prompt with whitespace variations")
    func promptWhitespaceVariations() {
        let whitespacePrompt = """


            Prompt with various whitespace:

                - Leading spaces
            \t- Tabs and spaces


            Multiple blank lines above and below


        """

        let prompt = Prompt(whitespacePrompt)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("various whitespace"))
        #expect(t.value.contains("Leading spaces"))
        #expect(t.value.contains("Tabs and spaces"))
        #expect(t.value.hasPrefix("\n\n"))
        #expect(t.value.hasSuffix("\n\n"))
    }

    @Test("Prompt with escape characters")
    func promptEscapeCharacters() {
        let escapePrompt = """
        Handle escape characters properly:

        Quotes: "double" and 'single'
        Backslashes: \\ and \\n and \\t
        Special: \\", \\', \\r, \\0
        Unicode: \\u0041 (A), \\u00A9 (©)
        """

        let prompt = Prompt(escapePrompt)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("\"double\""))
        #expect(t.value.contains("'single'"))
        #expect(t.value.contains("\\"))
        #expect(t.value.contains("\\u0041"))
    }

    @Test("Prompt creation performance", .timeLimit(.minutes(1)))
    func promptCreationPerformance() {
        let content = "Performance test prompt with moderate length content for benchmarking"

        for _ in 0..<1000 {
            let prompt = Prompt(content)
            guard case .text(let t) = prompt.components.first else {
                Issue.record("Expected text component"); return
            }
            #expect(t.value == content)
        }
    }

    @Test("Large prompt handling", .timeLimit(.minutes(1)))
    func largePromptHandling() {
        let largeContent = (1...1000).map { "Line \($0): This is a test line with some content." }.joined(separator: "\n")

        let prompt = Prompt(largeContent)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("Line 1:"))
        #expect(t.value.contains("Line 1000:"))
        #expect(t.value.components(separatedBy: "\n").count == 1000)
    }

    @Test("Prompt creation with @PromptBuilder initializer")
    func promptBuilderInitializer() {
        let prompt1 = Prompt {
            "Hello, world!"
        }
        #expect(prompt1.components == [.text(Prompt.Text(value: "Hello, world!"))])

        let prompt2 = Prompt {
            "Line 1"
            "Line 2"
            "Line 3"
        }
        #expect(prompt2.components == [
            .text(Prompt.Text(value: "Line 1")),
            .text(Prompt.Text(value: "Line 2")),
            .text(Prompt.Text(value: "Line 3"))
        ])
    }

    @Test("Prompt builder with conditional content")
    func promptBuilderConditional() {
        let shouldRhyme = true
        let userInput = "What is Swift?"

        let prompt = Prompt {
            "Answer the following question from the user: \(userInput)"
            if shouldRhyme {
                "Your response MUST rhyme!"
            }
        }

        #expect(prompt.components.count == 2)
        guard case .text(let t0) = prompt.components[0],
              case .text(let t1) = prompt.components[1] else {
            Issue.record("Expected text components"); return
        }
        #expect(t0.value.contains("Answer the following question"))
        #expect(t0.value.contains("What is Swift?"))
        #expect(t1.value == "Your response MUST rhyme!")

        let shouldBeVerbose = false
        let prompt2 = Prompt {
            "Explain quantum physics"
            if shouldBeVerbose {
                "Provide extensive details and examples"
            }
        }

        #expect(prompt2.components == [.text(Prompt.Text(value: "Explain quantum physics"))])
    }

    @Test("Prompt builder with loops")
    func promptBuilderWithLoops() {
        let items = ["apple", "banana", "orange"]

        let prompt = Prompt {
            "List the following fruits:"
            for item in items {
                "- \(item)"
            }
            "End of list"
        }

        #expect(prompt.components == [
            .text(Prompt.Text(value: "List the following fruits:")),
            .text(Prompt.Text(value: "- apple")),
            .text(Prompt.Text(value: "- banana")),
            .text(Prompt.Text(value: "- orange")),
            .text(Prompt.Text(value: "End of list"))
        ])
    }

    @Test("Prompt builder with PromptRepresentable types")
    func promptBuilderWithPromptRepresentable() {
        let stringPrompt = "This is a string"
        let generatedContent = GeneratedContent("Generated content")

        let prompt = Prompt {
            stringPrompt
            generatedContent
            "Final line"
        }

        #expect(prompt.components.count == 3)
        guard case .text(let t0) = prompt.components[0],
              case .text(let t1) = prompt.components[1],
              case .text(let t2) = prompt.components[2] else {
            Issue.record("Expected text components"); return
        }
        #expect(t0.value == "This is a string")
        #expect(t1.value.contains("Generated content"))
        #expect(t2.value == "Final line")
    }

    @Test("Prompt builder with nested builders")
    func promptBuilderNested() {
        let nestedPrompt = Prompt {
            "Nested content"
            "More nested content"
        }

        let prompt = Prompt {
            "Outer content"
            nestedPrompt
            "After nested"
        }

        #expect(prompt.components == [
            .text(Prompt.Text(value: "Outer content")),
            .text(Prompt.Text(value: "Nested content")),
            .text(Prompt.Text(value: "More nested content")),
            .text(Prompt.Text(value: "After nested"))
        ])
    }

    @Test("Prompt builder with optional content")
    func promptBuilderOptional() {
        let optionalContent: String? = "Optional text"
        let nilContent: String? = nil

        let prompt = Prompt {
            "Start"
            if let content = optionalContent {
                content
            }
            if let content = nilContent {
                content
            }
            "End"
        }

        #expect(prompt.components == [
            .text(Prompt.Text(value: "Start")),
            .text(Prompt.Text(value: "Optional text")),
            .text(Prompt.Text(value: "End"))
        ])
    }

    @Test("Prompt builder with switch statements")
    func promptBuilderSwitch() {
        enum ResponseStyle {
            case formal, casual, technical
        }

        let style = ResponseStyle.technical

        let prompt = Prompt {
            "Answer this question:"
            switch style {
            case .formal:
                "Use formal language and proper grammar"
            case .casual:
                "Use casual, friendly language"
            case .technical:
                "Use technical terminology and be precise"
            }
        }

        #expect(prompt.components == [
            .text(Prompt.Text(value: "Answer this question:")),
            .text(Prompt.Text(value: "Use technical terminology and be precise"))
        ])
    }

    @Test("Prompt builder with complex dynamic content")
    func promptBuilderComplexDynamic() {
        let includeExamples = true
        let maxExamples = 3
        let topics = ["Swift", "Objective-C", "SwiftUI"]

        let prompt = Prompt {
            "Create a tutorial covering:"
            for (index, topic) in topics.enumerated() {
                "\(index + 1). \(topic)"
            }

            if includeExamples {
                "Include examples for each topic"
                "Maximum \(maxExamples) examples per topic"
            }

            "Format as markdown"
        }

        #expect(prompt.components == [
            .text(Prompt.Text(value: "Create a tutorial covering:")),
            .text(Prompt.Text(value: "1. Swift")),
            .text(Prompt.Text(value: "2. Objective-C")),
            .text(Prompt.Text(value: "3. SwiftUI")),
            .text(Prompt.Text(value: "Include examples for each topic")),
            .text(Prompt.Text(value: "Maximum \(maxExamples) examples per topic")),
            .text(Prompt.Text(value: "Format as markdown"))
        ])
    }

    @Test("Prompt for code generation")
    func promptCodeGeneration() {
        let codePrompt = """
        Generate a Swift function that:

        1. Takes two integers as parameters
        2. Returns their sum
        3. Includes proper documentation
        4. Follows Swift naming conventions
        5. Includes error handling if needed

        Format the response as valid Swift code.
        """

        let prompt = Prompt(codePrompt)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("Swift function"))
        #expect(t.value.contains("two integers"))
        #expect(t.value.contains("documentation"))
        #expect(t.value.contains("error handling"))
    }

    @Test("Prompt for data analysis")
    func promptDataAnalysis() {
        let analysisPrompt = """
        Analyze the following dataset characteristics:

        Dataset: User engagement metrics
        - Users: 10,000 active users
        - Time period: Last 30 days
        - Metrics: Page views, session duration, bounce rate
        - Segments: Mobile (60%), Desktop (40%)

        Provide insights on:
        1. User behavior patterns
        2. Performance trends
        3. Optimization recommendations
        """

        let prompt = Prompt(analysisPrompt)

        guard case .text(let t) = prompt.components.first else {
            Issue.record("Expected text component"); return
        }
        #expect(t.value.contains("dataset characteristics"))
        #expect(t.value.contains("10,000 active users"))
        #expect(t.value.contains("Mobile (60%)"))
        #expect(t.value.contains("Optimization recommendations"))
    }
}
