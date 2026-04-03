//
//  GenerationSchema+Extra.swift
//  OpenFoundationModelsExtra
//
//  Extended functionality for GenerationSchema to provide convenient access
//  to internal properties for providers.
//

import Foundation
@_spi(Internal) import OpenFoundationModelsCore
import OpenFoundationModels
@_exported import JSONSchema

extension GenerationSchema {
    /// Type-safe JSON Schema representation for provider implementations.
    ///
    /// Converts the internal schema dictionary to a `JSONSchema` value.
    /// The dictionary from `toSchemaDictionary()` may contain `"type": ["X", "null"]`
    /// for optional properties, which mattt/JSONSchema cannot decode. This method
    /// normalizes such patterns to `"anyOf": [{"type": "X"}, {"type": "null"}]`
    /// before decoding.
    public var _jsonSchema: JSONSchema {
        var dict = toSchemaDictionary()
        GenerationSchema.normalizeForJSONSchema(&dict)
        let data = try! JSONSerialization.data(withJSONObject: dict as [String: Any])
        return try! JSONDecoder().decode(JSONSchema.self, from: data)
    }

    /// Recursively normalize a schema dictionary so that mattt/JSONSchema can decode it.
    ///
    /// Transforms `"type": ["X", "null"]` → `"anyOf": [{"type": "X", ...otherFields}, {"type": "null"}]`
    /// and recurses into `properties`, `items`, `anyOf`, `oneOf`, `allOf`.
    private static func normalizeForJSONSchema(_ dict: inout [String: any Sendable]) {
        // Convert "type": ["X", "null"] → anyOf
        if let typeArray = dict["type"] as? [String] {
            dict.removeValue(forKey: "type")

            // Collect extra fields that belong to the primary type schema
            var primarySchema: [String: any Sendable] = [:]
            let extraKeys: Set<String> = [
                "items", "minItems", "maxItems", "uniqueItems",
                "properties", "required", "additionalProperties",
                "minLength", "maxLength", "pattern", "format",
                "minimum", "maximum", "exclusiveMinimum", "exclusiveMaximum", "multipleOf",
                "enum",
            ]
            for key in extraKeys {
                if let value = dict[key] {
                    primarySchema[key] = value
                    dict.removeValue(forKey: key)
                }
            }

            var schemas: [[String: any Sendable]] = []
            for typeName in typeArray {
                if typeName == "null" {
                    schemas.append(["type": "null"])
                } else {
                    var schema: [String: any Sendable] = ["type": typeName]
                    for (k, v) in primarySchema {
                        schema[k] = v
                    }
                    schemas.append(schema)
                }
            }
            dict["anyOf"] = schemas
        }

        // Recursively normalize nested properties
        if var properties = dict["properties"] as? [String: any Sendable] {
            for (key, value) in properties {
                if var propDict = value as? [String: any Sendable] {
                    normalizeForJSONSchema(&propDict)
                    properties[key] = propDict
                }
            }
            dict["properties"] = properties
        }

        // Normalize items in array types
        if var items = dict["items"] as? [String: any Sendable] {
            normalizeForJSONSchema(&items)
            dict["items"] = items
        }

        // Normalize anyOf/oneOf/allOf arrays
        for key in ["anyOf", "oneOf", "allOf"] {
            if var schemas = dict[key] as? [[String: any Sendable]] {
                for i in schemas.indices {
                    normalizeForJSONSchema(&schemas[i])
                }
                dict[key] = schemas
            }
        }
    }
}
