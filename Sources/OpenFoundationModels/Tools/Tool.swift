// Tool.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Based on Apple Foundation Models API specification

import Foundation

/// A tool that a model can call to gather information at runtime or perform side effects.
/// 
/// **Apple Foundation Models Documentation:**
/// Tool calling gives the model the ability to call your code to incorporate up-to-date information 
/// like recent events and data from your app. A tool includes a name and a description that the 
/// framework puts in the prompt to let the model decide when and how often to call your tool.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/tool
/// 
/// **Apple Official API:** `protocol Tool : Sendable`
/// 
/// **Conformances:**
/// - Sendable
/// - SendableMetatype
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Inheritance:**
/// - Sendable
/// - SendableMetatype
/// 
/// **Key Features:**
/// - Tools must conform to Sendable so the framework can run them concurrently
/// - If the model needs to pass the output of one tool as the input to another, it executes back-to-back tool calls
/// - You control the life cycle of your tool, so you can track the state of it between calls to the model
/// 
/// **Usage Example:**
/// ```swift
/// struct FindContacts: Tool {
///     let name = "findContacts"
///     let description = "Find a specific number of contacts"
///     
///     @Generable
///     struct Arguments {
///         @Guide(description: "The number of contacts to get", .range(1...10))
///         let count: Int
///     }
///     
///     // Define the output type
///     typealias Output = String
///     
///     func call(arguments: Arguments) async throws -> String {
///         var contacts: [CNContact] = []
///         // Fetch a number of contacts using the arguments.
///         let formattedContacts = contacts.map {
///             "\($0.givenName) \($0.familyName)"
///         }
///         return formattedContacts.joined(separator: ", ")
///     }
/// }
/// ```
public protocol Tool<Arguments, Output>: Sendable, SendableMetatype {
    /// The output that this tool produces for the language model to reason about in subsequent
    /// interactions.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// The output that this tool produces for the language model to reason about in subsequent interactions.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/output
    /// 
    /// **Apple Official API:** `associatedtype Output : PromptRepresentable`
    /// 
    /// **Required**
    /// 
    /// **Note:** Typically output is either a String or a Generable type.
    associatedtype Output: PromptRepresentable
    
    /// The arguments that this tool should accept.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// The arguments that this tool should accept.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/arguments
    /// 
    /// **Apple Official API:** `associatedtype Arguments : ConvertibleFromGeneratedContent`
    /// 
    /// **Required**
    /// 
    /// **Note:** Typically arguments are either a Generable type or GeneratedContent.
    associatedtype Arguments: ConvertibleFromGeneratedContent
    
    /// A unique name for the tool, such as "get_weather", "toggleDarkMode", or "search contacts".
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A unique name for the tool, such as "get_weather", "toggleDarkMode", or "search contacts".
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/name
    /// 
    /// **Apple Official API:** `var name: String`
    /// 
    /// **Required** - Default implementation provided.
    var name: String { get }
    
    /// A natural language description of when and how to use the tool.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A natural language description of when and how to use the tool.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/description
    /// 
    /// **Apple Official API:** `var description: String`
    /// 
    /// **Required**
    var description: String { get }
    
    /// If true, the model's name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// If true, the model's name, description, and parameters schema will be injected into the 
    /// instructions of sessions that leverage this tool.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/includesschemaininstructions
    /// 
    /// **Apple Official API:** `var includesSchemaInInstructions: Bool`
    /// 
    /// **Required** - Default implementation provided.
    var includesSchemaInInstructions: Bool { get }
    
    /// A schema for the parameters this tool accepts.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A schema for the parameters this tool accepts.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/parameters
    /// 
    /// **Apple Official API:** `var parameters: GenerationSchema`
    /// 
    /// **Required** - Default implementation provided.
    var parameters: GenerationSchema { get }
    
    /// A language model will call this method when it wants to leverage this tool.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A language model will call this method when it wants to leverage this tool.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/call(arguments:)
    /// 
    /// **Apple Official API:** `func call(arguments: Self.Arguments) async throws -> Self.Output`
    /// 
    /// **Required**
    /// 
    /// - Parameter arguments: The arguments for the tool call
    /// - Returns: The output of the tool execution
    /// - Throws: Any error that occurs during tool execution
    func call(arguments: Arguments) async throws -> Output
}


// MARK: - Default Implementations
/// **Apple Foundation Models Documentation:**
/// Default implementations for Tool protocol properties
extension Tool {
    /// A unique name for the tool, such as "get_weather", "toggleDarkMode", or "search contacts".
    /// 
    /// **Apple Foundation Models Documentation:**
    /// By default, uses the type name as the tool name.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/name
    /// 
    /// **Apple Official API:** Default implementation provided.
    public var name: String {
        return String(describing: type(of: self))
    }
    
    /// If true, the model's name, description, and parameters schema will be injected
    /// into the instructions of sessions that leverage this tool.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// The default implementation is `true`
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/includesschemaininstructions
    /// 
    /// **Apple Official API:** Default implementation provided.
    /// 
    /// **Note:** This should only be `false` if the model has been trained to have
    /// innate knowledge of this tool. For zero-shot prompting, it should always be `true`.
    public var includesSchemaInInstructions: Bool {
        return true
    }
}

// MARK: - Parameters Default Implementation for Generable Arguments
/// **Apple Foundation Models Documentation:**
/// Default implementation for parameters when Arguments conforms to Generable
extension Tool where Self.Arguments: Generable {
    /// A schema for the parameters this tool accepts.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Automatically generates a schema based on the tool's Arguments type when it conforms to Generable.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/parameters
    /// 
    /// **Apple Official API:** Default implementation provided for Generable Arguments.
    public var parameters: GenerationSchema {
        return Arguments.generationSchema
    }
}

// MARK: - Parameters Default Implementation for Non-Generable Arguments
/// **Apple Foundation Models Documentation:**
/// Default implementation for parameters when Arguments doesn't conform to Generable
extension Tool {
    /// A schema for the parameters this tool accepts.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Provides a basic object schema when Arguments doesn't conform to Generable.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/tool/parameters
    /// 
    /// **Apple Official API:** Default implementation provided.
    public var parameters: GenerationSchema {
        // Check if Arguments conforms to Generable at runtime
        if let generableType = Arguments.self as? any Generable.Type {
            return generableType.generationSchema
        }
        // Otherwise, return a basic object schema
        return GenerationSchema(
            type: "object",
            description: "Tool arguments for \(name)",
            properties: [:]
        )
    }
}

// MARK: - Protocol Implementation Notes
// ✅ PHASE 4.7: All Apple-required Tool protocol features implemented
// ✅ CONFIRMED: ToolOutput now implemented in Foundation/ToolOutput.swift
// ✅ CONFIRMED: Tool default implementations for includesSchemaInInstructions and parameters
// ✅ CONFIRMED: ConvertibleFromGeneratedContent protocol implemented
// ✅ CONFIRMED: GenerationSchema type implemented