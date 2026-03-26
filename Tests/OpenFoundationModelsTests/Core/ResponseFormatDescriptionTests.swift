import Testing
import Foundation
@testable import OpenFoundationModels

@Generable
private struct DescTestProfile {
    let name: String
    let age: Int
    let nickname: String?
}

@Generable
private enum DescTestColor: String {
    case red = "red"
    case green = "green"
    case blue = "blue"
}

@Suite("Transcript.ResponseFormat Description Tests", .tags(.core, .unit))
struct ResponseFormatDescriptionTests {

    // MARK: - schema-based init

    @Test("schema-based description is parseable JSON")
    func schemaBasedDescriptionIsParseable() throws {
        let format = Transcript.ResponseFormat(schema: DescTestProfile.generationSchema)
        let data = Data(format.description.utf8)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json != nil)
    }

    @Test("schema-based description contains object type")
    func schemaBasedDescriptionContainsObjectType() throws {
        let format = Transcript.ResponseFormat(schema: DescTestProfile.generationSchema)
        let json = try JSONSerialization.jsonObject(with: Data(format.description.utf8)) as? [String: Any]
        #expect(json?["type"] as? String == "object")
    }

    @Test("schema-based description contains properties")
    func schemaBasedDescriptionContainsProperties() throws {
        let format = Transcript.ResponseFormat(schema: DescTestProfile.generationSchema)
        let json = try JSONSerialization.jsonObject(with: Data(format.description.utf8)) as? [String: Any]
        let props = json?["properties"] as? [String: Any]
        #expect(props != nil)
        #expect(props?["name"] != nil)
        #expect(props?["age"] != nil)
        #expect(props?["nickname"] != nil)
    }

    @Test("schema-based description contains required array")
    func schemaBasedDescriptionContainsRequired() throws {
        let format = Transcript.ResponseFormat(schema: DescTestProfile.generationSchema)
        let json = try JSONSerialization.jsonObject(with: Data(format.description.utf8)) as? [String: Any]
        let required = json?["required"] as? [String]
        #expect(required != nil)
        #expect(required?.contains("name") == true)
        #expect(required?.contains("age") == true)
        #expect(required?.contains("nickname") != true)
    }

    // MARK: - type-based init

    @Test("type-based description is parseable JSON")
    func typeBasedDescriptionIsParseable() throws {
        let format = Transcript.ResponseFormat(type: DescTestProfile.self)
        let data = Data(format.description.utf8)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json != nil)
    }

    @Test("type-based description contains object type")
    func typeBasedDescriptionContainsObjectType() throws {
        let format = Transcript.ResponseFormat(type: DescTestProfile.self)
        let json = try JSONSerialization.jsonObject(with: Data(format.description.utf8)) as? [String: Any]
        #expect(json?["type"] as? String == "object")
    }

    // MARK: - Enum schema

    @Test("enum schema description is parseable JSON")
    func enumSchemaDescriptionIsParseable() throws {
        let format = Transcript.ResponseFormat(type: DescTestColor.self)
        let data = Data(format.description.utf8)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json != nil)
    }

    @Test("enum schema description reflects string type or enum values")
    func enumSchemaDescriptionReflectsEnumValues() throws {
        let format = Transcript.ResponseFormat(type: DescTestColor.self)
        let json = try JSONSerialization.jsonObject(with: Data(format.description.utf8)) as? [String: Any]
        // enum schemas produce either "enum" array or "type": "string" with nested anyOf
        let hasEnum = json?["enum"] != nil
        let hasStringType = json?["type"] as? String == "string"
        let hasAnyOf = json?["anyOf"] != nil
        #expect(hasEnum || hasStringType || hasAnyOf)
    }

    // MARK: - name fallback

    @Test("name is set correctly for schema-based init")
    func nameForSchemaBasedInit() {
        let format = Transcript.ResponseFormat(schema: DescTestProfile.generationSchema)
        #expect(format.name.contains("DescTestProfile"))
    }

    @Test("name is set correctly for type-based init")
    func nameForTypeBasedInit() {
        let format = Transcript.ResponseFormat(type: DescTestProfile.self)
        #expect(format.name == String(describing: DescTestProfile.self))
    }
}
