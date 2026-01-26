import Foundation
import Testing
@testable import OpenFoundationModelsCore

@Suite("Optional Property Tests")
struct OptionalPropertyTests {

    @Test("Optional Generable property creation")
    func optionalGenerableProperty() throws {
        // Create a property with Optional<String> type
        let prop = GenerationSchema.Property(
            name: "nickname",
            description: "Optional nickname",
            type: String?.self,
            guides: []
        )

        // Verify the property was created correctly
        #expect(prop.name == "nickname")
        #expect(prop.description == "Optional nickname")

        // Verify type is Optional
        let typeName = String(describing: prop.type)
        #expect(typeName.hasPrefix("Optional<"), "Type should be Optional, got: \(typeName)")
    }

    @Test("Optional property in schema generates correct JSON")
    func optionalPropertyInSchema() throws {
        // Create a schema with an optional property
        let schema = GenerationSchema(
            type: String.self,
            description: "Test schema",
            properties: [
                GenerationSchema.Property(
                    name: "required_field",
                    description: "A required field",
                    type: String.self
                ),
                GenerationSchema.Property(
                    name: "optional_field",
                    description: "An optional field",
                    type: String?.self
                )
            ]
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!

        print("Generated JSON Schema:")
        print(json)

        // Verify the JSON contains correct structure
        #expect(json.contains("\"required_field\""))
        #expect(json.contains("\"optional_field\""))

        // Check that optional field has null type
        // The optional field should have type: ["string", "null"]
        #expect(json.contains("null"), "Optional field should allow null")

        // Verify required array only contains required_field
        #expect(json.contains("\"required\""))
    }

    @Test("Optional String property with Regex")
    func optionalStringWithRegex() throws {
        let pattern = /^[a-z]+$/
        let prop = GenerationSchema.Property(
            name: "code",
            description: "Optional code",
            type: String?.self,
            guides: [pattern]
        )

        #expect(prop.name == "code")
        #expect(prop.regexPatterns.count == 1)

        let typeName = String(describing: prop.type)
        #expect(typeName.hasPrefix("Optional<"))
    }

    @Test("Optional Int property with guides")
    func optionalIntWithGuides() throws {
        let prop = GenerationSchema.Property(
            name: "age",
            description: "Optional age",
            type: Int?.self,
            guides: [.minimum(0), .maximum(150)]
        )

        #expect(prop.name == "age")
        #expect(prop.guides.count == 2)

        let typeName = String(describing: prop.type)
        #expect(typeName.hasPrefix("Optional<"))
    }

    @Test("Guides are applied to JSON schema")
    func guidesAppliedToJSONSchema() throws {
        let schema = GenerationSchema(
            type: String.self,
            description: "Test schema with guides",
            properties: [
                GenerationSchema.Property(
                    name: "level",
                    description: "Level between 1 and 100",
                    type: Int.self,
                    guides: [.minimum(1), .maximum(100)]
                ),
                GenerationSchema.Property(
                    name: "optionalScore",
                    description: "Optional score between 0 and 10",
                    type: Int?.self,
                    guides: [.minimum(0), .maximum(10)]
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!

        print("Schema with guides JSON:")
        print(json)

        // Parse and verify
        let jsonData = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        guard let properties = parsed["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }

        // Verify level has min/max
        if let levelProp = properties["level"] as? [String: Any] {
            #expect(levelProp["minimum"] as? Int == 1, "level should have minimum 1")
            #expect(levelProp["maximum"] as? Int == 100, "level should have maximum 100")
        } else {
            Issue.record("level property not found")
        }

        // Verify optionalScore has min/max and null type
        if let scoreProp = properties["optionalScore"] as? [String: Any] {
            #expect(scoreProp["minimum"] as? Int == 0, "optionalScore should have minimum 0")
            #expect(scoreProp["maximum"] as? Int == 10, "optionalScore should have maximum 10")

            // Should also have null type
            if let typeArray = scoreProp["type"] as? [String] {
                #expect(typeArray.contains("integer"), "optionalScore should have integer type")
                #expect(typeArray.contains("null"), "optionalScore should allow null")
            }
        } else {
            Issue.record("optionalScore property not found")
        }
    }

    @Test("Mixed required and optional properties")
    func mixedRequiredOptionalProperties() throws {
        let schema = GenerationSchema(
            type: String.self,
            description: "User profile",
            properties: [
                GenerationSchema.Property(name: "id", description: "User ID", type: String.self),
                GenerationSchema.Property(name: "name", description: "Full name", type: String.self),
                GenerationSchema.Property(name: "email", description: "Email address", type: String?.self),
                GenerationSchema.Property(name: "age", description: "Age", type: Int?.self)
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!

        print("Mixed Schema JSON:")
        print(json)

        // Parse the JSON to verify structure
        let jsonData = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Check required array
        if let required = parsed["required"] as? [String] {
            #expect(required.contains("id"), "id should be required")
            #expect(required.contains("name"), "name should be required")
            #expect(!required.contains("email"), "email should NOT be required")
            #expect(!required.contains("age"), "age should NOT be required")
        }

        // Check properties
        if let properties = parsed["properties"] as? [String: Any] {
            // Check email has null type
            if let emailProp = properties["email"] as? [String: Any],
               let emailType = emailProp["type"] as? [String] {
                #expect(emailType.contains("string"))
                #expect(emailType.contains("null"))
            }

            // Check age has null type
            if let ageProp = properties["age"] as? [String: Any],
               let ageType = ageProp["type"] as? [String] {
                #expect(ageType.contains("integer"))
                #expect(ageType.contains("null"))
            }
        }
    }

    @Test("Regex pattern is applied to JSON schema for optional String")
    func regexPatternAppliedToJSONSchema() throws {
        let schema = GenerationSchema(
            type: String.self,
            description: "Test regex pattern",
            properties: [
                GenerationSchema.Property(
                    name: "code",
                    description: "Code with pattern",
                    type: String?.self,
                    guides: [/^[A-Z]{3}$/]
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!

        print("Regex Schema JSON:")
        print(json)

        // Parse and verify pattern is in JSON
        let jsonData = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        guard let properties = parsed["properties"] as? [String: Any],
              let codeProp = properties["code"] as? [String: Any] else {
            Issue.record("code property not found")
            return
        }

        // Check pattern exists
        #expect(codeProp["pattern"] != nil, "pattern should be present in JSON schema")

        // Check type allows null
        if let typeArray = codeProp["type"] as? [String] {
            #expect(typeArray.contains("string"))
            #expect(typeArray.contains("null"))
        } else {
            Issue.record("type should be array for optional")
        }
    }

    @Test("Range guide on optional Double")
    func rangeGuideOnOptionalDouble() throws {
        let schema = GenerationSchema(
            type: String.self,
            description: "Test range",
            properties: [
                GenerationSchema.Property(
                    name: "temperature",
                    description: "Temperature between -40 and 50",
                    type: Double?.self,
                    guides: [.range(-40.0...50.0)]
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!

        print("Range Schema JSON:")
        print(json)

        let jsonData = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        guard let properties = parsed["properties"] as? [String: Any],
              let tempProp = properties["temperature"] as? [String: Any] else {
            Issue.record("temperature property not found")
            return
        }

        // Check min/max
        #expect(tempProp["minimum"] as? Double == -40.0)
        #expect(tempProp["maximum"] as? Double == 50.0)

        // Check type allows null
        if let typeArray = tempProp["type"] as? [String] {
            #expect(typeArray.contains("number"))
            #expect(typeArray.contains("null"))
        }
    }

    @Test("AnyOf guide on optional String")
    func anyOfGuideOnOptionalString() throws {
        let schema = GenerationSchema(
            type: String.self,
            description: "Test anyOf",
            properties: [
                GenerationSchema.Property(
                    name: "status",
                    description: "Status value",
                    type: String?.self,
                    guides: [.anyOf(["active", "inactive", "pending"])]
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!

        print("AnyOf Schema JSON:")
        print(json)

        let jsonData = json.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        guard let properties = parsed["properties"] as? [String: Any],
              let statusProp = properties["status"] as? [String: Any] else {
            Issue.record("status property not found")
            return
        }

        // Check enum values
        if let enumValues = statusProp["enum"] as? [String] {
            #expect(enumValues.contains("active"))
            #expect(enumValues.contains("inactive"))
            #expect(enumValues.contains("pending"))
        } else {
            Issue.record("enum should be present for anyOf guide")
        }

        // Check type allows null
        if let typeArray = statusProp["type"] as? [String] {
            #expect(typeArray.contains("string"))
            #expect(typeArray.contains("null"))
        }
    }
}
