import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore
import OpenFoundationModelsMacros

@Suite("GenerationSchema Debug Test")
struct GenerationSchemaDebugTest {
    
    @Test("Debug: Check actual JSON output of GenerationSchema")
    func debugSchemaOutput() throws {
        // Create a simple schema directly
        let schema = GenerationSchema(
            type: String.self,  // dummy type
            description: "Test parameters",
            properties: [
                GenerationSchema.Property(
                    name: "field1",
                    description: "First field",
                    type: String.self
                ),
                GenerationSchema.Property(
                    name: "field2", 
                    description: "Second field",
                    type: Int.self
                )
            ]
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        
        // Print the actual JSON
        if let jsonString = String(data: data, encoding: .utf8) {
            print("\n=== Actual JSON Output ===")
            print(jsonString)
            print("========================\n")
        }
        
        // Parse and verify
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Check what we got
        print("Type: \(json?["type"] ?? "nil")")
        print("Description: \(json?["description"] ?? "nil")")
        print("Properties exist: \(json?["properties"] != nil)")
        print("Required exist: \(json?["required"] != nil)")
        
        // This test will fail if properties are missing
        #expect(json?["properties"] != nil, "Properties should be present in encoded JSON")
        
        if let properties = json?["properties"] as? [String: Any] {
            print("\nProperties found:")
            for (key, value) in properties {
                print("  - \(key): \(value)")
            }
            #expect(properties["field1"] != nil)
            #expect(properties["field2"] != nil)
        } else {
            Issue.record("Properties field is missing or not a dictionary!")
        }
    }
    
    @Generable
    struct TestModelWithMacro {
        let name: String
        let value: Int
    }
    
    @Test("Debug: Check macro-generated schema")
    func debugMacroGeneratedSchema() throws {
        let schema = TestModelWithMacro.generationSchema
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        
        // Print the actual JSON
        if let jsonString = String(data: data, encoding: .utf8) {
            print("\n=== Macro-generated Schema JSON ===")
            print(jsonString)
            print("==================================\n")
        }
        
        // Parse and verify
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        #expect(json?["properties"] != nil, "Macro-generated schema should have properties")
    }
}