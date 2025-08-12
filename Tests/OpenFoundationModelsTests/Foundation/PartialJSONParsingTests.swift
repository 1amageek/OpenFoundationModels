// PartialJSONParsingTests.swift
// OpenFoundationModelsTests
//
// Comprehensive tests for partial JSON parsing functionality
// Based on PARTIAL_JSON_PARSING_SPEC.md

import Foundation
import Testing
@testable import OpenFoundationModels

/// Tests for partial JSON parsing functionality
/// 
/// **Focus:** Validates the ability to parse incomplete JSON during streaming,
/// extracting available properties while tracking completeness status.
///
/// **Reference:** PARTIAL_JSON_PARSING_SPEC.md
@Suite("Partial JSON Parsing Tests", .tags(.foundation, .streaming))
struct PartialJSONParsingTests {
    
    // Helper function to ensure we use the correct initializer
    private func parseJSON(_ json: String) throws -> GeneratedContent {
        return try GeneratedContent(json: json)
    }
    
    // MARK: - Section 1: Basic Partial JSON Tests
    
    @Test("Empty object parsing")
    func emptyObjectParsing() throws {
        let json = "{}"
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        #expect(properties.isEmpty)
    }
    
    @Test("Incomplete empty object")
    func incompleteEmptyObject() throws {
        let json = "{"
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        // Should handle partial JSON gracefully
        do {
            _ = try content.properties()
        } catch {
            // Expected to fail or return empty
            // Error is already non-nil in catch block
        }
    }
    
    @Test("Key only - no colon")
    func keyOnlyNoColon() throws {
        let json = #"{"name"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        // No complete properties should be extracted
        if let properties = try? content.properties() {
            #expect(properties.isEmpty || properties["name"] == nil)
        }
    }
    
    @Test("Key with colon - no value")
    func keyWithColonNoValue() throws {
        let json = #"{"name":"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        // No complete properties should be extracted
        if let properties = try? content.properties() {
            #expect(properties["name"] == nil)
        }
    }
    
    @Test("Incomplete string value")
    func incompleteStringValue() throws {
        let json = #"{"name": "Al"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        // Partial value might be extracted depending on implementation
        if let properties = try? content.properties() {
            // Implementation may choose to extract "Al" or skip incomplete values
            let name = properties["name"]
            if name != nil {
                #expect(name?.text == "Al")
            }
        }
    }
    
    @Test("Complete property without closing brace")
    func completePropertyWithoutClosingBrace() throws {
        let json = #"{"name": "Alice""#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        // Property should be extractable even without closing brace
        if let properties = try? content.properties() {
            #expect(properties["name"]?.text == "Alice")
        }
    }
    
    @Test("Complete single property")
    func completeSingleProperty() throws {
        let json = #"{"name": "Alice"}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        #expect(properties["name"]?.text == "Alice")
    }
    
    // MARK: - Section 2: Multiple Properties Tests
    
