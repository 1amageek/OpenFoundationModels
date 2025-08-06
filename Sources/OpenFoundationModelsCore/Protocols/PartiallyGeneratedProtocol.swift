// PartiallyGeneratedProtocol.swift
// OpenFoundationModels
//
// Protocol for partially generated content during streaming

import Foundation

/// A protocol that all PartiallyGenerated types conform to
/// 
/// **Apple Foundation Models Documentation:**
/// Protocol for tracking completion state of partially generated content
/// during streaming responses.
/// 
/// This protocol is used internally to provide a unified interface
/// for checking completion status across different PartiallyGenerated types.
public protocol PartiallyGeneratedProtocol: ConvertibleFromGeneratedContent {
    /// Indicates whether the content generation is complete
    var isComplete: Bool { get }
}