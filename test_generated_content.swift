import Foundation
import OpenFoundationModels

// Test basic string creation
let content1 = GeneratedContent("Hello, world!")
print("String content: \(content1.stringValue)")

// Test JSON parsing
do {
    let jsonString = """
    {
        "name": "John Doe",
        "age": 30,
        "active": true
    }
    """
    
    let content2 = try GeneratedContent(json: jsonString)
    print("JSON parsed successfully")
    
    let properties = try content2.properties()
    print("Name: \(properties["name"]?.stringValue ?? "N/A")")
    print("Age: \(properties["age"]?.stringValue ?? "N/A")")
    print("Active: \(properties["active"]?.stringValue ?? "N/A")")
    
} catch {
    print("Error: \(error)")
}

// Test array JSON
do {
    let arrayJSON = """
    ["apple", "banana", "orange"]
    """
    
    let content3 = try GeneratedContent(json: arrayJSON)
    let elements = try content3.elements()
    print("\nArray elements:")
    for (index, element) in elements.enumerated() {
        print("  \(index): \(element.stringValue)")
    }
    
} catch {
    print("Error: \(error)")
}

// Test protocol conformances
let testContent = GeneratedContent("Test content")
print("\nProtocol conformances:")
print("Instructions: \(testContent.instructionsRepresentation.text)")
print("Prompt: \(testContent.promptRepresentation.text)")
print("Generated content: \(testContent.generatedContent.stringValue)")

print("\nAll tests passed!")