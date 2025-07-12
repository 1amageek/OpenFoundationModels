// PromptTests.swift
// OpenFoundationModelsTests
//
// ✅ APPLE OFFICIAL: Tests for Apple Foundation Models Prompt system

import Foundation
import Testing
@testable import OpenFoundationModels

/// Tests for Prompt structure and functionality
/// 
/// **Focus:** Validates Prompt structure and PromptRepresentable protocol
/// according to Apple's Foundation Models specification.
///
/// **Apple Foundation Models Documentation:**
/// Prompts represent user input and queries to language models.
/// They serve as the primary interface for requesting model responses.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/prompt
@Suite("Prompt Tests", .tags(.foundation))
struct PromptTests {
    
    // MARK: - Basic Prompt Tests
    
    @Test("Prompt creation with string")
    func promptStringCreation() {
        let prompt = Prompt("What is the weather like today?")
        
        #expect(!prompt.text.isEmpty)
        #expect(prompt.text == "What is the weather like today?")
    }
    
    @Test("Prompt creation with empty string")
    func promptEmptyCreation() {
        let prompt = Prompt("")
        
        #expect(prompt.text.isEmpty)
        #expect(prompt.text == "")
    }
    
    @Test("Prompt text property access")
    func promptTextAccess() {
        let text = "Generate a detailed user profile"
        let prompt = Prompt(text)
        
        #expect(prompt.text == text)
    }
    
    // MARK: - PromptRepresentable Tests
    
    @Test("String conforms to PromptRepresentable")
    func stringPromptRepresentable() {
        let text = "Test prompt"
        let prompt = text.promptRepresentation
        
        #expect(prompt.text == text)
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
        
        #expect(prompt.text == complexQuery)
        #expect(prompt.text.contains("JSON structure"))
        #expect(prompt.text.contains("requirements:"))
        #expect(prompt.text.contains("proper JSON formatting"))
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
        
        #expect(prompt.text.contains("TASK:"))
        #expect(prompt.text.contains("INPUT:"))
        #expect(prompt.text.contains("OUTPUT FORMAT:"))
        #expect(prompt.text.contains("Tokyo, Japan"))
    }
    
    // MARK: - Prompt Content Validation
    
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
        
        #expect(prompt.text.contains("```swift"))
        #expect(prompt.text.contains("struct User"))
        #expect(prompt.text.contains("Swift syntax"))
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
        
        #expect(prompt.text.contains("# Task Description"))
        #expect(prompt.text.contains("**detailed**"))
        #expect(prompt.text.contains("*Item 1*"))
        #expect(prompt.text.contains("## Output Requirements"))
    }
    
    // MARK: - International Content Tests
    
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
        
        #expect(prompt.text.contains("Hello, how are you?"))
        #expect(prompt.text.contains("¿cómo estás?"))
        #expect(prompt.text.contains("comment allez-vous?"))
        #expect(prompt.text.contains("こんにちは"))
        #expect(prompt.text.contains("مرحبا"))
        #expect(prompt.text.contains("Привет"))
        #expect(prompt.text.contains("你好"))
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
        
        #expect(prompt.text.contains("🌟"))
        #expect(prompt.text.contains("🚀"))
        #expect(prompt.text.contains("💡"))
        #expect(prompt.text.contains("©"))
        #expect(prompt.text.contains("∑"))
        #expect(prompt.text.contains("π"))
    }
    
    // MARK: - Edge Cases and Validation
    
    @Test("Prompt with very long content")
    func promptLongContent() {
        let longContent = String(repeating: "This is a test sentence. ", count: 100)
        let prompt = Prompt(longContent)
        
        #expect(prompt.text.count > 2000)
        #expect(prompt.text.hasPrefix("This is a test sentence."))
        #expect(prompt.text.hasSuffix("This is a test sentence. "))
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
        
        #expect(prompt.text.contains("various whitespace"))
        #expect(prompt.text.contains("Leading spaces"))
        #expect(prompt.text.contains("Tabs and spaces"))
        #expect(prompt.text.hasPrefix("\n\n"))
        #expect(prompt.text.hasSuffix("\n\n"))
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
        
        #expect(prompt.text.contains("\"double\""))
        #expect(prompt.text.contains("'single'"))
        #expect(prompt.text.contains("\\"))
        #expect(prompt.text.contains("\\u0041"))
    }
    
    // MARK: - Performance Tests
    
    @Test("Prompt creation performance", .timeLimit(.minutes(1)))
    func promptCreationPerformance() {
        let content = "Performance test prompt with moderate length content for benchmarking"
        
        for _ in 0..<1000 {
            let prompt = Prompt(content)
            #expect(prompt.text == content)
        }
    }
    
    @Test("Large prompt handling", .timeLimit(.minutes(1)))
    func largePromptHandling() {
        let largeContent = (1...1000).map { "Line \($0): This is a test line with some content." }.joined(separator: "\n")
        
        let prompt = Prompt(largeContent)
        
        #expect(prompt.text.contains("Line 1:"))
        #expect(prompt.text.contains("Line 1000:"))
        #expect(prompt.text.components(separatedBy: "\n").count == 1000)
    }
    
    // MARK: - Functional Tests
    
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
        
        #expect(prompt.text.contains("Swift function"))
        #expect(prompt.text.contains("two integers"))
        #expect(prompt.text.contains("documentation"))
        #expect(prompt.text.contains("error handling"))
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
        
        #expect(prompt.text.contains("dataset characteristics"))
        #expect(prompt.text.contains("10,000 active users"))
        #expect(prompt.text.contains("Mobile (60%)"))
        #expect(prompt.text.contains("Optimization recommendations"))
    }
}