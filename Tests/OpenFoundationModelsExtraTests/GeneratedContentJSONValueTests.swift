import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsExtra
import JSONSchema

@Suite("GeneratedContent JSONValue Conversion Tests")
struct GeneratedContentJSONValueTests {

    @Test("String value roundtrip")
    func stringRoundtrip() throws {
        let content = GeneratedContent(kind: .string("hello"))
        let value = content.toJSONValue()
        guard case .string(let s) = value else {
            Issue.record("Expected .string, got \(value)")
            return
        }
        #expect(s == "hello")
        let restored = try GeneratedContent(jsonValue: value)
        #expect(restored.jsonString == content.jsonString)
    }

    @Test("Integer value roundtrip")
    func integerRoundtrip() throws {
        let content = GeneratedContent(kind: .number(42.0))
        let value = content.toJSONValue()
        guard case .int(let i) = value else {
            Issue.record("Expected .int, got \(value)")
            return
        }
        #expect(i == 42)
        let restored = try GeneratedContent(jsonValue: value)
        #expect(restored.jsonString == "42")
    }

    @Test("Double value roundtrip")
    func doubleRoundtrip() throws {
        let content = GeneratedContent(kind: .number(3.14))
        let value = content.toJSONValue()
        guard case .double(let d) = value else {
            Issue.record("Expected .double, got \(value)")
            return
        }
        #expect(abs(d - 3.14) < 0.0001)
        let restored = try GeneratedContent(jsonValue: value)
        #expect(restored.jsonString == content.jsonString)
    }

    @Test("Bool value roundtrip")
    func boolRoundtrip() throws {
        let content = GeneratedContent(kind: .bool(true))
        let value = content.toJSONValue()
        guard case .bool(let b) = value else {
            Issue.record("Expected .bool, got \(value)")
            return
        }
        #expect(b == true)
        let restored = try GeneratedContent(jsonValue: value)
        #expect(restored.jsonString == "true")
    }

    @Test("Null value roundtrip")
    func nullRoundtrip() throws {
        let content = GeneratedContent(kind: .null)
        let value = content.toJSONValue()
        #expect(value == .null)
        let restored = try GeneratedContent(jsonValue: value)
        #expect(restored.jsonString == "null")
    }

    @Test("Object value roundtrip")
    func objectRoundtrip() throws {
        let content = GeneratedContent(properties: ["name": "Alice", "age": GeneratedContent(kind: .number(30))])
        let value = content.toJSONValue()
        guard case .object(let dict) = value else {
            Issue.record("Expected .object, got \(value)")
            return
        }
        #expect(dict["name"] == .string("Alice"))
        #expect(dict["age"] == .int(30))
    }

    @Test("Array value roundtrip")
    func arrayRoundtrip() throws {
        let content = GeneratedContent(elements: ["a", "b", "c"])
        let value = content.toJSONValue()
        guard case .array(let arr) = value else {
            Issue.record("Expected .array, got \(value)")
            return
        }
        #expect(arr.count == 3)
        #expect(arr[0] == .string("a"))
    }

    @Test("JSONValue to GeneratedContent: object")
    func jsonValueToGeneratedContent() throws {
        let value: JSONValue = .object(["x": .int(1), "y": .string("hi")])
        let content = try GeneratedContent(jsonValue: value)
        let props = try content.properties()
        #expect(props["x"] != nil)
        #expect(props["y"] != nil)
    }

    @Test("JSONValue to GeneratedContent: nested")
    func nestedJSONValue() throws {
        let value: JSONValue = .object([
            "user": .object(["name": .string("Bob"), "age": .int(25)])
        ])
        let content = try GeneratedContent(jsonValue: value)
        let props = try content.properties()
        let user = try props["user"]!.properties()
        #expect(user["name"] != nil)
        #expect(user["age"] != nil)
    }

    @Test("JSONValue to GeneratedContent: array")
    func jsonValueArray() throws {
        let value: JSONValue = .array([.int(1), .int(2), .int(3)])
        let content = try GeneratedContent(jsonValue: value)
        let elems = try content.elements()
        #expect(elems.count == 3)
    }

    @Test("JSONValue to GeneratedContent: null")
    func jsonValueNull() throws {
        let content = try GeneratedContent(jsonValue: .null)
        #expect(content.jsonString == "null")
    }

    @Test("toJSONValue: integer numbers output as int not double")
    func integerOutputFormat() {
        let content = GeneratedContent(kind: .number(100.0))
        #expect(content.jsonString == "100")
        let value = content.toJSONValue()
        if case .int(let i) = value {
            #expect(i == 100)
        } else {
            Issue.record("Expected .int(100), got \(value)")
        }
    }

    @Test("toJSONValue: string with special characters")
    func specialCharacters() throws {
        let content = GeneratedContent(kind: .string("hello\nworld\t!"))
        let value = content.toJSONValue()
        guard case .string(let s) = value else {
            Issue.record("Expected .string"); return
        }
        #expect(s == "hello\nworld\t!")
        let restored = try GeneratedContent(jsonValue: value)
        #expect(restored.jsonString == content.jsonString)
    }

    @Test("toJSONValue on JSON-parsed content")
    func fromParsedJSON() throws {
        let content = try GeneratedContent(json: #"{"score": 99, "pass": true}"#)
        let value = content.toJSONValue()
        guard case .object(let dict) = value else {
            Issue.record("Expected .object"); return
        }
        #expect(dict["score"] == .int(99))
        #expect(dict["pass"] == .bool(true))
    }
}
