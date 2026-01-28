//
//  Prompt+Extra.swift
//  OpenFoundationModelsExtra
//
//  Extended functionality for Prompt to provide convenient access
//  to internal properties for providers.
//

import Foundation
import OpenFoundationModelsCore

extension Prompt {
    /// Access to internal content for provider implementations
    /// - Note: This property provides direct access to the internal content string
    public var _content: String {
        return content
    }
}
