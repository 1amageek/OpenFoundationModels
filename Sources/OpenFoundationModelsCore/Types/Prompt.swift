// Prompt.swift
// OpenFoundationModelsCore
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// A prompt from a person to the model.
/// 
/// **Apple Foundation Models Documentation:**
/// Prompts can contain content written by you, an outside source, or input directly
/// from people using your app. You can initialize a Prompt from a string literal.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/prompt
/// 
/// **Apple Official API:** `struct Prompt`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - Copyable
/// - PromptRepresentable
/// - Sendable
/// 
/// **Usage:**
/// ```swift
/// // Simple prompt from string
/// let prompt = Prompt("What are miniature schnauzers known for?")
/// 
/// // Dynamic prompt with builder
/// let responseShouldRhyme = true
/// let prompt = Prompt {
///     "Answer the following question from the user: \(userInput)"
///     if responseShouldRhyme {
///         "Your response MUST rhyme!"
///     }
/// }
/// ```
public struct Prompt: Sendable {
    
    /// The internal content of the prompt
    internal let content: String
    
    /// Creates a prompt from a string.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// You can initialize a Prompt from a string literal.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/prompt
    /// 
    /// - Parameter content: The string content of the prompt
    public init(_ content: String) {
        self.content = content
    }
    
    /// Creates a prompt using a builder closure.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Use PromptBuilder to dynamically control the prompt's content based on your app's state.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/prompt/init(_:)
    /// 
    /// **Apple Official API:** `init(@PromptBuilder _ content: () throws -> Prompt) rethrows`
    /// 
    /// - Parameter content: A builder closure that constructs the prompt
    public init(@PromptBuilder _ content: () throws -> Prompt) rethrows {
        let builtPrompt = try content()
        self.content = builtPrompt.content
    }
}

// MARK: - CustomStringConvertible

extension Prompt: CustomStringConvertible {
    /// A textual representation of the prompt.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Returns the content of the prompt as a string.
    public var description: String {
        return content
    }
}

// MARK: - PromptRepresentable

extension Prompt: PromptRepresentable {
    /// An instance that represents a prompt.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Returns self since Prompt already represents a prompt.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/promptrepresentable/promptrepresentation
    public var promptRepresentation: Prompt {
        return self
    }
}