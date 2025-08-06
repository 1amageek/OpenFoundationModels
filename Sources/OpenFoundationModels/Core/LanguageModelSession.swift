// LanguageModelSession.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import Foundation

/// A stateful session for interacting with a language model
/// 
/// ✅ CONFIRMED: Apple uses class (NOT actor) for LanguageModelSession
/// - Thread safety managed by the framework
/// - Observable for SwiftUI integration
/// - Multiple confirmed initializer patterns
/// - Supports both basic string and structured Generable responses
/// - Streaming and non-streaming methods
/// - Synchronous prewarm() method
public final class LanguageModelSession: Observable, @unchecked Sendable {
    
    /// The underlying language model
    /// ✅ CONFIRMED: Uses any LanguageModel for flexibility
    private var model: any LanguageModel
    
    /// Session instructions
    /// ✅ CONFIRMED: Instructions property exists
    public private(set) var instructions: Instructions?
    
    /// Available tools for the session
    /// ✅ CONFIRMED: Tools array property
    public private(set) var tools: [any Tool]
    
    /// Conversation transcript
    /// ✅ CONFIRMED: Transcript property
    public private(set) var transcript: Transcript
    
    /// Boolean value that indicates a response is being generated
    /// ✅ APPLE SPEC: isResponding property
    public private(set) var isResponding: Bool = false
    
    // MARK: - Apple Official Initializers
    
    /// Apple's official convenience initializer
    /// ✅ APPLE SPEC: convenience init(model:guardrails:tools:instructions:)
    public convenience init(
        model: any LanguageModel = SystemLanguageModel.default,
        guardrails: LanguageModelSession.Guardrails = .default,
        tools: [any Tool] = [],
        instructions: Instructions? = nil
    ) {
        self.init()
        self.model = model
        self.instructions = instructions
        self.tools = tools
        // Store guardrails and other parameters
        // Note: Guardrails implementation needed
    }
    
    /// Apple's official convenience initializer with transcript
    /// ✅ APPLE SPEC: convenience init(model:guardrails:tools:transcript:)
    public convenience init(
        model: any LanguageModel = SystemLanguageModel.default,
        guardrails: Guardrails = .default,
        tools: [any Tool] = [],
        transcript: Transcript
    ) {
        self.init()
        self.model = model
        self.tools = tools
        self.transcript = transcript
        // Store guardrails and other parameters
        // Note: Guardrails implementation needed
    }
    
    /// Initialize a new session (default)
    /// ✅ CONFIRMED: Default initializer
    public init() {
        self.model = SystemLanguageModel.default
        self.instructions = nil
        self.tools = []
        self.transcript = Transcript()
    }
    
    /// Initialize session with any LanguageModel
    /// ✅ PHASE 4.1: Dependency injection with LanguageModel protocol
    public init(model: any LanguageModel) {
        self.model = model
        self.instructions = nil
        self.tools = []
        self.transcript = Transcript()
    }
    
    /// Initialize session with instructions using result builder
    /// ✅ CONFIRMED: @InstructionsBuilder pattern from Apple docs
    public init(@InstructionsBuilder instructions: () -> String) {
        let instructionsText = instructions()
        self.model = SystemLanguageModel.default
        self.instructions = Instructions(instructionsText)
        self.tools = []
        self.transcript = Transcript()
    }
    
    
    // MARK: - Apple Official API Methods
    
    /// Apple's official respond method with closure-based prompt
    /// ✅ APPLE SPEC: func respond(options:isolation:prompt:) async throws -> sending Response<String>
    public func respond(
        options: GenerationOptions = .default,
        isolation: isolated (any Actor)? = nil,
        prompt: () throws -> Prompt
    ) async throws -> Response<String> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        let content = try await model.generate(prompt: promptText, options: options)
        
