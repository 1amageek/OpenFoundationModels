
import Foundation
import Testing
@testable import OpenFoundationModels
@_spi(Internal) @testable import OpenFoundationModelsCore

// MARK: - Helpers

private func textValue(of prompt: Prompt) -> String {
    guard case .text(let t) = prompt.components.first else { return "" }
    return t.value
}

private func textValue(of instructions: Instructions) -> String {
    guard case .text(let t) = instructions.components.first else { return "" }
    return t.value
}

// MARK: - Test-local @Generable types

@Generable
struct JSONTestPerson {
    let name: String
    let age: Int
}

@Generable
struct JSONTestPoint {
    let x: Double
    let y: Double
}

@Generable
struct JSONTestProduct {
    @Guide(description: "Product name")
    let name: String
    @Guide(description: "Price in USD")
    let price: Double
    let inStock: Bool
}

@Generable
struct JSONTestAddress {
    let street: String
    let city: String
    let zipCode: String
}

@Generable
struct JSONTestEmployee {
    let id: String
    let name: String
    let department: String?
}

@Generable
struct JSONTestCompany {
    let name: String
    let address: JSONTestAddress
    let employees: [JSONTestEmployee]
}

@Generable
struct JSONTestOptionalFields {
    let requiredString: String
    let optionalString: String?
    let optionalInt: Int?
}

@Generable
struct JSONTestEmpty {
    let value: String
}

@Generable(description: "Activity status")
enum JSONTestStatus {
    case active
    case inactive
    case pending
}

// MARK: - Helper

func assertValidJSON(_ string: String, sourceLocation: SourceLocation = #_sourceLocation) {
    guard let data = string.data(using: .utf8) else {
        Issue.record("Failed to convert to UTF-8 data", sourceLocation: sourceLocation)
        return
    }
    do {
        _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    } catch {
        Issue.record("Invalid JSON: \(string) — error: \(error)", sourceLocation: sourceLocation)
    }
}

// MARK: - A. GeneratedContent Kind ごとの JSON 出力検証

@Suite("GeneratedContent JSON Output Validation", .tags(.foundation))
struct GeneratedContentJSONOutputTests {

    @Test("null kind produces valid JSON")
    func nullKindJSON() {
        let content = GeneratedContent(kind: .null)
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
        assertValidJSON(String(describing: content.debugDescription))
    }

