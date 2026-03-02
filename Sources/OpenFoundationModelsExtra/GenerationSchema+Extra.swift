//
//  GenerationSchema+Extra.swift
//  OpenFoundationModelsExtra
//
//  Extended functionality for GenerationSchema to provide convenient access
//  to internal properties for providers.
//

import Foundation
import OpenFoundationModelsCore
@_exported import JSONSchema

extension GenerationSchema {
    /// Type-safe JSON Schema representation for provider implementations.
    ///
    /// Converts the internal schema dictionary to a `JSONSchema` value.
    /// This conversion is guaranteed to succeed since the dictionary is
    /// constructed by `toSchemaDictionary()` which always produces valid JSON Schema.
    public var _jsonSchema: JSONSchema {
        let data = try! JSONSerialization.data(withJSONObject: toSchemaDictionary())
        return try! JSONDecoder().decode(JSONSchema.self, from: data)
    }
}
