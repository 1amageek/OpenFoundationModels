import Testing
import Foundation
import OpenFoundationModelsExtra
import OpenFoundationModels
@_spi(Internal) @testable import Generation

// MARK: - Test Types

@Generable
struct RequiredPrimitivesModel {
    var name: String
    var age: Int
    var isActive: Bool
}

@Generable
struct OptionalPrimitivesModel {
    var label: String
    var flag: Bool?
    var note: String?
}

@Generable
struct MixedModel {
    var id: Int
    var title: String
    var subtitle: String?
    var count: Int?
    var enabled: Bool?
}

@Generable
enum Priority: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

@Generable
struct ModelWithEnum {
    var name: String
    var priority: Priority
}

@Generable
struct ModelWithOptionalEnum {
    var name: String
    var priority: Priority?
}

@Generable
struct NestedModel {
    var outer: String
    var inner: InnerModel

    @Generable
    struct InnerModel {
        var value: String
        var count: Int
    }
}

@Generable
struct NestedOptionalModel {
    var outer: String
    var inner: InnerModel?

    @Generable
    struct InnerModel {
        var value: String
        var score: Int?
    }
}

@Generable
struct ArrayModel {
    var tags: [String]
    var scores: [Int]?
}

// MARK: - Helpers

/// Encode JSONSchema back to dictionary for inspection
private func schemaToDict(_ schema: JSONSchema) throws -> [String: Any] {
    let data = try JSONEncoder().encode(schema)
    guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw SchemaTestError.notDictionary
    }
    return dict
}

private enum SchemaTestError: Error {
    case notDictionary
}

// MARK: - Tests

@Suite("_jsonSchema Conversion Tests")
struct JSONSchemaConversionTests {

    // MARK: - Required Primitives

    @Test("Required primitive types convert to JSONSchema without crash")
    func requiredPrimitives() throws {
        let schema = RequiredPrimitivesModel.generationSchema
        let jsonSchema = schema._jsonSchema

        // Re-encode to verify structure
        let dict = try schemaToDict(jsonSchema)
        #expect(dict["type"] as? String == "object")
        let props = try #require(dict["properties"] as? [String: Any])
        #expect(props["name"] != nil)
        #expect(props["age"] != nil)
        #expect(props["isActive"] != nil)
    }

    // MARK: - Optional Primitives (CRASH CASE)

    @Test("Optional Bool converts to JSONSchema without crash")
    func optionalBool() throws {
        let schema = OptionalPrimitivesModel.generationSchema
        // This crashes with try! because toSchemaDictionary() produces
        // "type": ["boolean", "null"] which JSONSchema cannot decode
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        #expect(dict["type"] as? String == "object")
    }

    @Test("Optional String converts to JSONSchema without crash")
    func optionalString() throws {
        let schema = OptionalPrimitivesModel.generationSchema
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        let props = try #require(dict["properties"] as? [String: Any])
        #expect(props["note"] != nil)
    }

    // MARK: - Mixed Required/Optional

    @Test("Struct with mixed required and optional properties converts correctly")
    func mixedRequiredOptional() throws {
        let schema = MixedModel.generationSchema
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        let props = try #require(dict["properties"] as? [String: Any])
        #expect(props["id"] != nil)
        #expect(props["title"] != nil)
        #expect(props["subtitle"] != nil)
        #expect(props["count"] != nil)
        #expect(props["enabled"] != nil)

        // Required should include non-optional fields only
        let required = try #require(dict["required"] as? [String])
        #expect(required.contains("id"))
        #expect(required.contains("title"))
        #expect(!required.contains("subtitle"))
        #expect(!required.contains("count"))
        #expect(!required.contains("enabled"))
    }

    // MARK: - Enum

    @Test("Enum type converts to JSONSchema")
    func enumType() throws {
        let schema = Priority.generationSchema
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        #expect(dict["type"] as? String == "string")
        let enumValues = try #require(dict["enum"] as? [String])
        #expect(enumValues.contains("low"))
        #expect(enumValues.contains("medium"))
        #expect(enumValues.contains("high"))
    }

    @Test("Struct with required enum property converts to JSONSchema")
    func structWithEnum() throws {
        let schema = ModelWithEnum.generationSchema
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        let props = try #require(dict["properties"] as? [String: Any])
        #expect(props["name"] != nil)
        #expect(props["priority"] != nil)
    }

    // MARK: - Optional Enum

    @Test("Struct with optional enum property converts to JSONSchema without crash")
    func optionalEnum() throws {
        let schema = ModelWithOptionalEnum.generationSchema
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        let props = try #require(dict["properties"] as? [String: Any])
        #expect(props["name"] != nil)
        #expect(props["priority"] != nil)
    }

    // MARK: - Nested Objects

    @Test("Nested object converts to JSONSchema")
    func nestedObject() throws {
        let schema = NestedModel.generationSchema
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        let props = try #require(dict["properties"] as? [String: Any])
        #expect(props["outer"] != nil)
        #expect(props["inner"] != nil)
    }

    @Test("Optional nested object with optional properties converts without crash")
    func optionalNestedObject() throws {
        let schema = NestedOptionalModel.generationSchema
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        let props = try #require(dict["properties"] as? [String: Any])
        #expect(props["outer"] != nil)
        #expect(props["inner"] != nil)

        let required = try #require(dict["required"] as? [String])
        #expect(required.contains("outer"))
        #expect(!required.contains("inner"))
    }

    // MARK: - Array Types

    @Test("Required array converts to JSONSchema")
    func requiredArray() throws {
        let schema = ArrayModel.generationSchema
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        let props = try #require(dict["properties"] as? [String: Any])
        #expect(props["tags"] != nil)
    }

    @Test("Optional array converts to JSONSchema without crash")
    func optionalArray() throws {
        let schema = ArrayModel.generationSchema
        let jsonSchema = schema._jsonSchema

        let dict = try schemaToDict(jsonSchema)
        let props = try #require(dict["properties"] as? [String: Any])
        #expect(props["scores"] != nil)

        let required = try #require(dict["required"] as? [String])
        #expect(required.contains("tags"))
        #expect(!required.contains("scores"))
    }
}
