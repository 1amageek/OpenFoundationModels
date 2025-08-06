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
        
        #expect(!prompt.description.isEmpty)
        #expect(prompt.description == "What is the weather like today?")
    }
    
    @Test("Prompt creation with empty string")
    func promptEmptyCreation() {
        let prompt = Prompt("")
        
        #expect(prompt.description.isEmpty)
        #expect(prompt.description == "")
    }
    
    @Test("Prompt text property access")
    func promptTextAccess() {
        let text = "Generate a detailed user profile"
        let prompt = Prompt(text)
        
        #expect(prompt.description == text)
    }
    
    // MARK: - PromptRepresentable Tests
    
    @Test("String conforms to PromptRepresentable")
    func stringPromptRepresentable() {
        let text = "Test prompt"
        let prompt = text.promptRepresentation
        
        #expect(prompt.description == text)
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
        
        #expect(prompt.description == complexQuery)
        #expect(prompt.description.contains("JSON structure"))
        #expect(prompt.description.contains("requirements:"))
        #expect(prompt.description.contains("proper JSON formatting"))
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
        
        #expect(prompt.description.contains("TASK:"))
        #expect(prompt.description.contains("INPUT:"))
        #expect(prompt.description.contains("OUTPUT FORMAT:"))
        #expect(prompt.description.contains("Tokyo, Japan"))
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
        
        #expect(prompt.description.contains("```swift"))
        #expect(prompt.description.contains("struct User"))
        #expect(prompt.description.contains("Swift syntax"))
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
        
        #expect(prompt.description.contains("# Task Description"))
        #expect(prompt.description.contains("**detailed**"))
        #expect(prompt.description.contains("*Item 1*"))
        #expect(prompt.description.contains("## Output Requirements"))
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
        
        #expect(prompt.description.contains("Hello, how are you?"))
        #expect(prompt.description.contains("¿cómo estás?"))
        #expect(prompt.description.contains("comment allez-vous?"))
        #expect(prompt.description.contains("こんにちは"))
        #expect(prompt.description.contains("مرحبا"))
        #expect(prompt.description.contains("Привет"))
        #expect(prompt.description.contains("你好"))
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
        
        #expect(prompt.description.contains("🌟"))
        #expect(prompt.description.contains("🚀"))
        #expect(prompt.description.contains("💡"))
        #expect(prompt.description.contains("©"))
        #expect(prompt.description.contains("∑"))
        #expect(prompt.description.contains("π"))
    }
    
    // MARK: - Edge Cases and Validation
    
    @Test("Prompt with very long content")
    func promptLongContent() {
        let longContent = String(repeating: "This is a test sentence. ", count: 100)
        let prompt = Prompt(longContent)
        
        #expect(prompt.description.count > 2000)
        #expect(prompt.description.hasPrefix("This is a test sentence."))
        #expect(prompt.description.hasSuffix("This is a test sentence. "))
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
        
        #expect(prompt.description.contains("various whitespace"))
        #expect(prompt.description.contains("Leading spaces"))
        #expect(prompt.description.contains("Tabs and spaces"))
        #expect(prompt.description.hasPrefix("\n\n"))
        #expect(prompt.description.hasSuffix("\n\n"))
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
        
        #expect(prompt.description.contains("\"double\""))
        #expect(prompt.description.contains("'single'"))
        #expect(prompt.description.contains("\\"))
        #expect(prompt.description.contains("\\u0041"))
    }
    
    // MARK: - Performance Tests
    
    @Test("Prompt creation performance", .timeLimit(.minutes(1)))
    func promptCreationPerformance() {
        let content = "Performance test prompt with moderate length content for benchmarking"
        
        for _ in 0..<1000 {
            let prompt = Prompt(content)
            #expect(prompt.description == content)
        }
    }
    
    @Test("Large prompt handling", .timeLimit(.minutes(1)))
    func largePromptHandling() {
        let largeContent = (1...1000).map { "Line \($0): This is a test line with some content." }.joined(separator: "\n")
        
        let prompt = Prompt(largeContent)
        
        #expect(prompt.description.contains("Line 1:"))
        #expect(prompt.description.contains("Line 1000:"))
        #expect(prompt.description.components(separatedBy: "\n").count == 1000)
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
        
        #expect(prompt.description.contains("Swift function"))
        #expect(prompt.description.contains("two integers"))
        #expect(prompt.description.contains("documentation"))
        #expect(prompt.description.contains("error handling"))
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
        
        #expect(prompt.description.contains("dataset characteristics"))
        #expect(prompt.description.contains("10,000 active users"))
        #expect(prompt.description.contains("Mobile (60%)"))
        #expect(prompt.description.contains("Optimization recommendations"))
    }
}