import Foundation

/// An entry in a conversation transcript
public struct TranscriptEntry: Sendable {
    /// The role of the participant
    public let role: Role
    
    /// Text content (for user/assistant messages)
    public let content: String?
    
    /// Tool call information
    public let toolCall: ToolCall?
    
    /// Tool output (for tool responses)
    public let toolOutput: ToolOutput?
    
    /// Timestamp of the entry
    public let timestamp: Date
    
    /// Unique identifier for the entry
    public let id: String
    
    /// Initialize a transcript entry
    public init(
        role: Role,
        content: String? = nil,
        toolCall: ToolCall? = nil,
        toolOutput: ToolOutput? = nil,
        timestamp: Date = Date(),
        id: String = UUID().uuidString
    ) {
        self.role = role
        self.content = content
        self.toolCall = toolCall
        self.toolOutput = toolOutput
        self.timestamp = timestamp
        self.id = id
    }
    
    /// Roles in a conversation
    public enum Role: String, Sendable {
        case user
        case assistant
        case tool
        case system
    }
}

// MARK: - Convenience Initializers
extension TranscriptEntry {
    /// Create a user message entry
    public static func user(_ content: String) -> TranscriptEntry {
        TranscriptEntry(role: .user, content: content)
    }
    
    /// Create an assistant message entry
    public static func assistant(_ content: String) -> TranscriptEntry {
        TranscriptEntry(role: .assistant, content: content)
    }
    
    /// Create a tool call entry
    public static func toolCall(_ toolCall: ToolCall) -> TranscriptEntry {
        TranscriptEntry(role: .assistant, toolCall: toolCall)
    }
    
    /// Create a tool response entry
    public static func toolResponse(_ output: ToolOutput, for toolCallId: String) -> TranscriptEntry {
        TranscriptEntry(role: .tool, toolOutput: output)
    }
}