#!/usr/bin/env swift -I .build/debug -L .build/debug -lOpenFoundationModelsCore

import Foundation
import OpenFoundationModelsCore

// Create a simple schema with properties
let schema = GenerationSchema(
    type: String.self,  // dummy type
    description: "Test parameters",
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
print("Debug description:")
print(schema.debugDescription)
print()

// Encode to JSON
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

do {
    let data = try encoder.encode(schema)
    
    if let jsonString = String(data: data, encoding: .utf8) {
        print("Encoded JSON:")
        print(jsonString)
        print()
        
        // Parse and verify
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Verification:")
            print("✓ type: \(json["type"] ?? "nil")")
            print("✓ description: \(json["description"] ?? "nil")")
            
            if let properties = json["properties"] as? [String: Any] {
                print("✓ properties: Present with \(properties.count) fields")
                for (key, _) in properties {
                    print("  - \(key)")
                }
            } else {
                print("✗ properties: Missing!")
            }
            
            if let required = json["required"] as? [String] {
                print("✓ required: \(required)")
            } else {
                print("✗ required: Missing!")
            }
        }
    }
} catch {
    print("Error: \(error)")
}