// Tool.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// Protocol for tools that can be called by language models
/// 
/// From Apple Documentation:
/// - Tools must conform to Sendable for concurrent execution
/// - Framework can run tools concurrently  
/// - Model can execute back-to-back tool calls
/// - Developer controls tool lifecycle and state between calls
public protocol Tool: Sendable {
    /// Associated type for tool arguments
    /// ✅ CONFIRMED: Must conform to ConvertibleFromGeneratedContent (NOT Generable)
    /// Note: Arguments typically are Generable types for schema generation
    associatedtype Arguments: ConvertibleFromGeneratedContent
    
    /// Tool name (has default implementation)
    var name: String { get }
    
    /// Tool description
    var description: String { get }
    
    /// Whether to include schema in instructions (has default implementation)  
    /// ❌ MISSING: Not implemented yet
    var includesSchemaInInstructions: Bool { get }
    
    /// Schema for the parameters this tool accepts (has default implementation)
    /// ❌ MISSING: Not implemented yet - requires GenerationSchema
    var parameters: GenerationSchema { get }
    
    /// Execute the tool
    func call(arguments: Arguments) async throws -> ToolOutput
}

// ✅ CONFIRMED: ToolOutput moved to separate file based on Apple specs
// See: Sources/OpenFoundationModels/Foundation/ToolOutput.swift

// 🚨 TYPE NAMESPACE CONFLICT RESOLVED:
// This top-level ToolCall is different from Transcript.ToolCall
// Renaming to avoid confusion with Apple's nested types

/// Represents a tool call request (top-level type)
/// ⚠️ INFERRED: Structure not confirmed from Apple docs
/// 🚨 NOTE: Different from Transcript.ToolCall (Apple's nested type)
public struct ToolCallRequest: Sendable {
    /// The name of the tool to call
    public let name: String
    
    /// The arguments for the tool (as JSON)
    public let arguments: String
    
    /// Unique identifier for this tool call
    public let id: String
    
    public init(name: String, arguments: String, id: String = UUID().uuidString) {
        self.name = name
        self.arguments = arguments
        self.id = id
    }
}

// MARK: - Default Implementations
extension Tool {
    /// Default implementation: include schema in instructions
    /// ✅ CONFIRMED: Apple specification shows this defaults to true
    public var includesSchemaInInstructions: Bool {
        return true
    }
    
    /// Default implementation: generate schema from Arguments type
    /// ✅ CONFIRMED: Apple specification shows this uses Arguments.generationSchema
    public var parameters: GenerationSchema {
        // If Arguments conforms to Generable, use its generationSchema
        if let generableType = Arguments.self as? any Generable.Type {
            return generableType.generationSchema
        }
        // Otherwise, create a basic schema
        return GenerationSchema(
            type: Arguments.self as! any Generable.Type,
            description: "Tool arguments for \(name)",
            properties: []
        )
    }
    
    /// Default implementation: use type name as tool name
    /// ✅ CONFIRMED: Apple specification shows this has default implementation
    public var name: String {
        return String(describing: type(of: self))
    }
}

// MARK: - Protocol Implementation Notes
// ✅ CONFIRMED: ToolOutput now implemented in Foundation/ToolOutput.swift
// ✅ CONFIRMED: Tool default implementations for includesSchemaInInstructions and parameters
// ❌ ConvertibleFromGeneratedContent protocol implementation needed
// ❌ GenerationSchema type implementation needed