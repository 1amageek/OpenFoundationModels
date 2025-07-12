// Instructions.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// Instructions define the model's intended behavior on prompts.
/// 
/// **Apple Foundation Models Documentation:**
/// Instructions define the model's intended behavior on prompts.
/// 
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
/// **Example:**
/// ```swift
/// let instructions = """
///  Suggest related topics. Keep them concise (three to seven words) and make sure they \
///  build naturally from the person's topic.
///  """
/// 
/// let session = LanguageModelSession(instructions: instructions)
/// 
/// let prompt = "Making homemade bread"
/// let response = try await session.respond(to: prompt)
/// ```
public struct Instructions: Copyable, InstructionsRepresentable {
    /// Text content of the instructions
    /// ✅ CONFIRMED: Apple specification requires text property
    public let text: String
    
    /// Creates instructions with text content.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates instructions with text content.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructions/init(_:)
    /// 
    /// **Apple Official API:** `init(_: String)`
    /// 
    /// - Parameter text: The instruction text that defines model behavior
    public init(_ text: String) {
        self.text = text
    }
    
    /// Initialize instructions with result builder
    /// - Parameter builder: Instructions builder closure
    public init(@InstructionsBuilder _ builder: () -> Instructions) {
        let instructions = builder()
        self.text = instructions.text
    }
}

// MARK: - Protocol Conformances

extension Instructions {
    /// An instance that represents the instructions.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An instance that represents the instructions.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable/instructionsrepresentation
    /// 
    /// **Apple Official API:** `var instructionsRepresentation: Instructions`
    public var instructionsRepresentation: Instructions {
        return self
    }
}