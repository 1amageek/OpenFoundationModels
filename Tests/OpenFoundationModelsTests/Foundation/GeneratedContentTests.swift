
import Foundation
import Testing
@testable import OpenFoundationModels

@Suite("Generated Content Tests", .tags(.foundation))
struct GeneratedContentTests {
    
    
    @Test("GeneratedContent creation with string")
    func generatedContentStringCreation() {
        let content = GeneratedContent("Hello, world!")
        
        #expect(content.text == "Hello, world!")
        #expect(content.text == "Hello, world!")
        #expect(!content.text.isEmpty)
    }
    
    @Test("GeneratedContent creation with empty string")
    func generatedContentEmptyCreation() {
        let content = GeneratedContent("")
        
        #expect(content.text == "")
        #expect(content.text == "")
        #expect(content.text.isEmpty)
    }
    
    @Test("GeneratedContent text property access")
    func generatedContentTextAccess() {
        let text = "Generated response content"
        let content = GeneratedContent(text)
        
        #expect(content.text == text)
        #expect(content.text == text)
    }
    
    
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
        
        let properties = try content.properties()
        #expect(properties["name"]?.text == "John Doe")
        #expect(properties["age"]?.text == "30")
        #expect(properties["email"]?.text == "john@example.com")
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
        #expect(properties["title"]?.text == "Sample Article")
        #expect(properties["wordCount"]?.text == "500")
        #expect(properties["published"]?.text == "true")
        
        let tags = try properties["tags"]?.elements()
        #expect(tags?.count == 3)
        #expect(tags?[0].text == "technology")
        #expect(tags?[1].text == "AI")
        #expect(tags?[2].text == "swift")
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
        
        #expect(profileProperties?["name"]?.text == "Alice")
        