        // Create transcript entries
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: nil
            )
        )
        let responseEntry = Transcript.Entry.response(
            Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: content))]
            )
        )
        
        return Response(
            content: content,
            transcriptEntries: [promptEntry, responseEntry]
        )
    }
    
    /// Apple's official respond method with generic content generation
    /// ✅ APPLE SPEC: func respond<Content>(generating:options:includeSchemaInPrompt:isolation:prompt:) async throws -> sending Response<Content>
    public func respond<Content: Generable>(
        generating: Content.Type,
        options: GenerationOptions = .default,
        includeSchemaInPrompt: Bool = true,
        isolation: isolated (any Actor)? = nil,
        prompt: () throws -> Prompt
    ) async throws -> Response<Content> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        // Generate schema-guided content
        let schemaPrompt = includeSchemaInPrompt ? 
            "\(promptText)\n\nGenerate response following this schema: \(Content.generationSchema)" : 
            promptText
        
        let text = try await model.generate(prompt: schemaPrompt, options: options)
        let generatedContent = GeneratedContent(text)
        let content = try Content(generatedContent)
        
        // Create transcript entries
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: nil
            )
        )
        let responseEntry = Transcript.Entry.response(
            Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: "\(content)"))]
            )
        )
        
        return Response(
            content: content,
            transcriptEntries: [promptEntry, responseEntry]
        )
    }
    
    /// Apple's official respond method with schema-based generation
    /// ✅ APPLE SPEC: func respond(options:schema:includeSchemaInPrompt:isolation:prompt:) async throws -> Response<GeneratedContent>
    public func respond(
        options: GenerationOptions = .default,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        isolation: isolated (any Actor)? = nil,
        prompt: () throws -> Prompt
    ) async throws -> Response<GeneratedContent> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        // Generate schema-guided content
        let schemaPrompt = includeSchemaInPrompt ? 
            "\(promptText)\n\nGenerate response following this schema: \(schema)" : 
            promptText
        
        let text = try await model.generate(prompt: schemaPrompt, options: options)
        let content = GeneratedContent(text)
        
        // Create transcript entries
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: nil
            )
        )
        let responseEntry = Transcript.Entry.response(
            Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: "\(content)"))]
            )
        )
        
        return Response(
            content: content,
            transcriptEntries: [promptEntry, responseEntry]
        )
    }
    
    // MARK: - Convenience Methods (String-based)
    
    /// Convenience method for string-based prompts
    /// ✅ APPLE SPEC: func respond(to:options:isolation:) async throws -> sending Response<String>
    public func respond(
        to prompt: String,
        options: GenerationOptions = .default,
        isolation: isolated (any Actor)? = nil
    ) async throws -> Response<String> {
        return try await respond(options: options, isolation: isolation) {
            Prompt(prompt)
        }
    }
    
    /// Convenience method for string-based prompts with type generation
    /// ✅ APPLE SPEC: func respond(to:generating:includeSchemaInPrompt:options:isolation:) async throws -> Response<Content>
    public func respond<Content: Generable>(
        to prompt: String,
        generating: Content.Type,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .default,
        isolation: isolated (any Actor)? = nil
    ) async throws -> Response<Content> {
        return try await respond(
            generating: generating,
            options: options,
            includeSchemaInPrompt: includeSchemaInPrompt,
            isolation: isolation
        ) {
            Prompt(prompt)
        }
    }
    
    /// Convenience method for string-based prompts with schema
    /// ✅ APPLE SPEC: func respond(to:schema:includeSchemaInPrompt:options:isolation:) async throws -> Response<GeneratedContent>
    public func respond(
        to prompt: String,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .default,
        isolation: isolated (any Actor)? = nil
    ) async throws -> Response<GeneratedContent> {
        return try await respond(
            options: options,
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            isolation: isolation
        ) {
            Prompt(prompt)
        }
    }
    
    // MARK: - Legacy Methods (Deprecated)
    
    
    // MARK: - Apple Official Streaming API
    
    /// Apple's official stream response method with closure-based prompt
    /// ✅ APPLE SPEC: func streamResponse(options:prompt:) rethrows -> sending ResponseStream<String>
    public func streamResponse(
        options: GenerationOptions = .default,
        prompt: () throws -> Prompt
    ) rethrows -> ResponseStream<String> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        let stream = AsyncThrowingStream<Response<String>.Partial, Error> { continuation in
            Task {
                let stringStream = model.stream(prompt: promptText, options: options)
                var accumulatedContent = ""
                
                for await chunk in stringStream {
                    accumulatedContent += chunk
                    let partial = Response<String>.Partial(
                        content: accumulatedContent,
                        isComplete: false
                    )
                    continuation.yield(partial)
                }
                
                // Final complete partial
                let finalPartial = Response<String>.Partial(
                    content: accumulatedContent,
                    isComplete: true
                )
                continuation.yield(finalPartial)
                continuation.finish()
            }
        }
        
        return ResponseStream(stream: stream)
    }
    
    /// Apple's official stream response method with generic content generation
    /// ✅ APPLE SPEC: func streamResponse<Content>(generating:options:includeSchemaInPrompt:prompt:) rethrows -> sending ResponseStream<Content>
    public func streamResponse<Content: Generable>(
        generating: Content.Type,
        options: GenerationOptions = .default,
        includeSchemaInPrompt: Bool = true,
        prompt: () throws -> Prompt
    ) rethrows -> ResponseStream<Content> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        let stream = AsyncThrowingStream<Response<Content>.Partial, Error> { continuation in
            Task {
                let schemaPrompt = includeSchemaInPrompt ? 
                    "\(promptText)\n\nGenerate response following this schema: \(Content.generationSchema)" : 
                    promptText
                
                let stringStream = model.stream(prompt: schemaPrompt, options: options)
                var accumulatedText = ""
                
                for await chunk in stringStream {
                    accumulatedText += chunk
                    let partialContent = GeneratedContent(accumulatedText)
                    
                    // For now, create partial responses with string content
                    // TODO: Implement proper Generable partial parsing when needed
                    if let partialData = try? Content(partialContent) {
                        let partial = Response<Content>.Partial(
                            content: partialData,
                            isComplete: false
                        )
                        continuation.yield(partial)
                    }
                }
                
                // Final complete partial
                let finalContent = GeneratedContent(accumulatedText)
                if let finalData = try? Content(finalContent) {
                    let partial = Response<Content>.Partial(
                        content: finalData,
                        isComplete: true
                    )
                    continuation.yield(partial)
                }
                
                continuation.finish()
            }
        }
        
        return ResponseStream(stream: stream)
    }
    
    /// Apple's official stream response method with schema-based generation
    /// ✅ APPLE SPEC: func streamResponse(options:schema:includeSchemaInPrompt:prompt:) rethrows -> sending ResponseStream<GeneratedContent>
    public func streamResponse(
        options: GenerationOptions = .default,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        prompt: () throws -> Prompt
    ) rethrows -> ResponseStream<GeneratedContent> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        let stream = AsyncThrowingStream<Response<GeneratedContent>.Partial, Error> { continuation in
            Task {
                let schemaPrompt = includeSchemaInPrompt ? 
                    "\(promptText)\n\nGenerate response following this schema: \(schema)" : 
                    promptText
                
                let stringStream = model.stream(prompt: schemaPrompt, options: options)
                var accumulatedText = ""
                
                for await chunk in stringStream {
                    accumulatedText += chunk
                    let partialContent = GeneratedContent(accumulatedText)
                    
                    let partial = Response<GeneratedContent>.Partial(
                        content: partialContent,
                        isComplete: false
                    )
                    continuation.yield(partial)
                }
                
                // Final complete partial
                let finalContent = GeneratedContent(accumulatedText)
                let finalPartial = Response<GeneratedContent>.Partial(
                    content: finalContent,
                    isComplete: true
                )
                continuation.yield(finalPartial)
                continuation.finish()
            }
        }
        
        return ResponseStream(stream: stream)
    }
    
    // MARK: - Convenience Streaming Methods (String-based)
    
    /// Convenience method for string-based streaming prompts
    /// ✅ APPLE SPEC: func streamResponse(to:options:) -> ResponseStream<String>
    public func streamResponse(
        to prompt: String,
        options: GenerationOptions = .default
    ) -> ResponseStream<String> {
        return streamResponse(options: options) {
            Prompt(prompt)
        }
    }
    
    /// Convenience method for string-based streaming prompts with type generation
    /// ✅ APPLE SPEC: func streamResponse(to:generating:includeSchemaInPrompt:options:) -> ResponseStream<Content>
    public func streamResponse<Content: Generable>(
        to prompt: String,
        generating: Content.Type,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .default
    ) -> ResponseStream<Content> {
        return streamResponse(
            generating: generating,
            options: options,
            includeSchemaInPrompt: includeSchemaInPrompt
        ) {
            Prompt(prompt)
        }
    }
    
    /// Convenience method for string-based streaming prompts with schema
    /// ✅ APPLE SPEC: func streamResponse(to:schema:includeSchemaInPrompt:options:) -> ResponseStream<GeneratedContent>
    public func streamResponse(
        to prompt: String,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = .default
    ) -> ResponseStream<GeneratedContent> {
        return streamResponse(
            options: options,
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt
        ) {
            Prompt(prompt)
        }
    }
    
    
    // MARK: - Model Management
    
    /// Prewarm the model to reduce initial latency
    /// ✅ CONFIRMED: prewarm() method is synchronous (not async)
    public func prewarm() {
        // Implementation needed - model prewarming
        // This should prepare the model for faster response generation
    }
    
    /// Prewarm the model with a specific prompt and content type
    /// ✅ APPLE SPEC: prewarm<Content>(prompt:generating:) method
    public func prewarm<Content: Generable>(
        prompt: Prompt,
        generating: Content.Type
    ) {
        // Implementation needed - content-specific prewarming
        // This should prepare the model for the specific content type
    }
    
    /// Prewarm the model with a specific prompt and schema
    /// ✅ APPLE SPEC: prewarm(prompt:schema:) method
    public func prewarm(
        prompt: Prompt,
        schema: GenerationSchema?
    ) {
        // Implementation needed - schema-specific prewarming
        // This should prepare the model for the specific schema
    }
}

