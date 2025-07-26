// ToolCallErrorAlias.swift
// OpenFoundationModels
//
// Type alias for backward compatibility

import Foundation

/// Type alias for backward compatibility
/// The actual type is now nested inside LanguageModelSession
/// as per Apple's Foundation Models specification
public typealias ToolCallError = LanguageModelSession.ToolCallError