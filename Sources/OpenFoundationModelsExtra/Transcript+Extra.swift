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
