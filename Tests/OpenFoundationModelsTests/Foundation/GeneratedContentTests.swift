// GeneratedContentTests.swift
// OpenFoundationModelsTests
//
// ✅ APPLE OFFICIAL: Tests for Apple Foundation Models GeneratedContent system

import Foundation
import Testing
@testable import OpenFoundationModels

/// Tests for GeneratedContent structure and functionality
/// 
/// **Focus:** Validates GeneratedContent creation, manipulation, and protocol conformance
/// according to Apple's Foundation Models specification.
///
/// **Apple Foundation Models Documentation:**
/// GeneratedContent represents the output from language model responses.
/// It serves as the bridge between raw model output and structured Swift types.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/generatedcontent
@Suite("Generated Content Tests", .tags(.foundation))
struct GeneratedContentTests {
    
    // MARK: - Basic GeneratedContent Tests
    
    @Test("GeneratedContent creation with string")
    func generatedContentStringCreation() {
        let content = GeneratedContent("Hello, world!")
        
        #expect(content.stringValue == "Hello, world!")
        #expect(content.text == "Hello, world!")
        #expect(!content.stringValue.isEmpty)
    }
    
    @Test("GeneratedContent creation with empty string")
    func generatedContentEmptyCreation() {
        let content = GeneratedContent("")
        
        #expect(content.stringValue == "")
        #expect(content.text == "")
        #expect(content.stringValue.isEmpty)
    }
    
    @Test("GeneratedContent text property access")
    func generatedContentTextAccess() {
        let text = "Generated response content"
        let content = GeneratedContent(text)
        
        #expect(content.text == text)
        #expect(content.stringValue == text)
    }
    
    // MARK: - JSON Content Tests
    
    @Test("GeneratedContent with JSON string")
    func generatedContentJSON() throws {
        let jsonString = """
        {
            "name": "John Doe",
            "age": 30,
            "email": "john@example.com"
        }
        """
        
        let content = try GeneratedContent(json: jsonString)
        
        // JSON parsing converts to structured data, not raw string
        let properties = try content.properties()
        #expect(properties["name"]?.stringValue == "John Doe")
        #expect(properties["age"]?.stringValue == "30")
        #expect(properties["email"]?.stringValue == "john@example.com")
    }
    
    @Test("GeneratedContent with structured JSON data")
    func generatedContentStructuredJSON() throws {
        let jsonString = """
        {
            "title": "Sample Article",
            "wordCount": 500,
            "published": true,
            "tags": ["technology", "AI", "swift"]
        }
        """
        
        let content = try GeneratedContent(json: jsonString)
        
        let properties = try content.properties()
        #expect(properties["title"]?.stringValue == "Sample Article")
        #expect(properties["wordCount"]?.stringValue == "500")
        #expect(properties["published"]?.stringValue == "true")
        
        let tags = try properties["tags"]?.elements()
        #expect(tags?.count == 3)
        #expect(tags?[0].stringValue == "technology")
        #expect(tags?[1].stringValue == "AI")
        #expect(tags?[2].stringValue == "swift")
    }
    
