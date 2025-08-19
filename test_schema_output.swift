import Foundation
import OpenFoundationModels
import OpenFoundationModelsCore

// Simple test without macros - using the initializer directly
let testSchema = GenerationSchema(
    type: String.self,  // dummy type
    description: "Get weather parameters",
    properties: [
        GenerationSchema.Property(
            name: "location",
            description: "City name",
            type: String.self
        ),
        GenerationSchema.Property(
            name: "unit",
            description: "Temperature unit",
            type: String?.self
        )
    ]
)

print("=== Testing GenerationSchema Encoding ===\n")

// Debug description
print("Debug description:")
print(testSchema.debugDescription)
print()

// Encode to JSON
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

do {
    let data = try encoder.encode(testSchema)
    
    if let jsonString = String(data: data, encoding: .utf8) {
        print("Encoded JSON:")
        print(jsonString)
        print()
        
        // Parse and check structure
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Analysis:")
            print("- type: \(json["type"] ?? "nil")")
            print("- description: \(json["description"] ?? "nil")")
            print("- properties: \(json["properties"] != nil ? "✅ Present" : "❌ Missing")")
            print("- required: \(json["required"] != nil ? "✅ Present" : "❌ Missing")")
            
            if let properties = json["properties"] as? [String: Any] {
                print("\nProperties content:")
                for (key, _) in properties {
                    print("  - \(key)")
                }
            }
        }
    }
} catch {
    print("Error: \(error)")
}