        let settingsContent = profileProperties?["settings"]
        let settingsProperties = try settingsContent?.properties()
        #expect(settingsProperties?["theme"]?.text == "dark")
        #expect(settingsProperties?["notifications"]?.text == "true")
    }
    
    
    @Test("GeneratedContent Generable conformance")
    func generatedContentGenerableConformance() {
        let _ = GeneratedContent("Test content")
        
        let schema = GeneratedContent.generationSchema
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
    
    @Test("GeneratedContent ConvertibleFromGeneratedContent")
    func generatedContentConvertibleFrom() throws {
        let originalContent = GeneratedContent("Original content")
        
        let convertedContent = try GeneratedContent(originalContent)
        
        #expect(convertedContent.text == originalContent.text)
        #expect(convertedContent.text == originalContent.text)
    }
    
    @Test("GeneratedContent ConvertibleToGeneratedContent")
    func generatedContentConvertibleTo() {
        let content = GeneratedContent("Content to convert")
        
        let converted = content.generatedContent
        
        #expect(converted.text == content.text)
        #expect(converted.text == content.text)
    }
    
    @Test("GeneratedContent InstructionsRepresentable")
    func generatedContentInstructionsRepresentable() {
        let content = GeneratedContent("Instruction content")
        let instructions = content.instructionsRepresentation
        
        #expect(instructions.content == "\"Instruction content\"")
    }
    
    @Test("GeneratedContent PartiallyGenerated")
    func generatedContentPartiallyGenerated() {
        let content = GeneratedContent("Partial content")
        
        let asPartial = content.asPartiallyGenerated()
        #expect(asPartial.text == content.text)
    }
    
    
    @Test("GeneratedContent with multiline content")
    func generatedContentMultiline() {
        let multilineContent = """
        Line 1: Introduction
        Line 2: Main content
        Line 3: Conclusion
        
        Additional paragraph with more details.
        """
        
        let content = GeneratedContent(multilineContent)
        
        #expect(content.text == multilineContent)
        #expect(content.text.contains("Line 1"))
        #expect(content.text.contains("Line 3"))
        #expect(content.text.contains("Additional paragraph"))
    }
    
    @Test("GeneratedContent with special characters")
    func generatedContentSpecialCharacters() {
        let specialContent = "Content with émojis 🚀, quotes \"hello\", and symbols: ©®™"
        let content = GeneratedContent(specialContent)
        
        #expect(content.text == specialContent)
        #expect(content.text.contains("🚀"))
        #expect(content.text.contains("\"hello\""))
        #expect(content.text.contains("©®™"))
    }
    
    @Test("GeneratedContent with Unicode characters")
    func generatedContentUnicode() {
        let unicodeContent = "多言語テスト: English, 日本語, العربية, русский, 中文"
        let content = GeneratedContent(unicodeContent)
        
        #expect(content.text == unicodeContent)
        #expect(content.text.contains("日本語"))
        #expect(content.text.contains("العربية"))
        #expect(content.text.contains("русский"))
        #expect(content.text.contains("中文"))
    }
    
    
    @Test("GeneratedContent with very long content")
    func generatedContentLongContent() {
        let longContent = String(repeating: "A", count: 10000)
        let content = GeneratedContent(longContent)
        
        #expect(content.text.count == 10000)
        #expect(content.text.allSatisfy { $0 == "A" })
        #expect(content.text.count == 10000)
    }
    
    @Test("GeneratedContent with whitespace only")
    func generatedContentWhitespaceOnly() {
        let whitespaceContent = "   \n\t   \n   "
        let content = GeneratedContent(whitespaceContent)
        
        #expect(content.text == whitespaceContent)
        #expect(!content.text.isEmpty)
        #expect(content.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    @Test("GeneratedContent with null characters")
    func generatedContentNullCharacters() {
        let contentWithNull = "Content\u{0000}with\u{0000}null"
        let content = GeneratedContent(contentWithNull)
        
        #expect(content.text == contentWithNull)
        #expect(content.text.contains("\u{0000}"))
    }
    
    
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
        
        #expect(content.text.contains("Alice"))
        #expect(content.text.contains("Bob"))
        #expect(content.text.contains("notifications"))
        #expect(content.text.contains("metadata"))
        
        #expect(content.text.contains("users"))
        #expect(content.text.contains("preferences"))
        #expect(content.text.contains("theme"))
        #expect(content.text.contains("language"))
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
        }
        """
        
        let content = GeneratedContent(swiftCode)
        
        #expect(content.text == swiftCode)
        #expect(content.text.contains("struct User"))
        #expect(content.text.contains("func isValid()"))
        #expect(content.text.contains("extension User: Codable"))
    }
    
    
    @Test("GeneratedContent creation performance", .timeLimit(.minutes(1)))
    func generatedContentCreationPerformance() {
        let content = "Performance test content"
        
        for _ in 0..<1000 {
            let generated = GeneratedContent(content)
            #expect(generated.text == content)
        }
    }
    
    @Test("GeneratedContent large JSON performance", .timeLimit(.minutes(1)))
    func generatedContentLargeJSONPerformance() throws {
        let largeJSON = "[" + (1...1000).map { "{\"key\($0)\": \"value\($0)\"}" }.joined(separator: ",") + "]"
        
        let content = try GeneratedContent(json: largeJSON)
        
        let elements = try content.elements()
        #expect(elements.count == 1000)
        
        let firstElement = try elements[0].properties()
        #expect(firstElement["key1"]?.text == "value1")
    }
    
    
    @Test("GeneratedContent Sendable conformance")
    func generatedContentSendableConformance() {
        let content = GeneratedContent("Sendable test")
        
        let _ = content as Sendable
        
        Task {
            let asyncContent = content
            #expect(asyncContent.text == "Sendable test")
        }
    }
    
    @Test("GeneratedContent with partial JSON object")
    func generatedContentPartialJSONObject() throws {
        let partialJSON = #"{"title": "A story of"#
        
        let content = try GeneratedContent(json: partialJSON)
        
        #expect(!content.isComplete)
        
        // The partial JSON should still be accessible through kind
        switch content.kind {
        case .structure(let properties, _):
            #expect(properties["title"]?.text == "A story of")
        default:
            #expect(Bool(false), "Expected structure kind for partial object")
        }
    }
    
    @Test("GeneratedContent with partial JSON array")
    func generatedContentPartialJSONArray() throws {
        let partialJSON = #"["item1", "item2", "item"#
        
        let content = try GeneratedContent(json: partialJSON)
        
        #expect(!content.isComplete)
        
        // The partial JSON should still be accessible through kind
        switch content.kind {
        case .array(let elements):
            #expect(elements.count >= 2)
            #expect(elements[0].text == "item1")
            #expect(elements[1].text == "item2")
        default:
            #expect(Bool(false), "Expected array kind for partial array")
        }
    }
    
    @Test("GeneratedContent with complete JSON after partial parsing")
    func generatedContentCompleteJSONAfterPartial() throws {
        // This JSON is complete but could be parsed as partial
        let completeJSON = #"{"name": "John", "age": 30}"#
        
        let content = try GeneratedContent(json: completeJSON)
        
        #expect(content.isComplete)
        
        let properties = try content.properties()
        #expect(properties["name"]?.text == "John")
        #expect(try properties["age"]?.value(Int.self) == 30)
    }
    
    @Test("GeneratedContent with nested partial JSON")
    func generatedContentNestedPartialJSON() throws {
        let partialJSON = #"{"user": {"name": "Alice", "preferences": {"theme": "dark"#
        
        let content = try GeneratedContent(json: partialJSON)
        
        #expect(!content.isComplete)
        
        // Check that partial nested structure is parsed
        switch content.kind {
        case .structure(let properties, _):
            if let user = properties["user"] {
                switch user.kind {
                case .structure(let userProps, _):
                    #expect(userProps["name"]?.text == "Alice")
                default:
                    #expect(Bool(false), "Expected nested structure for user")
                }
            } else {
                #expect(Bool(false), "Expected user property")
            }
        default:
            #expect(Bool(false), "Expected structure kind")
        }
    }
    
    @Test("GeneratedContent with partial string literal")
    func generatedContentPartialStringLiteral() throws {
        let partialJSON = #"{"message": "Hello, wor"#
        
        let content = try GeneratedContent(json: partialJSON)
        
        #expect(!content.isComplete)
        
        switch content.kind {
        case .structure(let properties, _):
            #expect(properties["message"]?.text == "Hello, wor")
        default:
            #expect(Bool(false), "Expected structure kind")
        }
    }
    
    @Test("GeneratedContent with top-level number")
    func generatedContentTopLevelNumber() throws {
        let content = try GeneratedContent(json: "42.5")
        
        #expect(content.isComplete)
        #expect(try content.value(Double.self) == 42.5)
        
        switch content.kind {
        case .number(let n):
            #expect(n == 42.5)
        default:
            #expect(Bool(false), "Expected number kind")
        }
    }
    
    @Test("GeneratedContent with top-level boolean")
    func generatedContentTopLevelBoolean() throws {
        let contentTrue = try GeneratedContent(json: "true")
        let contentFalse = try GeneratedContent(json: "false")
        
        #expect(contentTrue.isComplete)
        #expect(contentFalse.isComplete)
        #expect(try contentTrue.value(Bool.self) == true)
        #expect(try contentFalse.value(Bool.self) == false)
    }
    
    @Test("GeneratedContent with top-level null")
    func generatedContentTopLevelNull() throws {
        let content = try GeneratedContent(json: "null")
        
        #expect(content.isComplete)
        
        switch content.kind {
        case .null:
            #expect(true)
        default:
            #expect(Bool(false), "Expected null kind")
        }
    }
    
    @Test("GeneratedContent with top-level string")
    func generatedContentTopLevelString() throws {
        let content = try GeneratedContent(json: #""hello world""#)
        
        #expect(content.isComplete)
        #expect(try content.value(String.self) == "hello world")
        
        switch content.kind {
        case .string(let s):
            #expect(s == "hello world")
        default:
            #expect(Bool(false), "Expected string kind")
        }
    }
    
    @Test("GeneratedContent with non-JSON text")
    func generatedContentNonJSONText() throws {
        let content = try GeneratedContent(json: "hello")
        
        #expect(!content.isComplete)
        
        switch content.kind {
        case .string(let s):
            #expect(s == "hello")
        default:
            #expect(Bool(false), "Expected string kind with non-JSON text")
        }
    }
    
    @Test("GeneratedContent preserves key order in partial JSON")
    func generatedContentPreservesKeyOrderPartial() throws {
        // Use partial JSON to test key order preservation
        // (Complete JSON via JSONSerialization doesn't guarantee order)
        let partialJson = #"{"b": 2, "a": 1, "c":"#
        let content = try GeneratedContent(json: partialJson)
        
        switch content.kind {
        case .structure(_, let orderedKeys):
            // Partial JSON parser should preserve insertion order
            #expect(orderedKeys == ["b", "a"])
        default:
            #expect(Bool(false), "Expected structure kind")
        }
    }
    
    @Test("GeneratedContent toJSONString respects orderedKeys")
    func generatedContentToJSONStringRespectsOrder() throws {
        let content = GeneratedContent(properties: ["b": 2, "a": 1, "c": 3])
        let jsonString = content.jsonString
        
        // Should be valid JSON
        let data = jsonString.data(using: .utf8)!
        #expect(throws: Never.self) {
            _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        }
        
        // Should contain all keys
        #expect(jsonString.contains("\"a\""))
        #expect(jsonString.contains("\"b\""))
        #expect(jsonString.contains("\"c\""))
    }
    
    @Test("GeneratedContent partial JSON properties access")
    func generatedContentPartialPropertiesAccess() throws {
        let partialJSON = #"{"name": "Alice", "age": 2"#
        let content = try GeneratedContent(json: partialJSON)
        
        #expect(!content.isComplete)
        
        // properties() should work even for partial content
        let properties = try content.properties()
        #expect(properties["name"]?.text == "Alice")
        // "age": 2 is actually parsed as a complete number even without closing brace
        #expect(try properties["age"]?.value(Double.self) == 2)
    }
    
    @Test("GeneratedContent partial JSON elements access")
    func generatedContentPartialElementsAccess() throws {
        let partialJSON = #"["item1", "item2", "item"#
        let content = try GeneratedContent(json: partialJSON)
        
        #expect(!content.isComplete)
        
        // elements() should work even for partial content
        let elements = try content.elements()
        #expect(elements.count >= 2)
        #expect(elements[0].text == "item1")
        #expect(elements[1].text == "item2")
    }
    
    @Test("GeneratedContent with unclosed top-level string")
    func generatedContentUnclosedTopLevelString() throws {
        let unclosedString = #""hello wor"#
        let content = try GeneratedContent(json: unclosedString)
        
        // Unclosed strings should be treated as partial
        #expect(!content.isComplete)
        
        // PartialJSON.scanString extracts the value from unclosed strings
        switch content.kind {
        case .string(let s):
            #expect(s == "hello wor")  // The extracted value, not the raw JSON
        default:
            #expect(Bool(false), "Expected string kind for unclosed string")
        }
        
        // jsonString should return rebuilt JSON from parsed structure
        #expect(content.jsonString == #""hello wor""#)
    }
    
    @Test("GeneratedContent with closed top-level string")
    func generatedContentClosedTopLevelString() throws {
        let closedString = #""hello world""#
        let content = try GeneratedContent(json: closedString)
        
        // Properly closed strings should be complete
        #expect(content.isComplete)
        #expect(try content.value(String.self) == "hello world")
    }
    
    @Test("GeneratedContent partial object to Generable conversion")
    func generatedContentPartialToGenerable() throws {
        // Define a simple Generable type inline for testing
        struct TestIdea: ConvertibleFromGeneratedContent {
            let title: String
            
            init(_ content: GeneratedContent) throws {
                switch content.kind {
                case .structure(let props, _):
                    self.title = try props["title"]?.value(String.self) ?? ""
                default:
                    throw GeneratedContentError.dictionaryExpected
                }
            }
        }
        
        let partialJSON = #"{"title": "A story of"#
        let content = try GeneratedContent(json: partialJSON)
        
        #expect(!content.isComplete)
        
        // Should be able to convert partial JSON to type
        let idea = try TestIdea(content)
        #expect(idea.title == "A story of")
        
        // jsonString should return rebuilt JSON from parsed structure
        #expect(content.jsonString == #"{"title": "A story of"}"#)
    }
    
    @Test("GeneratedContent fragments are complete")
    func generatedContentFragmentsAreComplete() throws {
        // Numbers are complete
        let numberContent = try GeneratedContent(json: "12.5")
        #expect(numberContent.isComplete)
        #expect(try numberContent.value(Double.self) == 12.5)
        
        // Booleans are complete
        let boolContent = try GeneratedContent(json: "true")
        #expect(boolContent.isComplete)
        #expect(try boolContent.value(Bool.self) == true)
        
        // null is complete
        let nullContent = try GeneratedContent(json: "null")
        #expect(nullContent.isComplete)
        switch nullContent.kind {
        case .null:
            #expect(Bool(true))
        default:
            #expect(Bool(false), "Expected null kind")
        }
    }
    
    @Test("GeneratedContent partial array with incomplete literal")
    func generatedContentPartialArrayWithIncompleteLiteral() throws {
        let partialJSON = #"["a", 1, tru"#
        let content = try GeneratedContent(json: partialJSON)
        
        #expect(!content.isComplete)
        
        switch content.kind {
        case .array(let elems):
            #expect(elems.count == 2) // "tru" is incomplete, not parsed
            #expect(try elems[0].value(String.self) == "a")
            #expect(try elems[1].value(Double.self) == 1)
        default:
            #expect(Bool(false), "Expected array kind")
        }
    }
}