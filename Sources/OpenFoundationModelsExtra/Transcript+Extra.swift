//
//  Transcript+Extra.swift
//  OpenFoundationModelsExtra
//
//  Extended functionality for Transcript to provide convenient access
//  to internal properties for providers.
//

import Foundation
import OpenFoundationModels

extension Transcript {
    /// Access to internal entries for provider implementations
    /// - Note: This property provides direct access to the internal entries array
    public var _entries: [Entry] {
        return entries
    }
}

extension Transcript.ToolCalls {
    /// Access to internal calls array for tool processing
    /// - Note: This property provides direct access to the internal calls array
    public var _calls: [Transcript.ToolCall] {
        return calls
    }
}

extension Transcript.ResponseFormat {
    /// Access to internal type string for provider implementations
    /// - Note: This property provides direct access to the internal type string
    public var _type: String? {
        return type
    }

    /// Access to internal schema for provider implementations
    /// - Note: This property provides direct access to the internal schema
    public var _schema: GenerationSchema? {
        return schema
    }
}