// MARK: - Nested Types

extension LanguageModelSession {
    
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
}

// MARK: - ToolCallError Error Description

extension LanguageModelSession.ToolCallError: LocalizedError {
    
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

// MARK: - ToolCallError Error Types

extension LanguageModelSession.ToolCallError {
    
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

// MARK: - ToolCallError Convenience Initializers

extension LanguageModelSession.ToolCallError {
    
    /// Create a tool not found error
    /// ✅ APPLE SPEC: Convenience initializer
    public static func toolNotFound(toolName: String) -> LanguageModelSession.ToolCallError {
        return LanguageModelSession.ToolCallError(
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
    public static func invalidArguments(toolName: String, reason: String) -> LanguageModelSession.ToolCallError {
        return LanguageModelSession.ToolCallError(
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
    public static func executionFailed(toolName: String, underlying: Error) -> LanguageModelSession.ToolCallError {
        return LanguageModelSession.ToolCallError(
            toolName: toolName,
            underlying: underlying,
            context: ["error_type": ErrorType.executionFailed.rawValue]
        )
    }
    
    /// Create a timeout error
    /// ✅ APPLE SPEC: Convenience initializer
    public static func timeout(toolName: String, timeoutSeconds: TimeInterval) -> LanguageModelSession.ToolCallError {
        return LanguageModelSession.ToolCallError(
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
    public static func permissionDenied(toolName: String, reason: String) -> LanguageModelSession.ToolCallError {
        return LanguageModelSession.ToolCallError(
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
    public static func unavailable(toolName: String, reason: String) -> LanguageModelSession.ToolCallError {
        return LanguageModelSession.ToolCallError(
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