    @Test("bool(true) produces valid JSON")
    func boolTrueJSON() {
        let content = GeneratedContent(kind: .bool(true))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("bool(false) produces valid JSON")
    func boolFalseJSON() {
        let content = GeneratedContent(kind: .bool(false))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("number(integer) produces valid JSON")
    func numberIntegerJSON() {
        let content = GeneratedContent(kind: .number(42))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("number(decimal) produces valid JSON")
    func numberDecimalJSON() {
        let content = GeneratedContent(kind: .number(3.14))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("number(zero) produces valid JSON")
    func numberZeroJSON() {
        let content = GeneratedContent(kind: .number(0))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("number(negative) produces valid JSON")
    func numberNegativeJSON() {
        let content = GeneratedContent(kind: .number(-99.5))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("string produces valid JSON")
    func stringJSON() {
        let content = GeneratedContent(kind: .string("hello"))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("empty string produces valid JSON")
    func emptyStringJSON() {
        let content = GeneratedContent(kind: .string(""))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("string with special characters produces valid JSON")
    func specialCharsStringJSON() {
        let content = GeneratedContent(kind: .string("line1\nline2\ttab \"quoted\" back\\slash"))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("string with Unicode produces valid JSON")
    func unicodeStringJSON() {
        let content = GeneratedContent(kind: .string("日本語テスト 🎉 émoji café"))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("empty array produces valid JSON")
    func emptyArrayJSON() {
        let content = GeneratedContent(kind: .array([]))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("array of strings produces valid JSON")
    func stringArrayJSON() {
        let elements = ["a", "b", "c"].map { GeneratedContent(kind: .string($0)) }
        let content = GeneratedContent(kind: .array(elements))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("array of mixed types produces valid JSON")
    func mixedArrayJSON() {
        let elements: [GeneratedContent] = [
            GeneratedContent(kind: .string("text")),
            GeneratedContent(kind: .number(42)),
            GeneratedContent(kind: .bool(true)),
            GeneratedContent(kind: .null),
        ]
        let content = GeneratedContent(kind: .array(elements))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("nested array produces valid JSON")
    func nestedArrayJSON() {
        let inner = GeneratedContent(kind: .array([
            GeneratedContent(kind: .number(1)),
            GeneratedContent(kind: .number(2)),
        ]))
        let content = GeneratedContent(kind: .array([inner, GeneratedContent(kind: .string("x"))]))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("empty structure produces valid JSON")
    func emptyStructureJSON() {
        let content = GeneratedContent(kind: .structure(properties: [:], orderedKeys: []))
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("simple structure produces valid JSON")
    func simpleStructureJSON() {
        let content = GeneratedContent(properties: [
            "name": "Alice",
            "age": 30,
        ])
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("nested structure produces valid JSON")
    func nestedStructureJSON() {
        let address = GeneratedContent(properties: [
            "street": "123 Main St",
            "city": "Tokyo",
        ])
        let content = GeneratedContent(properties: [
            "name": "Bob",
            "address": address,
        ])
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }

    @Test("structure with array property produces valid JSON")
    func structureWithArrayJSON() {
        let tags = GeneratedContent(elements: ["swift", "json", "test"])
        let content = GeneratedContent(properties: [
            "title": "doc",
            "tags": tags,
        ])
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
    }
}

// MARK: - B. @Generable struct の JSON 出力検証

@Suite("Generable Struct JSON Output Validation", .tags(.foundation))
struct GenerableStructJSONOutputTests {

    @Test("basic struct jsonString is valid JSON")
    func basicStructJSONString() throws {
        let json = #"{"name": "Alice", "age": 30}"#
        let content = try GeneratedContent(json: json)
        let person = try JSONTestPerson(content)
        assertValidJSON(person.generatedContent.jsonString)
    }

    @Test("basic struct promptRepresentation is valid JSON")
    func basicStructPromptRepresentation() throws {
        let json = #"{"name": "Alice", "age": 30}"#
        let content = try GeneratedContent(json: json)
        let person = try JSONTestPerson(content)
        assertValidJSON(textValue(of: person.promptRepresentation))
    }

    @Test("basic struct instructionsRepresentation is valid JSON")
    func basicStructInstructionsRepresentation() throws {
        let json = #"{"name": "Alice", "age": 30}"#
        let content = try GeneratedContent(json: json)
        let person = try JSONTestPerson(content)
        assertValidJSON(textValue(of: person.instructionsRepresentation))
    }

    @Test("Double properties produce valid JSON")
    func doublePropertiesJSON() throws {
        let json = #"{"x": 1.5, "y": -2.7}"#
        let content = try GeneratedContent(json: json)
        let point = try JSONTestPoint(content)
        assertValidJSON(point.generatedContent.jsonString)
        assertValidJSON(textValue(of: point.promptRepresentation))
        assertValidJSON(textValue(of: point.instructionsRepresentation))
    }

    @Test("@Guide annotated struct produces valid JSON")
    func guideAnnotatedStructJSON() throws {
        let json = #"{"name": "Widget", "price": 19.99, "inStock": true}"#
        let content = try GeneratedContent(json: json)
        let product = try JSONTestProduct(content)
        assertValidJSON(product.generatedContent.jsonString)
        assertValidJSON(textValue(of: product.promptRepresentation))
        assertValidJSON(textValue(of: product.instructionsRepresentation))
    }

    @Test("nested struct produces valid JSON")
    func nestedStructJSON() throws {
        let json = """
        {
            "name": "Acme Corp",
            "address": {"street": "123 Main", "city": "Tokyo", "zipCode": "100-0001"},
            "employees": [
                {"id": "e1", "name": "Taro", "department": "Engineering"},
                {"id": "e2", "name": "Hanako", "department": null}
            ]
        }
        """
        let content = try GeneratedContent(json: json)
        let company = try JSONTestCompany(content)
        assertValidJSON(company.generatedContent.jsonString)
        assertValidJSON(textValue(of: company.promptRepresentation))
        assertValidJSON(textValue(of: company.instructionsRepresentation))
    }

    @Test("optional properties produce valid JSON when present")
    func optionalPresentJSON() throws {
        let json = #"{"requiredString": "hello", "optionalString": "world", "optionalInt": 42}"#
        let content = try GeneratedContent(json: json)
        let fields = try JSONTestOptionalFields(content)
        assertValidJSON(fields.generatedContent.jsonString)
        assertValidJSON(textValue(of: fields.promptRepresentation))
        assertValidJSON(textValue(of: fields.instructionsRepresentation))
    }

    @Test("optional properties produce valid JSON when absent")
    func optionalAbsentJSON() throws {
        let json = #"{"requiredString": "hello"}"#
        let content = try GeneratedContent(json: json)
        let fields = try JSONTestOptionalFields(content)
        assertValidJSON(fields.generatedContent.jsonString)
        assertValidJSON(textValue(of: fields.promptRepresentation))
        assertValidJSON(textValue(of: fields.instructionsRepresentation))
    }
}

// MARK: - C. @Generable enum の JSON 出力検証

@Suite("Generable Enum JSON Output Validation", .tags(.foundation))
struct GenerableEnumJSONOutputTests {

    @Test("enum case produces valid JSON for promptRepresentation")
    func enumPromptJSON() throws {
        let json = #""active""#
        let content = try GeneratedContent(json: json)
        let status = try JSONTestStatus(content)
        assertValidJSON(textValue(of: status.promptRepresentation))
    }

    @Test("enum case produces valid JSON for instructionsRepresentation")
    func enumInstructionsJSON() throws {
        let json = #""inactive""#
        let content = try GeneratedContent(json: json)
        let status = try JSONTestStatus(content)
        assertValidJSON(textValue(of: status.instructionsRepresentation))
    }

    @Test("enum generatedContent.jsonString is valid JSON")
    func enumJSONString() throws {
        let json = #""pending""#
        let content = try GeneratedContent(json: json)
        let status = try JSONTestStatus(content)
        assertValidJSON(status.generatedContent.jsonString)
    }
}

// MARK: - D. ConvertibleToGeneratedContent デフォルト実装の検証

@Suite("ConvertibleToGeneratedContent Default Implementation Validation", .tags(.foundation))
struct ConvertibleToGeneratedContentDefaultTests {

    @Test("promptRepresentation matches jsonString")
    func promptMatchesJSONString() throws {
        let json = #"{"name": "Test", "age": 25}"#
        let content = try GeneratedContent(json: json)
        let person = try JSONTestPerson(content)
        let jsonString = person.generatedContent.jsonString
        let promptText = textValue(of: person.promptRepresentation)
        #expect(promptText == jsonString)
    }

    @Test("instructionsRepresentation matches jsonString")
    func instructionsMatchesJSONString() throws {
        let json = #"{"name": "Test", "age": 25}"#
        let content = try GeneratedContent(json: json)
        let person = try JSONTestPerson(content)
        let jsonString = person.generatedContent.jsonString
        let instructionsText = textValue(of: person.instructionsRepresentation)
        #expect(instructionsText == jsonString)
    }

    @Test("promptRepresentation and instructionsRepresentation are consistent")
    func promptAndInstructionsConsistent() throws {
        let json = """
        {
            "name": "Acme Corp",
            "address": {"street": "123 Main", "city": "Tokyo", "zipCode": "100-0001"},
            "employees": [{"id": "e1", "name": "Taro", "department": "Engineering"}]
        }
        """
        let content = try GeneratedContent(json: json)
        let company = try JSONTestCompany(content)
        let promptText = textValue(of: company.promptRepresentation)
        let instructionsText = textValue(of: company.instructionsRepresentation)
        #expect(promptText == instructionsText)
        assertValidJSON(promptText)
    }
}

// MARK: - E. ProtocolExtensions の JSON 出力検証

@Suite("ProtocolExtensions JSON Output Validation", .tags(.foundation))
struct ProtocolExtensionsJSONOutputTests {

    @Test("GeneratedContent.promptRepresentation produces valid JSON for structure")
    func generatedContentStructurePromptJSON() {
        let content = GeneratedContent(properties: [
            "key": "value",
            "count": 10,
        ])
        assertValidJSON(textValue(of: content.promptRepresentation))
    }

    @Test("GeneratedContent.instructionsRepresentation produces valid JSON for structure")
    func generatedContentStructureInstructionsJSON() {
        let content = GeneratedContent(properties: [
            "key": "value",
            "count": 10,
        ])
        assertValidJSON(textValue(of: content.instructionsRepresentation))
    }

    @Test("GeneratedContent.promptRepresentation produces valid JSON for array")
    func generatedContentArrayPromptJSON() {
        let content = GeneratedContent(elements: ["a", "b", "c"])
        assertValidJSON(textValue(of: content.promptRepresentation))
    }

    @Test("GeneratedContent.promptRepresentation produces valid JSON for scalar")
    func generatedContentScalarPromptJSON() {
        assertValidJSON(textValue(of: GeneratedContent(kind: .string("hello")).promptRepresentation))
        assertValidJSON(textValue(of: GeneratedContent(kind: .number(42)).promptRepresentation))
        assertValidJSON(textValue(of: GeneratedContent(kind: .bool(true)).promptRepresentation))
        assertValidJSON(textValue(of: GeneratedContent(kind: .null).promptRepresentation))
    }

    @Test("Bool promptRepresentation is valid JSON fragment")
    func boolPromptJSON() {
        assertValidJSON(textValue(of: true.promptRepresentation))
        assertValidJSON(textValue(of: false.promptRepresentation))
    }

    @Test("Bool instructionsRepresentation is valid JSON fragment")
    func boolInstructionsJSON() {
        assertValidJSON(textValue(of: true.instructionsRepresentation))
        assertValidJSON(textValue(of: false.instructionsRepresentation))
    }

    @Test("Int promptRepresentation is valid JSON fragment")
    func intPromptJSON() {
        assertValidJSON(textValue(of: 42.promptRepresentation))
        assertValidJSON(textValue(of: 0.promptRepresentation))
        assertValidJSON(textValue(of: (-1).promptRepresentation))
    }

    @Test("Int instructionsRepresentation is valid JSON fragment")
    func intInstructionsJSON() {
        assertValidJSON(textValue(of: 42.instructionsRepresentation))
    }

    @Test("Double promptRepresentation is valid JSON fragment")
    func doublePromptJSON() {
        assertValidJSON(textValue(of: 3.14.promptRepresentation))
        assertValidJSON(textValue(of: 0.0.promptRepresentation))
    }

    @Test("Double instructionsRepresentation is valid JSON fragment")
    func doubleInstructionsJSON() {
        assertValidJSON(textValue(of: 3.14.instructionsRepresentation))
    }

    @Test("Float promptRepresentation is valid JSON fragment")
    func floatPromptJSON() {
        assertValidJSON(textValue(of: Float(2.5).promptRepresentation))
    }

    @Test("Decimal promptRepresentation is valid JSON fragment")
    func decimalPromptJSON() {
        assertValidJSON(textValue(of: Decimal(123.456).promptRepresentation))
    }

    @Test("String promptRepresentation produces single text component")
    func stringPromptContent() {
        let value = "hello world"
        let prompt = value.promptRepresentation
        #expect(prompt.components == [.text(Prompt.Text(value: "hello world"))])
    }

    @Test("String instructionsRepresentation produces single text component")
    func stringInstructionsContent() {
        let value = "hello world"
        let instructions = value.instructionsRepresentation
        #expect(instructions.components == [.text(Instructions.Text(value: "hello world"))])
    }

    @Test("deeply nested structure round-trips through valid JSON")
    func deeplyNestedRoundTrip() throws {
        let inner = GeneratedContent(properties: [
            "deep": "value",
            "flag": true,
        ])
        let middle = GeneratedContent(properties: [
            "inner": inner,
            "list": GeneratedContent(elements: [1, 2, 3]),
        ])
        let outer = GeneratedContent(properties: [
            "middle": middle,
            "label": "top",
        ])

        let jsonString = outer.jsonString
        assertValidJSON(jsonString)

        let data = try #require(jsonString.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        let dict = try #require(parsed as? [String: Any])
        let middleDict = try #require(dict["middle"] as? [String: Any])
        let innerDict = try #require(middleDict["inner"] as? [String: Any])
        #expect(innerDict["deep"] as? String == "value")
    }

    @Test("special characters in keys and values produce valid JSON")
    func specialCharsInKeysAndValues() {
        let content = GeneratedContent(properties: [
            "key with spaces": "value\nwith\nnewlines",
            "quotes\"here": "tab\there",
        ])
        assertValidJSON(content.jsonString)
        assertValidJSON(content.debugDescription)
        assertValidJSON(textValue(of: content.promptRepresentation))
    }
}
