import Foundation

/// Protocol for tools that can be called by language models
public protocol Tool: Sendable {
    /// The type of arguments this tool accepts
    associatedtype Arguments: Generable
    
    /// The name of the tool
    var name: String { get }
    
    /// A description of what the tool does
    var description: String { get }
    
    /// Execute the tool with the given arguments
    /// - Parameter arguments: The arguments for the tool
    /// - Returns: The output from the tool execution
    func call(arguments: Arguments) async throws -> ToolOutput
}

/// Output from a tool execution
public struct ToolOutput: Sendable {
    /// The content returned by the tool
    public let content: String
    
    /// Additional metadata about the execution
    public let metadata: [String: String]?
    
    public init(content: String, metadata: [String: String]? = nil) {
        self.content = content
        self.metadata = metadata
    }
}

/// Represents a tool call made by the language model
public struct ToolCall: Sendable {
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