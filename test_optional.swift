import Foundation
import OpenFoundationModelsCore

// Test Optional type detection
let stringType = String.self
let optionalStringType = String?.self

print("String type: \(String(describing: stringType))")
print("Optional<String> type: \(String(describing: optionalStringType))")

// Test the helper function
let typeName1 = String(describing: stringType)
let typeName2 = String(describing: optionalStringType)

print("String hasPrefix Optional<: \(typeName1.hasPrefix("Optional<"))")
print("Optional<String> hasPrefix Optional<: \(typeName2.hasPrefix("Optional<"))")

// Create a simple schema with Optional property
let schema = GenerationSchema(
    type: String.self,
    description: "Test schema",
    properties: [
        GenerationSchema.Property(
            name: "requiredField",
            description: "A required field",
            type: String.self
        ),
        GenerationSchema.Property(
            name: "optionalField",
            description: "An optional field",
            type: String?.self
        )
    ]
)

// Encode to JSON
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted]
let data = try encoder.encode(schema)
if let jsonString = String(data: data, encoding: .utf8) {
    print("\n=== Encoded Schema ===")
    print(jsonString)
}

// Check the JSON structure
let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
if let required = json?["required"] as? [String] {
    print("\n=== Required fields ===")
    print(required)
    print("requiredField is required: \(required.contains("requiredField"))")
    print("optionalField is required: \(required.contains("optionalField"))")
}