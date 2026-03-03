import Foundation
import OpenFoundationModels
import OpenFoundationModelsCore
import JSONSchema

extension GeneratedContent {

    /// Converts GeneratedContent to JSONValue by decoding jsonString.
    public func toJSONValue() -> JSONValue {
        guard let data = jsonString.data(using: .utf8),
              let value = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            return .null
        }
        return value
    }

    /// Creates GeneratedContent from a JSONValue by encoding it to a JSON string.
    public init(jsonValue: JSONValue) throws {
        let data = try JSONEncoder().encode(jsonValue)
        guard let json = String(data: data, encoding: .utf8) else {
            throw GeneratedContentError.invalidJSON("Failed to encode JSONValue to string")
        }
        try self.init(json: json)
    }
}