    @Test("Two properties - second key only")
    func twoPropertiesSecondKeyOnly() throws {
        let json = #"{"name": "Alice", "age"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        if let properties = try? content.properties() {
            #expect(properties["name"]?.text == "Alice")
            #expect(properties["age"] == nil)
        }
    }
    
    @Test("Two properties - second with colon")
    func twoPropertiesSecondWithColon() throws {
        let json = #"{"name": "Alice", "age":"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        if let properties = try? content.properties() {
            #expect(properties["name"]?.text == "Alice")
            #expect(properties["age"] == nil)
        }
    }
    
    @Test("Two properties - second incomplete")
    func twoPropertiesSecondIncomplete() throws {
        let json = #"{"name": "Alice", "age": 2"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        if let properties = try? content.properties() {
            #expect(properties["name"]?.text == "Alice")
            // Partial number might be extracted
            if let age = properties["age"] {
                #expect(age.text == "2")
            }
        }
    }
    
    @Test("Two complete properties without closing brace")
    func twoCompletePropertiesWithoutClosingBrace() throws {
        let json = #"{"name": "Alice", "age": 25"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        if let properties = try? content.properties() {
            #expect(properties["name"]?.text == "Alice")
            #expect(properties["age"]?.text == "25")
        }
    }
    
    @Test("Two complete properties")
    func twoCompleteProperties() throws {
        let json = #"{"name": "Alice", "age": 25}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        #expect(properties["name"]?.text == "Alice")
        #expect(properties["age"]?.text == "25")
    }
    
    // MARK: - Section 3: Value Types Tests
    
    @Test("String value parsing")
    func stringValueParsing() throws {
        let testCases = [
            (#"{"text": "hello"}"#, "hello", true),
            (#"{"text": "hello"#, "hello", false),
            (#"{"text": "hel"#, "hel", false),
            (#"{"text": ""#, "", false),
            (#"{"text":"#, nil, false)
        ]
        
        for (json, expectedValue, expectedComplete) in testCases {
            let content = try parseJSON(json)
            #expect(content.isComplete == expectedComplete)
            
            if let properties = try? content.properties(),
               let value = expectedValue {
                #expect(properties["text"]?.text == value)
            }
        }
    }
    
    @Test("Number value parsing")
    func numberValueParsing() throws {
        let testCases = [
            (#"{"num": 123}"#, "123", true),
            (#"{"num": 123"#, "123", false),
            (#"{"num": 12"#, "12", false),
            (#"{"num": 1"#, "1", false),
            (#"{"num": 123.45}"#, "123.45", true),
            (#"{"num": 123."#, "123", false),  // Partial number: decimal point without digits is rolled back
            (#"{"num": -42}"#, "-42", true),
            (#"{"num": -"#, nil, false)
        ]
        
        for (json, expectedValue, expectedComplete) in testCases {
            let content = try parseJSON(json)
            #expect(content.isComplete == expectedComplete)
            
            if let properties = try? content.properties(),
               let value = expectedValue {
                #expect(properties["num"]?.text == value)
            }
        }
    }
    
    @Test("Boolean value parsing")
    func booleanValueParsing() throws {
        let testCases = [
            (#"{"flag": true}"#, "true", true),
            (#"{"flag": false}"#, "false", true),
            (#"{"flag": true"#, "true", false),
            (#"{"flag": false"#, "false", false),
            (#"{"flag": tru"#, nil, false),
            (#"{"flag": fals"#, nil, false),
            (#"{"flag": t"#, nil, false)
        ]
        
        for (json, expectedValue, expectedComplete) in testCases {
            let content = try parseJSON(json)
            #expect(content.isComplete == expectedComplete)
            
            if let properties = try? content.properties(),
               let value = expectedValue {
                #expect(properties["flag"]?.text == value)
            }
        }
    }
    
    @Test("Null value parsing")
    func nullValueParsing() throws {
        let testCases = [
            (#"{"value": null}"#, true, true),
            (#"{"value": null"#, true, false),
            (#"{"value": nul"#, false, false),
            (#"{"value": nu"#, false, false),
            (#"{"value": n"#, false, false)
        ]
        
        for (json, hasNull, expectedComplete) in testCases {
            let content = try parseJSON(json)
            #expect(content.isComplete == expectedComplete)
            
            if let properties = try? content.properties() {
                if hasNull {
                    #expect(properties["value"] != nil)
                    // Check if it's null type
                    if case .null = properties["value"]?.kind {
                        // Success - it's null
                    } else {
                        Issue.record("Expected null kind")
                    }
                } else {
                    #expect(properties["value"] == nil)
                }
            }
        }
    }
    
    // MARK: - Section 4: Nested Structure Tests
    
    @Test("Nested object - incomplete")
    func nestedObjectIncomplete() throws {
        let testCases = [
            #"{"user": {"#,
            #"{"user": {"name"#,
            #"{"user": {"name":"#,
            #"{"user": {"name": "Bob"#,
            #"{"user": {"name": "Bob""#
        ]
        
        for json in testCases {
            let content = try parseJSON(json)
            #expect(content.isComplete == false)
            
            // Nested incomplete objects might not be extracted
            if let properties = try? content.properties() {
                // Implementation may choose to skip incomplete nested objects
                _ = properties["user"]
            }
        }
    }
    
    @Test("Nested object - complete inner, incomplete outer")
    func nestedObjectCompleteInnerIncompleteOuter() throws {
        let json = #"{"user": {"name": "Bob"}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        if let properties = try? content.properties(),
           let user = properties["user"] {
            // Nested object should be extractable
            if let userProps = try? user.properties() {
                #expect(userProps["name"]?.text == "Bob")
            }
        }
    }
    
    @Test("Nested object - complete")
    func nestedObjectComplete() throws {
        let json = #"{"user": {"name": "Bob", "age": 30}}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        
        let properties = try content.properties()
        let user = try properties["user"]?.properties()
        #expect(user?["name"]?.text == "Bob")
        #expect(user?["age"]?.text == "30")
    }
    
    @Test("Deeply nested structure")
    func deeplyNestedStructure() throws {
        let json = #"{"a": {"b": {"c": {"d": "deep"}}}}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        
        let a = try content.properties()["a"]?.properties()
        let b = try a?["b"]?.properties()
        let c = try b?["c"]?.properties()
        #expect(c?["d"]?.text == "deep")
    }
    
    // MARK: - Section 5: Array Tests
    
    @Test("Array - incomplete")
    func arrayIncomplete() throws {
        let testCases = [
            #"{"items": ["#,
            #"{"items": [1"#,
            #"{"items": [1,"#,
            #"{"items": [1, 2"#,
            #"{"items": [1, 2,"#
        ]
        
        for json in testCases {
            let content = try parseJSON(json)
            #expect(content.isComplete == false)
        }
    }
    
    @Test("Array - complete inner, incomplete outer")
    func arrayCompleteInnerIncompleteOuter() throws {
        let json = #"{"items": [1, 2, 3]"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == false)
        
        if let properties = try? content.properties(),
           let items = try? properties["items"]?.elements() {
            #expect(items.count == 3)
            #expect(items[0].text == "1")
            #expect(items[1].text == "2")
            #expect(items[2].text == "3")
        }
    }
    
    @Test("Array - complete")
    func arrayComplete() throws {
        let json = #"{"items": [1, 2, 3]}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        
        let properties = try content.properties()
        let items = try properties["items"]?.elements()
        #expect(items?.count == 3)
    }
    
    @Test("Array with mixed types")
    func arrayWithMixedTypes() throws {
        let json = #"{"mixed": [1, "text", true, null, {"nested": "value"}]}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        
        let properties = try content.properties()
        let mixed = try properties["mixed"]?.elements()
        #expect(mixed?.count == 5)
        #expect(mixed?[0].text == "1")
        #expect(mixed?[1].text == "text")
        #expect(mixed?[2].text == "true")
        // mixed[3] should be null
        if let nested = try? mixed?[4].properties() {
            #expect(nested["nested"]?.text == "value")
        }
    }
    
    // MARK: - Section 6: Escape Sequence Tests
    
    @Test("Escaped quotes in strings")
    func escapedQuotesInStrings() throws {
        let testCases = [
            (#"{"text": "Hello \"World\""}"#, #"Hello "World""#, true),
            (#"{"text": "Quote: \""}"#, #"Quote: ""#, true),
            (#"{"text": "\\\"escaped\\\""}"#, #"\"escaped\""#, true)
        ]
        
        for (json, expectedValue, expectedComplete) in testCases {
            let content = try parseJSON(json)
            #expect(content.isComplete == expectedComplete)
            
            if expectedComplete {
                let properties = try content.properties()
                #expect(properties["text"]?.text == expectedValue)
            }
        }
    }
    
    @Test("Escaped backslashes")
    func escapedBackslashes() throws {
        let json = #"{"path": "C:\\Users\\Alice"}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        #expect(properties["path"]?.text == #"C:\Users\Alice"#)
    }
    
    @Test("Special characters in strings")
    func specialCharactersInStrings() throws {
        let json = #"{"text": "Line1\nLine2\tTabbed"}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        let text = properties["text"]?.text
        #expect(text?.contains("\n") == true)
        #expect(text?.contains("\t") == true)
    }
    
    @Test("Unicode characters")
    func unicodeCharacters() throws {
        let json = #"{"emoji": "Hello 👋 世界"}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        #expect(properties["emoji"]?.text == "Hello 👋 世界")
    }
    
    // MARK: - Section 7: Edge Cases
    
    @Test("Empty string values")
    func emptyStringValues() throws {
        let json = #"{"empty": ""}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        #expect(properties["empty"]?.text == "")
    }
    
    @Test("Whitespace handling")
    func whitespaceHandling() throws {
        let json = """
        {
            "name"    :    "Alice"  ,
            "age"  :   25
        }
        """
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        #expect(properties["name"]?.text == "Alice")
        #expect(properties["age"]?.text == "25")
    }
    
    @Test("Very long string")
    func veryLongString() throws {
        let longString = String(repeating: "a", count: 10000)
        let json = #"{"long": "\#(longString)"}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        #expect(properties["long"]?.text.count == 10000)
    }
    
    @Test("Deeply nested structure - 10 levels")
    func deeplyNestedTenLevels() throws {
        var json = "{"
        for i in 1...10 {
            json += #""a\#(i)": {"#
        }
        json += #""value": "value""#
        for _ in 1...10 {
            json += "}"
        }
        json += "}"
        
        let content = try parseJSON(json)
        #expect(content.isComplete == true)
        
        // Navigate through all levels
        var current: GeneratedContent? = content
        for i in 1...10 {
            current = try current?.properties()["a\(i)"]
        }
        // After navigating through a1 to a10, we have {"value": "value"}
        // Need to access the "value" property
        let finalValue = try current?.properties()["value"]
        #expect(finalValue?.text == "value")
    }
    
    @Test("Large array - 100 elements")
    func largeArray() throws {
        let elements = (1...100).map { String($0) }.joined(separator: ", ")
        let json = #"{"numbers": [\#(elements)]}"#
        let content = try parseJSON(json)
        
        #expect(content.isComplete == true)
        let properties = try content.properties()
        let numbers = try properties["numbers"]?.elements()
        #expect(numbers?.count == 100)
        #expect(numbers?[0].text == "1")
        #expect(numbers?[99].text == "100")
    }
    
    // MARK: - Section 8: Streaming Simulation Tests
    
    @Test("Progressive JSON building simulation")
    func progressiveJSONBuildingSimulation() throws {
        let stages = [
            "{",
            #"{"id":"#,
            #"{"id": "123"#,
            #"{"id": "123","#,
            #"{"id": "123", "name":"#,
            #"{"id": "123", "name": "Alice""#,
            #"{"id": "123", "name": "Alice", "items": ["#,
            #"{"id": "123", "name": "Alice", "items": [1, 2, 3]"#,
            #"{"id": "123", "name": "Alice", "items": [1, 2, 3]}"#
        ]
        
        let expectedComplete = [false, false, false, false, false, false, false, false, true]
        let expectedPropertyCounts = [0, 0, 1, 1, 1, 2, 3, 3, 3]  // Stage 7 has incomplete array but still counts as property
        
        for (index, json) in stages.enumerated() {
            let content = try parseJSON(json)
            #expect(content.isComplete == expectedComplete[index])
            
            if let properties = try? content.properties() {
                let actualCount = properties.count
                #expect(actualCount == expectedPropertyCounts[index])
            }
        }
    }
    
    @Test("Real-world LLM streaming pattern")
    func realWorldLLMStreamingPattern() throws {
        // Simulating token-by-token streaming from an LLM
        let tokens = [
            "{\"",
            "{\"response",
            "{\"response\":",
            "{\"response\": \"",
            "{\"response\": \"Hello",
            "{\"response\": \"Hello,",
            "{\"response\": \"Hello, how",
            "{\"response\": \"Hello, how can",
            "{\"response\": \"Hello, how can I",
            "{\"response\": \"Hello, how can I help",
            "{\"response\": \"Hello, how can I help you",
            "{\"response\": \"Hello, how can I help you?\"",
            "{\"response\": \"Hello, how can I help you?\",",
            "{\"response\": \"Hello, how can I help you?\", \"status",
            "{\"response\": \"Hello, how can I help you?\", \"status\":",
            "{\"response\": \"Hello, how can I help you?\", \"status\": \"",
            "{\"response\": \"Hello, how can I help you?\", \"status\": \"complete",
            "{\"response\": \"Hello, how can I help you?\", \"status\": \"complete\"",
            "{\"response\": \"Hello, how can I help you?\", \"status\": \"complete\"}"
        ]
        
        var lastValidResponse: String?
        var lastValidStatus: String?
        
        for token in tokens {
            let content = try GeneratedContent(json: token)
            
            if let properties = try? content.properties() {
                if let response = properties["response"]?.text {
                    lastValidResponse = response
                }
                if let status = properties["status"]?.text {
                    lastValidStatus = status
                }
            }
            
            if content.isComplete {
                #expect(lastValidResponse == "Hello, how can I help you?")
                #expect(lastValidStatus == "complete")
            }
        }
    }
    
    @Test("Complex nested structure progressive building")
    func complexNestedStructureProgressiveBuilding() throws {
        let stages = [
            #"{"#,
            #"{"user"#,
            #"{"user":"#,
            #"{"user": {"#,
            #"{"user": {"id"#,
            #"{"user": {"id":"#,
            #"{"user": {"id": "u123"#,
            #"{"user": {"id": "u123","#,
            #"{"user": {"id": "u123", "profile"#,
            #"{"user": {"id": "u123", "profile":"#,
            #"{"user": {"id": "u123", "profile": {"#,
            #"{"user": {"id": "u123", "profile": {"name"#,
            #"{"user": {"id": "u123", "profile": {"name":"#,
            #"{"user": {"id": "u123", "profile": {"name": "Alice"#,
            #"{"user": {"id": "u123", "profile": {"name": "Alice"}"#,
            #"{"user": {"id": "u123", "profile": {"name": "Alice"}}"#,
            #"{"user": {"id": "u123", "profile": {"name": "Alice"}}}"#
        ]
        
        for (index, json) in stages.enumerated() {
            let content = try parseJSON(json)
            let isComplete = content.isComplete
            
            // Only the last stage should be complete
            #expect(isComplete == (index == stages.count - 1))
            
            // Try to extract whatever is available
            if let properties = try? content.properties(),
               let user = properties["user"],
               let userProps = try? user.properties() {
                
                // After stage 6, we should have user.id
                if index >= 6 {
                    #expect(userProps["id"]?.text == "u123")
                }
                
                // After stage 14, we should have user.profile.name
                if index >= 14 {
                    if let profile = userProps["profile"],
                       let profileProps = try? profile.properties() {
                        #expect(profileProps["name"]?.text == "Alice")
                    }
                }
            }
        }
    }
}