    @Test("GeneratedContent with nested JSON structure")
    func generatedContentNestedJSON() throws {
        let nestedJSON = """
        {
            "user": {
                "profile": {
                    "name": "Alice",
                    "settings": {
                        "theme": "dark",
                        "notifications": true
                    }
                }
            }
        }
        """
        
        let content = try GeneratedContent(json: nestedJSON)
        
        let properties = try content.properties()
        let userContent = properties["user"]
        let userProperties = try userContent?.properties()
        let profileContent = userProperties?["profile"]
        let profileProperties = try profileContent?.properties()
        
        #expect(profileProperties?["name"]?.stringValue == "Alice")
        
        let settingsContent = profileProperties?["settings"]
        let settingsProperties = try settingsContent?.properties()
        #expect(settingsProperties?["theme"]?.stringValue == "dark")
        #expect(settingsProperties?["notifications"]?.stringValue == "true")
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test("GeneratedContent Generable conformance")
    func generatedContentGenerableConformance() {
        let _ = GeneratedContent("Test content")
        
        // Should conform to Generable protocol
        let schema = GeneratedContent.generationSchema
        #expect(schema.type == "object")
        #expect(schema.description?.contains("Generated content") == true)
    }
    
    @Test("GeneratedContent ConvertibleFromGeneratedContent")
    func generatedContentConvertibleFrom() throws {
        let originalContent = GeneratedContent("Original content")
        
        // Should be able to convert from itself
        let convertedContent = try GeneratedContent(originalContent)
        
        #expect(convertedContent.stringValue == originalContent.stringValue)
        #expect(convertedContent.text == originalContent.text)
    }
    
    @Test("GeneratedContent ConvertibleToGeneratedContent")
    func generatedContentConvertibleTo() {
        let content = GeneratedContent("Content to convert")
        
        // Should convert to itself
        let converted = content.generatedContent
        
        #expect(converted.stringValue == content.stringValue)
        #expect(converted.text == content.text)
    }
    
    @Test("GeneratedContent InstructionsRepresentable")
    func generatedContentInstructionsRepresentable() {
        let content = GeneratedContent("Instruction content")
        let instructions = content.instructionsRepresentation
        
        #expect(instructions.description == "Instruction content")
    }
    
    @Test("GeneratedContent PartiallyGenerated")
    func generatedContentPartiallyGenerated() {
        let content = GeneratedContent("Partial content")
        
        // PartiallyGenerated should be GeneratedContent itself
        let partial = content.toPartiallyGenerated()
        #expect(partial.stringValue == content.stringValue)
        
        let asPartial = content.asPartiallyGenerated()
        #expect(asPartial.stringValue == content.stringValue)
    }
    
    // MARK: - Content Manipulation Tests
    
    @Test("GeneratedContent with multiline content")
    func generatedContentMultiline() {
        let multilineContent = """
        Line 1: Introduction
        Line 2: Main content
        Line 3: Conclusion
        
        Additional paragraph with more details.
        """
        
        let content = GeneratedContent(multilineContent)
        
        #expect(content.stringValue == multilineContent)
        #expect(content.stringValue.contains("Line 1"))
        #expect(content.stringValue.contains("Line 3"))
        #expect(content.stringValue.contains("Additional paragraph"))
    }
    
    @Test("GeneratedContent with special characters")
    func generatedContentSpecialCharacters() {
        let specialContent = "Content with émojis 🚀, quotes \"hello\", and symbols: ©®™"
        let content = GeneratedContent(specialContent)
        
        #expect(content.stringValue == specialContent)
        #expect(content.stringValue.contains("🚀"))
        #expect(content.stringValue.contains("\"hello\""))
        #expect(content.stringValue.contains("©®™"))
    }
    
    @Test("GeneratedContent with Unicode characters")
    func generatedContentUnicode() {
        let unicodeContent = "多言語テスト: English, 日本語, العربية, русский, 中文"
        let content = GeneratedContent(unicodeContent)
        
        #expect(content.stringValue == unicodeContent)
        #expect(content.stringValue.contains("日本語"))
        #expect(content.stringValue.contains("العربية"))
        #expect(content.stringValue.contains("русский"))
        #expect(content.stringValue.contains("中文"))
    }
    
    // MARK: - Edge Cases and Validation
    
    @Test("GeneratedContent with very long content")
    func generatedContentLongContent() {
        let longContent = String(repeating: "A", count: 10000)
        let content = GeneratedContent(longContent)
        
        #expect(content.stringValue.count == 10000)
        #expect(content.stringValue.allSatisfy { $0 == "A" })
        #expect(content.text.count == 10000)
    }
    
    @Test("GeneratedContent with whitespace only")
    func generatedContentWhitespaceOnly() {
        let whitespaceContent = "   \n\t   \n   "
        let content = GeneratedContent(whitespaceContent)
        
        #expect(content.stringValue == whitespaceContent)
        #expect(!content.stringValue.isEmpty)
        #expect(content.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    @Test("GeneratedContent with null characters")
    func generatedContentNullCharacters() {
        let contentWithNull = "Content\u{0000}with\u{0000}null"
        let content = GeneratedContent(contentWithNull)
        
        #expect(content.stringValue == contentWithNull)
        #expect(content.stringValue.contains("\u{0000}"))
    }
    
    // MARK: - Complex Data Tests
    
    @Test("GeneratedContent representing complex objects")
    func generatedContentComplexObjects() {
        let complexObject = """
        {
            "users": [
                {
                    "id": 1,
                    "name": "Alice",
                    "preferences": {
                        "theme": "dark",
                        "language": "en",
                        "notifications": {
                            "email": true,
                            "push": false
                        }
                    }
                },
                {
                    "id": 2,
                    "name": "Bob",
                    "preferences": {
                        "theme": "light",
                        "language": "es",
                        "notifications": {
                            "email": false,
                            "push": true
                        }
                    }
                }
            ],
            "metadata": {
                "version": "1.0",
                "timestamp": "2024-01-01T00:00:00Z"
            }
        }
        """
        
        let content = GeneratedContent(complexObject)
        
        // Test that the content was parsed correctly and contains expected elements
        #expect(content.stringValue.contains("Alice"))
        #expect(content.stringValue.contains("Bob"))
        #expect(content.stringValue.contains("notifications"))
        #expect(content.stringValue.contains("metadata"))
        
        // Verify JSON structure is preserved (though formatting may differ)
        #expect(content.stringValue.contains("users"))
        #expect(content.stringValue.contains("preferences"))
        #expect(content.stringValue.contains("theme"))
        #expect(content.stringValue.contains("language"))
    }
    
    @Test("GeneratedContent representing code")
    func generatedContentCode() {
        let swiftCode = """
        struct User {
            let id: Int
            let name: String
            let email: String
            
            func isValid() -> Bool {
                return !name.isEmpty && email.contains("@")
            }
        }
        
        extension User: Codable {
            // Auto-synthesized conformance
        }
        """
        
        let content = GeneratedContent(swiftCode)
        
        #expect(content.stringValue == swiftCode)
        #expect(content.stringValue.contains("struct User"))
        #expect(content.stringValue.contains("func isValid()"))
        #expect(content.stringValue.contains("extension User: Codable"))
    }
    
    // MARK: - Performance Tests
    
    @Test("GeneratedContent creation performance", .timeLimit(.minutes(1)))
    func generatedContentCreationPerformance() {
        let content = "Performance test content"
        
        for _ in 0..<1000 {
            let generated = GeneratedContent(content)
            #expect(generated.stringValue == content)
        }
    }
    
    @Test("GeneratedContent large JSON performance", .timeLimit(.minutes(1)))
    func generatedContentLargeJSONPerformance() throws {
        let largeJSON = "[" + (1...1000).map { "{\"key\($0)\": \"value\($0)\"}" }.joined(separator: ",") + "]"
        
        let content = try GeneratedContent(json: largeJSON)
        
        let elements = try content.elements()
        #expect(elements.count == 1000)
        
        // Check first element
        let firstElement = try elements[0].properties()
        #expect(firstElement["key1"]?.stringValue == "value1")
    }
    
    // MARK: - Integration Tests
    
    @Test("GeneratedContent Sendable conformance")
    func generatedContentSendableConformance() {
        let content = GeneratedContent("Sendable test")
        
        // Should conform to Sendable
        let _ = content as Sendable
        
        // Should be safe to use across concurrency boundaries
        Task {
            let asyncContent = content
            #expect(asyncContent.stringValue == "Sendable test")
        }
    }
}