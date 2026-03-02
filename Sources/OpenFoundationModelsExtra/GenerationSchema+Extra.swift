//
//  GenerationSchema+Extra.swift
//  OpenFoundationModelsExtra
//
//  Extended functionality for GenerationSchema to provide convenient access
//  to internal properties for providers.
//

import Foundation
import OpenFoundationModelsCore

extension GenerationSchema {
    /// Access to JSON Schema dictionary representation for provider implementations
    /// - Note: This property provides direct access to the internal schema dictionary
    public var _jsonSchema: [String: Any] {
        return toSchemaDictionary()
    }
}
