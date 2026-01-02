
import Foundation
import Testing
@testable import OpenFoundationModels

@Suite("Prompt Tests", .tags(.foundation))
struct PromptTests {
    
    
    @Test("Prompt creation with string")
    func promptStringCreation() {
        let prompt = Prompt("What is the weather like today?")
        
        #expect(!prompt.content.isEmpty)
        #expect(prompt.content == "What is the weather like today?")
    }
    
    @Test("Prompt creation with empty string")
    func promptEmptyCreation() {
        let prompt = Prompt("")
        
        #expect(prompt.content.isEmpty)
        #expect(prompt.content == "")
    }
    
    @Test("Prompt text property access")
    func promptTextAccess() {
        let text = "Generate a detailed user profile"
        let prompt = Prompt(text)
        
        #expect(prompt.content == text)
    }
    
    
    @Test("String conforms to PromptRepresentable")
    func stringPromptRepresentable() {
        let text = "Test prompt"
        let prompt = text.promptRepresentation
        
        #expect(prompt.content == text)
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
        
        #expect(prompt.content == complexQuery)
        #expect(prompt.content.contains("JSON structure"))
        #expect(prompt.content.contains("requirements:"))
        #expect(prompt.content.contains("proper JSON formatting"))
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
        
        #expect(prompt.content.contains("TASK:"))
        #expect(prompt.content.contains("INPUT:"))
        #expect(prompt.content.contains("OUTPUT FORMAT:"))
        #expect(prompt.content.contains("Tokyo, Japan"))
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
        
        #expect(prompt.content.contains("```swift"))
        #expect(prompt.content.contains("struct User"))
        #expect(prompt.content.contains("Swift syntax"))
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
        
        #expect(prompt.content.contains("# Task Description"))
        #expect(prompt.content.contains("**detailed**"))
        #expect(prompt.content.contains("*Item 1*"))
        #expect(prompt.content.contains("## Output Requirements"))
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
        
        #expect(prompt.content.contains("Hello, how are you?"))
        #expect(prompt.content.contains("¿cómo estás?"))
        #expect(prompt.content.contains("comment allez-vous?"))
        #expect(prompt.content.contains("こんにちは"))
        #expect(prompt.content.contains("مرحبا"))
        #expect(prompt.content.contains("Привет"))
        #expect(prompt.content.contains("你好"))
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
        
        #expect(prompt.content.contains("🌟"))
        #expect(prompt.content.contains("🚀"))
        #expect(prompt.content.contains("💡"))
        #expect(prompt.content.contains("©"))
        #expect(prompt.content.contains("∑"))
        #expect(prompt.content.contains("π"))
    }
    
    
    @Test("Prompt with very long content")
    func promptLongContent() {
        let longContent = String(repeating: "This is a test sentence. ", count: 100)
        let prompt = Prompt(longContent)
        
        #expect(prompt.content.count > 2000)
        #expect(prompt.content.hasPrefix("This is a test sentence."))
        #expect(prompt.content.hasSuffix("This is a test sentence. "))
    }
    
    @Test("Prompt with whitespace variations")
    func promptWhitespaceVariations() {
        let whitespacePrompt = """
        
        
            Prompt with various whitespace:
            
                - Leading spaces
            	- Tabs and spaces
        
        
            Multiple blank lines above and below
        
        
        """
        
        let prompt = Prompt(whitespacePrompt)
        
        #expect(prompt.content.contains("various whitespace"))
        #expect(prompt.content.contains("Leading spaces"))
        #expect(prompt.content.contains("Tabs and spaces"))
        #expect(prompt.content.hasPrefix("\n\n"))
        #expect(prompt.content.hasSuffix("\n\n"))
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
        
        #expect(prompt.content.contains("\"double\""))
        #expect(prompt.content.contains("'single'"))
        #expect(prompt.content.contains("\\"))
        #expect(prompt.content.contains("\\u0041"))
    }
    
    
    @Test("Prompt creation performance", .timeLimit(.minutes(1)))
    func promptCreationPerformance() {
        let content = "Performance test prompt with moderate length content for benchmarking"
        
        for _ in 0..<1000 {
            let prompt = Prompt(content)
            #expect(prompt.content == content)
        }
    }
    
    @Test("Large prompt handling", .timeLimit(.minutes(1)))
    func largePromptHandling() {
        let largeContent = (1...1000).map { "Line \($0): This is a test line with some content." }.joined(separator: "\n")
        
        let prompt = Prompt(largeContent)
        
        #expect(prompt.content.contains("Line 1:"))
        #expect(prompt.content.contains("Line 1000:"))
        #expect(prompt.content.components(separatedBy: "\n").count == 1000)
    }
    
    
    @Test("Prompt creation with @PromptBuilder initializer")
    func promptBuilderInitializer() {
        let prompt1 = Prompt {
            "Hello, world!"
        }
        #expect(prompt1.content == "Hello, world!")
        
        let prompt2 = Prompt {
            "Line 1"
            "Line 2"
            "Line 3"
        }
        #expect(prompt2.content.contains("Line 1"))
        #expect(prompt2.content.contains("Line 2"))
        #expect(prompt2.content.contains("Line 3"))
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
        
        #expect(prompt.content.contains("Answer the following question"))
        #expect(prompt.content.contains("What is Swift?"))
        #expect(prompt.content.contains("Your response MUST rhyme!"))
        
        let shouldBeVerbose = false
        let prompt2 = Prompt {
            "Explain quantum physics"
            if shouldBeVerbose {
                "Provide extensive details and examples"
            }
        }
        
        #expect(prompt2.content.contains("Explain quantum physics"))
        #expect(!prompt2.content.contains("Provide extensive details"))
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
        
        #expect(prompt.content.contains("List the following fruits:"))
        #expect(prompt.content.contains("- apple"))
        #expect(prompt.content.contains("- banana"))
        #expect(prompt.content.contains("- orange"))
        #expect(prompt.content.contains("End of list"))
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
        
        #expect(prompt.content.contains("This is a string"))
        #expect(prompt.content.contains("Generated content"))
        #expect(prompt.content.contains("Final line"))
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
        
        #expect(prompt.content.contains("Outer content"))
        #expect(prompt.content.contains("Nested content"))
        #expect(prompt.content.contains("More nested content"))
        #expect(prompt.content.contains("After nested"))
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
        
        #expect(prompt.content.contains("Start"))
        #expect(prompt.content.contains("Optional text"))
        #expect(prompt.content.contains("End"))
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
        
        #expect(prompt.content.contains("Answer this question:"))
        #expect(prompt.content.contains("Use technical terminology"))
        #expect(!prompt.content.contains("formal language"))
        #expect(!prompt.content.contains("casual"))
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
        
        #expect(prompt.content.contains("Create a tutorial"))
        #expect(prompt.content.contains("1. Swift"))
        #expect(prompt.content.contains("2. Objective-C"))
        #expect(prompt.content.contains("3. SwiftUI"))
        #expect(prompt.content.contains("Include examples"))
        #expect(prompt.content.contains("Maximum 3 examples"))
        #expect(prompt.content.contains("Format as markdown"))
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
        
        #expect(prompt.content.contains("Swift function"))
        #expect(prompt.content.contains("two integers"))
        #expect(prompt.content.contains("documentation"))
        #expect(prompt.content.contains("error handling"))
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
        
        #expect(prompt.content.contains("dataset characteristics"))
        #expect(prompt.content.contains("10,000 active users"))
        #expect(prompt.content.contains("Mobile (60%)"))
        #expect(prompt.content.contains("Optimization recommendations"))
    }
}