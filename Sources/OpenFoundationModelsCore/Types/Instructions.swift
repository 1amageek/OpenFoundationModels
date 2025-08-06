// Instructions.swift
// OpenFoundationModelsCore
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// Instructions define the model's intended behavior on prompts.
/// 
/// **Apple Foundation Models Documentation:**
/// Instructions are typically provided by you to define the role and behavior of the model.
/// Apple trains the model to obey instructions over any commands it receives in prompts,
/// so don't include untrusted content in instructions.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/instructions
/// 
/// **Apple Official API:** `struct Instructions`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - Copyable
/// - InstructionsRepresentable
/// 
/// **Usage:**
/// ```swift
/// // Simple instructions from string
/// let instructions = """
///     Suggest related topics. Keep them concise (three to seven words) and \
///     make sure they build naturally from the person's topic.
///     """
/// 
/// let session = LanguageModelSession(instructions: instructions)
/// 
/// // Dynamic instructions with builder
/// let instructions = Instructions {
///     "You are a helpful assistant."
///     if shouldBeVerbose {
///         "Provide detailed explanations for all responses."
///     }
/// }
/// ```
/// 
/// - Important: Apple trains the model to obey instructions over any commands it receives
///   in prompts, so don't include untrusted content in instructions.
public struct Instructions: Sendable {
    
    /// The internal content of the instructions
    internal let content: String
    
    /// Creates instructions from a string.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Instructions are typically provided by you to define the role and behavior of the model.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructions
    /// 
    /// - Parameter content: The string content of the instructions
    public init(_ content: String) {
        self.content = content
    }
    
    /// Creates instructions using a builder closure.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Use InstructionsBuilder to dynamically control the instructions' content based on your app's state.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructions/init(_:)
    /// 
    /// **Apple Official API:** `init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows`
    /// 
    /// - Parameter content: A builder closure that constructs the instructions
    public init(@InstructionsBuilder _ content: () throws -> Instructions) rethrows {
        let builtInstructions = try content()
        self.content = builtInstructions.content
    }
}

// MARK: - CustomStringConvertible

extension Instructions: CustomStringConvertible {
    /// A textual representation of the instructions.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Returns the content of the instructions as a string.
    public var description: String {
        return content
    }
}

// MARK: - InstructionsRepresentable

extension Instructions: InstructionsRepresentable {
    /// An instance that represents instructions.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Returns self since Instructions already represents instructions.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable/instructionsrepresentation
    public var instructionsRepresentation: Instructions {
        return self
    }
}