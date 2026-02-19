import Foundation
import Testing
@testable import OpenFoundationModels

// MARK: - Test Types

@Generable
struct CodablePoint: Codable, Sendable {
    var x: Double
    var y: Double
}

@Generable
struct CodableDocument: Codable, Sendable {
    var title: String
    var body: String
    var score: Int
}

@Generable
struct CodableNested: Codable, Sendable {
    var label: String
    var point: CodablePoint
}

@Generable
struct CodableOptional: Codable, Sendable {
    var name: String
    var nickname: String?
}

@Generable
struct CodableWithArray: Codable, Sendable {
    var tags: [String]
    var value: Int
}

@Generable
struct CodableWithCustomCodingKeys: Codable, Sendable {
    var firstName: String
    var lastName: String

    init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

@Generable
struct CodableWithDefault: Codable, Sendable {
    var name: String
    var count: Int = 0
}

// MARK: - Tests

@Suite("Generable Codable CodingKeys Tests", .tags(.generable, .macros))
struct GenerableCodableTests {

    // MARK: - Encoding excludes _rawGeneratedContent

    @Test("Encoded JSON does not contain _rawGeneratedContent")
    func encodedJSONExcludesRawContent() throws {
        let content = try GeneratedContent(json: #"{"x": 1.5, "y": 2.5}"#)
        let point = try CodablePoint(content)

        let data = try JSONEncoder().encode(point)
        let json = String(data: data, encoding: .utf8)!

        #expect(!json.contains("_rawGeneratedContent"))
        #expect(json.contains("\"x\""))
        #expect(json.contains("\"y\""))
    }

    @Test("Encoded JSON contains only declared properties")
    func encodedJSONContainsOnlyDeclaredProperties() throws {
        let content = try GeneratedContent(json: #"{"title": "Hello", "body": "World", "score": 42}"#)
        let doc = try CodableDocument(content)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(doc)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(jsonObject.keys.sorted() == ["body", "score", "title"])
    }

    // MARK: - Encode/Decode round-trip

    @Test("Encode then decode round-trip preserves values")
    func encoderDecoderRoundTrip() throws {
        let content = try GeneratedContent(json: #"{"x": 3.14, "y": -2.71}"#)
        let original = try CodablePoint(content)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CodablePoint.self, from: data)

        #expect(decoded.x == 3.14)
        #expect(decoded.y == -2.71)
    }

    @Test("Nested @Generable Codable round-trip")
    func nestedRoundTrip() throws {
        let json = #"{"label": "Origin", "point": {"x": 0.0, "y": 0.0}}"#
        let content = try GeneratedContent(json: json)
        let nested = try CodableNested(content)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(nested)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(!jsonString.contains("_rawGeneratedContent"))

        let decoded = try JSONDecoder().decode(CodableNested.self, from: data)
        #expect(decoded.label == "Origin")
        #expect(decoded.point.x == 0.0)
        #expect(decoded.point.y == 0.0)
    }

    @Test("Optional property round-trip")
    func optionalPropertyRoundTrip() throws {
        // With value
        let json1 = #"{"name": "Alice", "nickname": "Ali"}"#
        let content1 = try GeneratedContent(json: json1)
        let obj1 = try CodableOptional(content1)

        let data1 = try JSONEncoder().encode(obj1)
        let decoded1 = try JSONDecoder().decode(CodableOptional.self, from: data1)
        #expect(decoded1.name == "Alice")
        #expect(decoded1.nickname == "Ali")

        // Without value
        let json2 = #"{"name": "Bob"}"#
        let content2 = try GeneratedContent(json: json2)
        let obj2 = try CodableOptional(content2)

        let data2 = try JSONEncoder().encode(obj2)
        let jsonString2 = String(data: data2, encoding: .utf8)!
        #expect(!jsonString2.contains("_rawGeneratedContent"))
    }

    @Test("Array property round-trip")
    func arrayPropertyRoundTrip() throws {
        let json = #"{"tags": ["swift", "macro"], "value": 10}"#
        let content = try GeneratedContent(json: json)
        let obj = try CodableWithArray(content)

        let data = try JSONEncoder().encode(obj)
        let decoded = try JSONDecoder().decode(CodableWithArray.self, from: data)
        #expect(decoded.tags == ["swift", "macro"])
        #expect(decoded.value == 10)

        let jsonString = String(data: data, encoding: .utf8)!
        #expect(!jsonString.contains("_rawGeneratedContent"))
    }

    // MARK: - User-defined CodingKeys preserved

    @Test("User-defined CodingKeys are preserved")
    func userDefinedCodingKeysPreserved() throws {
        let obj = CodableWithCustomCodingKeys(firstName: "John", lastName: "Doe")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(obj)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // User-defined CodingKeys should map to snake_case
        #expect(jsonObject.keys.sorted() == ["first_name", "last_name"])
        #expect(jsonObject["first_name"] as? String == "John")
        #expect(jsonObject["last_name"] as? String == "Doe")
    }

    // MARK: - Decode from external JSON

    @Test("Decode from plain JSON without _rawGeneratedContent")
    func decodeFromPlainJSON() throws {
        let json = #"{"x": 10.0, "y": 20.0}"#
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(CodablePoint.self, from: data)

        #expect(decoded.x == 10.0)
        #expect(decoded.y == 20.0)
    }

    // MARK: - Memberwise init

    @Test("Macro-generated memberwise init works without manual init")
    func memberwiseInitGenerated() throws {
        let point = CodablePoint(x: 1.0, y: 2.0)
        #expect(point.x == 1.0)
        #expect(point.y == 2.0)
    }

    @Test("Memberwise init with default value allows omitting parameter")
    func memberwiseInitDefaultValue() throws {
        let obj = CodableWithDefault(name: "test")
        #expect(obj.name == "test")
        #expect(obj.count == 0)

        let obj2 = CodableWithDefault(name: "test2", count: 5)
        #expect(obj2.name == "test2")
        #expect(obj2.count == 5)
    }

    @Test("Memberwise init with optional defaults to nil")
    func memberwiseInitOptionalDefaultsNil() throws {
        let obj = CodableOptional(name: "Alice")
        #expect(obj.name == "Alice")
        #expect(obj.nickname == nil)

        let obj2 = CodableOptional(name: "Bob", nickname: "B")
        #expect(obj2.name == "Bob")
        #expect(obj2.nickname == "B")
    }
}
