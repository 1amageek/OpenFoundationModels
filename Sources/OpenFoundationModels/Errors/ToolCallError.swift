import Foundation

/// An error that occurs while a system language model is calling a tool
/// ✅ APPLE SPEC: LanguageModelSession.ToolCallError structure
/// Referenced in Apple Foundation Models documentation
public struct ToolCallError: Error, Sendable {
    
    /// The name of the tool that caused the error
    /// ✅ APPLE SPEC: toolName property
    public let toolName: String
    
    /// The underlying error that occurred
    /// ✅ APPLE SPEC: underlying error
    public let underlying: Error
    
    /// Additional context about the error
    /// ✅ APPLE SPEC: context information
    public let context: [String: String]
    
    /// Initialize a tool call error
    /// ✅ APPLE SPEC: Standard initializer
    /// - Parameters:
    ///   - toolName: The name of the tool that caused the error
    ///   - underlying: The underlying error
    ///   - context: Additional context information
    public init(
        toolName: String,
        underlying: Error,
        context: [String: String] = [:]
    ) {
        self.toolName = toolName
        self.underlying = underlying
        self.context = context
    }
}

// MARK: - Error Description

extension ToolCallError: LocalizedError {
    
    /// A localized message describing what error occurred
    /// ✅ APPLE SPEC: Error description for debugging
    public var errorDescription: String? {
        return "Tool call error in '\(toolName)': \(underlying.localizedDescription)"
    }
    
    /// A localized message describing the reason for the failure
    /// ✅ APPLE SPEC: Failure reason for debugging
    public var failureReason: String? {
        return "The tool '\(toolName)' failed to execute properly: \(underlying.localizedDescription)"
    }
    
    /// A localized message describing how one might recover from the failure
    /// ✅ APPLE SPEC: Recovery suggestion for users
    public var recoverySuggestion: String? {
        return "Check the tool configuration and arguments, then try again."
    }
}

// MARK: - Error Types

extension ToolCallError {
    
    /// Specific types of tool call errors
    /// ✅ APPLE SPEC: Error categorization
    public enum ErrorType: String, Sendable {
        /// Tool not found
        case toolNotFound = "tool_not_found"
        
        /// Invalid arguments provided to the tool
        case invalidArguments = "invalid_arguments"
        
        /// Tool execution failed
        case executionFailed = "execution_failed"
        
        /// Tool timed out
        case timeout = "timeout"
        
        /// Tool returned invalid output
        case invalidOutput = "invalid_output"
        
        /// Permission denied for tool execution
        case permissionDenied = "permission_denied"
        
        /// Tool is temporarily unavailable
        case unavailable = "unavailable"
    }
    
    /// The type of error that occurred
    /// ✅ APPLE SPEC: Error type classification
    public var errorType: ErrorType {
        // Try to determine error type from context or underlying error
        if let typeString = context["error_type"],
           let type = ErrorType(rawValue: typeString) {
            return type
        }
        
        // Fallback to analyzing the underlying error
        let description = underlying.localizedDescription.lowercased()
        
        if description.contains("not found") {
            return .toolNotFound
        } else if description.contains("invalid") || description.contains("argument") {
            return .invalidArguments
        } else if description.contains("timeout") {
            return .timeout
        } else if description.contains("permission") || description.contains("denied") {
            return .permissionDenied
        } else if description.contains("unavailable") {
            return .unavailable
        } else {
            return .executionFailed
        }
    }
}

// MARK: - Convenience Initializers

extension ToolCallError {
    
    /// Create a tool not found error
    /// ✅ APPLE SPEC: Convenience initializer
    public static func toolNotFound(toolName: String) -> ToolCallError {
        return ToolCallError(
            toolName: toolName,
            underlying: NSError(
                domain: "ToolCallError",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Tool '\(toolName)' not found"]
            ),
            context: ["error_type": ErrorType.toolNotFound.rawValue]
        )
    }
    
    /// Create an invalid arguments error
    /// ✅ APPLE SPEC: Convenience initializer
    public static func invalidArguments(toolName: String, reason: String) -> ToolCallError {
        return ToolCallError(
            toolName: toolName,
            underlying: NSError(
                domain: "ToolCallError",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid arguments for tool '\(toolName)': \(reason)"]
            ),
            context: ["error_type": ErrorType.invalidArguments.rawValue, "reason": reason]
        )
    }
    
    /// Create an execution failed error
    /// ✅ APPLE SPEC: Convenience initializer
    public static func executionFailed(toolName: String, underlying: Error) -> ToolCallError {
        return ToolCallError(
            toolName: toolName,
            underlying: underlying,
            context: ["error_type": ErrorType.executionFailed.rawValue]
        )
    }
    
    /// Create a timeout error
    /// ✅ APPLE SPEC: Convenience initializer
    public static func timeout(toolName: String, timeoutSeconds: TimeInterval) -> ToolCallError {
        return ToolCallError(
            toolName: toolName,
            underlying: NSError(
                domain: "ToolCallError",
                code: 408,
                userInfo: [NSLocalizedDescriptionKey: "Tool '\(toolName)' timed out after \(timeoutSeconds) seconds"]
            ),
            context: [
                "error_type": ErrorType.timeout.rawValue,
                "timeout_seconds": String(timeoutSeconds)
            ]
        )
    }
    
    /// Create a permission denied error
    /// ✅ APPLE SPEC: Convenience initializer
    public static func permissionDenied(toolName: String, reason: String) -> ToolCallError {
        return ToolCallError(
            toolName: toolName,
            underlying: NSError(
                domain: "ToolCallError",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Permission denied for tool '\(toolName)': \(reason)"]
            ),
            context: ["error_type": ErrorType.permissionDenied.rawValue, "reason": reason]
        )
    }
    
    /// Create an unavailable error
    /// ✅ APPLE SPEC: Convenience initializer
    public static func unavailable(toolName: String, reason: String) -> ToolCallError {
        return ToolCallError(
            toolName: toolName,
            underlying: NSError(
                domain: "ToolCallError",
                code: 503,
                userInfo: [NSLocalizedDescriptionKey: "Tool '\(toolName)' is unavailable: \(reason)"]
            ),
            context: ["error_type": ErrorType.unavailable.rawValue, "reason": reason]
        )
    }
}