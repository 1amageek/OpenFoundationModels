// TypeAliases.swift
// OpenFoundationModels
//
// Type aliases for backward compatibility with Apple Foundation Models API

import Foundation

// MARK: - Type Aliases for Nested Types

/// Type alias for LanguageModelSession.Response for backward compatibility
/// ✅ APPLE SPEC: Response is a nested type within LanguageModelSession
public typealias Response = LanguageModelSession.Response

/// Type alias for LanguageModelSession.ResponseStream for backward compatibility
/// ✅ APPLE SPEC: ResponseStream is a nested type within LanguageModelSession
public typealias ResponseStream = LanguageModelSession.ResponseStream

/// Type alias for LanguageModelSession.GenerationError for backward compatibility
/// ✅ APPLE SPEC: GenerationError is a nested type within LanguageModelSession
public typealias GenerationError = LanguageModelSession.GenerationError