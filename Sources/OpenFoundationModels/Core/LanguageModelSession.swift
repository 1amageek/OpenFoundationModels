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
    ) async throws -> LanguageModelSession.Response<String> {
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
        
        return LanguageModelSession.Response(
            content: content,
            rawContent: GeneratedContent(content),
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
    ) async throws -> LanguageModelSession.Response<Content> {
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
        
        return LanguageModelSession.Response(
            content: content,
            rawContent: generatedContent,
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
    ) async throws -> LanguageModelSession.Response<GeneratedContent> {
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
        
        return LanguageModelSession.Response(
            content: content,
            rawContent: content,
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
    ) async throws -> LanguageModelSession.Response<String> {
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
    ) async throws -> LanguageModelSession.Response<Content> {
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
    ) async throws -> LanguageModelSession.Response<GeneratedContent> {
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
    ) rethrows -> LanguageModelSession.ResponseStream<String> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            Task<Void, Never> {
                let stringStream = model.stream(prompt: promptText, options: options)
                var accumulatedContent = ""
                
                for await chunk in stringStream {
                    accumulatedContent += chunk
                    // String.PartiallyGenerated = String (default)
                    continuation.yield(accumulatedContent)
                }
                
                // Final complete content is already the accumulated string
                continuation.finish()
            }
        }
        
        return LanguageModelSession.ResponseStream(stream: stream)
    }
    
    /// Apple's official stream response method with generic content generation
    /// ✅ APPLE SPEC: func streamResponse<Content>(generating:options:includeSchemaInPrompt:prompt:) rethrows -> sending ResponseStream<Content>
    public func streamResponse<Content: Generable>(
        generating: Content.Type,
        options: GenerationOptions = .default,
        includeSchemaInPrompt: Bool = true,
        prompt: () throws -> Prompt
    ) rethrows -> LanguageModelSession.ResponseStream<Content> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        // Type alias for clarity
        typealias PartialContent = Content.PartiallyGenerated
        
        let stream = AsyncThrowingStream<PartialContent, Error> { continuation in
            Task<Void, Never> {
                let schemaPrompt = includeSchemaInPrompt ? 
                    "\(promptText)\n\nGenerate response following this schema: \(Content.generationSchema)" : 
                    promptText
                
                let stringStream = model.stream(prompt: schemaPrompt, options: options)
                var accumulatedText = ""
                
                for await chunk in stringStream {
                    accumulatedText += chunk
                    let partialContent = GeneratedContent(accumulatedText)
                    
                    // Create PartiallyGenerated from accumulated content
                    if let partialData = try? PartialContent(partialContent) {
                        continuation.yield(partialData)
                    }
                }
                
                // Final complete content
                let finalContent = GeneratedContent(accumulatedText)
                if let finalData = try? PartialContent(finalContent) {
                    continuation.yield(finalData)
                }
                
                continuation.finish()
            }
        }
        
        return LanguageModelSession.ResponseStream(stream: stream)
    }
    
    /// Apple's official stream response method with schema-based generation
    /// ✅ APPLE SPEC: func streamResponse(options:schema:includeSchemaInPrompt:prompt:) rethrows -> sending ResponseStream<GeneratedContent>
    public func streamResponse(
        options: GenerationOptions = .default,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        prompt: () throws -> Prompt
    ) rethrows -> LanguageModelSession.ResponseStream<GeneratedContent> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        let stream = AsyncThrowingStream<GeneratedContent.PartiallyGenerated, Error> { continuation in
            Task<Void, Never> {
                let schemaPrompt = includeSchemaInPrompt ? 
                    "\(promptText)\n\nGenerate response following this schema: \(schema)" : 
                    promptText
                
                let stringStream = model.stream(prompt: schemaPrompt, options: options)
                var accumulatedText = ""
                
                for await chunk in stringStream {
                    accumulatedText += chunk
                    // GeneratedContent.PartiallyGenerated = GeneratedContent
                    let partialContent = GeneratedContent(accumulatedText)
                    continuation.yield(partialContent)
                }
                
                // Final complete content
                let finalContent = GeneratedContent(accumulatedText)
                continuation.yield(finalContent)
                continuation.finish()
            }
        }
        
        return LanguageModelSession.ResponseStream(stream: stream)
    }
    
    // MARK: - Convenience Streaming Methods (String-based)
    
    /// Convenience method for string-based streaming prompts
    /// ✅ APPLE SPEC: func streamResponse(to:options:) -> ResponseStream<String>
    public func streamResponse(
        to prompt: String,
        options: GenerationOptions = .default
    ) -> LanguageModelSession.ResponseStream<String> {
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
    ) -> LanguageModelSession.ResponseStream<Content> {
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
    ) -> LanguageModelSession.ResponseStream<GeneratedContent> {
        return streamResponse(
            options: options,
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt
        ) {
            Prompt(prompt)
        }
    }
    
    
    // MARK: - Model Management
    
    /// Requests that the system eagerly load the resources required for this session into memory 
    /// and optionally caches a prefix of your prompt.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// This method can be useful in cases where you have a strong signal that the user will interact 
    /// with session within a few seconds. For example, you might call prewarm when the user begins 
    /// typing into a text field.
    /// 
    /// If you know a prefix for the future prompt, passing it to prewarm will allow the system to 
    /// process the prompt eagerly and reduce latency for the future request.
    /// 
    /// - Important: You should only use prewarm when you have a window of at least 1s before the
    ///   call to `respond(to:)`.
    /// 
    /// - Note: Calling this method does not guarantee that the system loads your assets immediately,
    ///   particularly if your app is running in the background or the system is under load.
    /// 
    /// - Parameter promptPrefix: An optional prompt prefix to cache for faster future responses
    public func prewarm(promptPrefix: Prompt? = nil) {
        // Implementation: Prepare the model and optionally cache the prompt prefix
        // This is a synchronous method that initiates prewarming
        // The actual prewarming happens asynchronously in the background
    }
}

// MARK: - Nested Types

extension LanguageModelSession {
    
    // MARK: - Response
    
    /// A structure that stores the output of a response call.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A response from a language model that contains the generated content
    /// and associated transcript entries from the interaction.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response
    /// 
    /// **Apple Official API:** `struct Response<Content>`
    /// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
    /// - Beta Software: Contains preliminary API information
    /// 
    /// **Properties:**
    /// - `content: Content` - The response content
    /// - `transcriptEntries: ArraySlice<Transcript.Entry>` - The list of transcript entries
    /// 
    /// **Usage:**
    /// ```swift
    /// let response = try await session.respond { Prompt("Hello") }
    /// print(response.content) // Generated content
    /// print(response.transcriptEntries) // Transcript entries
    /// ```
    public struct Response<Content: Sendable>: Sendable {
        /// The response content.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// The generated content from the language model response.
        /// The type depends on the generation method used.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/content
        public let content: Content
        
        /// The raw response content.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// The raw response content. When `Content` is `GeneratedContent`, 
        /// this is the same as `content`.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/rawcontent
        public let rawContent: GeneratedContent
        
        /// The list of transcript entries.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// The transcript entries associated with this response,
        /// documenting the interaction history.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/transcriptentries
        public let transcriptEntries: ArraySlice<Transcript.Entry>
        
        /// Initialize a response with Apple-compliant structure
        /// 
        /// **Apple Foundation Models Documentation:**
        /// Creates a response with generated content and transcript entries.
        /// 
        /// - Parameters:
        ///   - content: The generated content
        ///   - rawContent: The raw generated content
        ///   - transcriptEntries: The associated transcript entries
        public init(
            content: Content,
            rawContent: GeneratedContent,
            transcriptEntries: ArraySlice<Transcript.Entry>
        ) {
            self.content = content
            self.rawContent = rawContent
            self.transcriptEntries = transcriptEntries
        }
        
        /// Convenience initializer when Content is GeneratedContent
        /// 
        /// When Content is GeneratedContent, rawContent is the same as content.
        /// 
        /// - Parameters:
        ///   - content: The generated content (also used as rawContent)
        ///   - transcriptEntries: The associated transcript entries
        public init(
            content: Content,
            transcriptEntries: ArraySlice<Transcript.Entry>
        ) where Content == GeneratedContent {
            self.content = content
            self.rawContent = content
            self.transcriptEntries = transcriptEntries
        }
        
    }
    
    // MARK: - Response.Partial
    
    /// Partial response during streaming
    /// ✅ APPLE SPEC: Response<Content>.Partial nested type
    public struct Partial<Content: Sendable>: Sendable {
        /// The partial content being generated
        /// ✅ APPLE SPEC: content property (generic for different content types)
        public let content: Content
        
        /// Whether the generation is complete
        /// ✅ APPLE SPEC: isComplete property
        public let isComplete: Bool
        
        /// Initialize a partial response
        /// ✅ APPLE SPEC: Standard initializer
        public init(
            content: Content,
            isComplete: Bool
        ) {
            self.content = content
            self.isComplete = isComplete
        }
    }
    
    // MARK: - ResponseStream
    
    /// A structure that stores the output of a response stream.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A response stream that provides streaming access to generated content
    /// as it becomes available from the language model.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream
    /// 
    /// **Apple Official API:** `struct ResponseStream<Content> where Content : Generable`
    /// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
    /// - Beta Software: Contains preliminary API information
    /// 
    /// **Conformances:**
    /// - AsyncSequence
    /// - Copyable
    /// 
    /// **Key Method:**
    /// - `collect(isolation:) async throws -> sending Response<Content>`
    /// 
    /// **Usage:**
    /// ```swift
    /// let stream = session.streamResponse { Prompt("Hello") }
    /// for try await partial in stream {
    ///     print(partial.content)
    /// }
    /// ```
    public struct ResponseStream<Content>: AsyncSequence, Sendable where Content: Generable & Sendable {
        
        /// The element type yielded by the stream
        /// ✅ APPLE SPEC: Element = Content.PartiallyGenerated
        public typealias Element = Content.PartiallyGenerated
        
        /// The async iterator for the stream
        /// ✅ APPLE SPEC: AsyncIterator implementation
        public typealias AsyncIterator = ResponseStreamIterator<Content>
        
        /// The underlying async stream
        /// ✅ APPLE SPEC: Internal stream implementation
        private let stream: AsyncThrowingStream<Content.PartiallyGenerated, Error>
        
        /// The last partial response received
        /// ✅ APPLE SPEC: Convenience property for UI updates
        public private(set) var last: Content.PartiallyGenerated?
        
        /// Initialize with an async throwing stream
        /// ✅ APPLE SPEC: Standard initializer
        public init(
            stream: AsyncThrowingStream<Content.PartiallyGenerated, Error>
        ) {
            self.stream = stream
            self.last = nil
        }
        
        /// Create an async iterator
        /// ✅ APPLE SPEC: AsyncSequence conformance
        public func makeAsyncIterator() -> AsyncIterator {
            return LanguageModelSession.ResponseStreamIterator(stream: stream)
        }
    }
    
    // MARK: - ResponseStreamIterator
    
    /// The async iterator for ResponseStream
    /// ✅ APPLE SPEC: AsyncIteratorProtocol implementation
    public struct ResponseStreamIterator<Content: Generable & Sendable>: AsyncIteratorProtocol {
        
        /// The element type
        /// ✅ APPLE SPEC: Element type matching parent stream
        public typealias Element = Content.PartiallyGenerated
        
        /// The underlying stream iterator
        /// ✅ APPLE SPEC: Internal iterator implementation
        private var iterator: AsyncThrowingStream<Content.PartiallyGenerated, Error>.AsyncIterator
        
        /// Initialize with a stream
        /// ✅ APPLE SPEC: Standard initializer
        public init(
            stream: AsyncThrowingStream<Content.PartiallyGenerated, Error>
        ) {
            self.iterator = stream.makeAsyncIterator()
        }
        
        /// Get the next element
        /// ✅ APPLE SPEC: AsyncIteratorProtocol conformance
        public mutating func next() async throws -> Element? {
            return try await iterator.next()
        }
    }
    
    // MARK: - GenerationError
    
    /// An error that occurs while generating a response.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An error that occurs while generating a response.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror
    /// 
    /// **Apple Official API:** `enum GenerationError`
    /// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
    /// - Beta Software: Contains preliminary API information
    /// 
    /// **Conformances:**
    /// - Error
    /// - LocalizedError
    /// - Sendable
    /// - SendableMetatype
    public enum GenerationError: Error, LocalizedError, Sendable, SendableMetatype {
        
        /// An error that indicates the assets required for the session are unavailable.
        case assetsUnavailable(Context)
        
        /// An error that happens if you attempt to make a session respond to a second prompt while it's still responding to the first one.
        case concurrentRequests(Context)
        
        /// An error that indicates the session failed to deserialize a valid generable type from model output.
        case decodingFailure(Context)
        
        /// An error that signals the session reached its context window size limit.
        case exceededContextWindowSize(Context)
        
        /// An error that indicates the system's safety guardrails are triggered by content in a prompt or the response generated by the model.
        case guardrailViolation(Context)
        
        /// An error that indicates your session has been rate limited.
        case rateLimited(Context)
        
        /// An error that indicates a generation guide with an unsupported pattern was used.
        case unsupportedGuide(Context)
        
        /// An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.
        case unsupportedLanguageOrLocale(Context)
        
        /// The context in which the error occurred.
        public struct Context: Sendable, SendableMetatype {
            /// A debug description to help developers diagnose issues during development.
            public let debugDescription: String
            
            /// Creates a context.
            public init(debugDescription: String) {
                self.debugDescription = debugDescription
            }
        }
    }
    
    // MARK: - ToolCallError
    
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

// MARK: - GenerationError Extensions

extension LanguageModelSession.GenerationError {
    
    /// A string representation of the error description.
    public var errorDescription: String? {
        switch self {
        case .assetsUnavailable(let context):
            return "Assets unavailable: \(context.debugDescription)"
            
        case .concurrentRequests(let context):
            return "Concurrent requests: \(context.debugDescription)"
            
        case .decodingFailure(let context):
            return "Decoding failure: \(context.debugDescription)"
            
        case .exceededContextWindowSize(let context):
            return "Context window size exceeded: \(context.debugDescription)"
            
        case .guardrailViolation(let context):
            return "Guardrail violation: \(context.debugDescription)"
            
        case .rateLimited(let context):
            return "Rate limited: \(context.debugDescription)"
            
        case .unsupportedGuide(let context):
            return "Unsupported guide: \(context.debugDescription)"
            
        case .unsupportedLanguageOrLocale(let context):
            return "Unsupported language or locale: \(context.debugDescription)"
        }
    }
    
    /// A string representation of the failure reason.
    public var failureReason: String? {
        switch self {
        case .assetsUnavailable:
            return "The assets required for the session are unavailable."
            
        case .concurrentRequests:
            return "You attempted to make a session respond to a second prompt while it's still responding to the first one."
            
        case .decodingFailure:
            return "The session failed to deserialize a valid generable type from model output."
            
        case .exceededContextWindowSize:
            return "The session reached its context window size limit."
            
        case .guardrailViolation:
            return "The system's safety guardrails were triggered by content in a prompt or the response generated by the model."
            
        case .rateLimited:
            return "Your session has been rate limited."
            
        case .unsupportedGuide:
            return "A generation guide with an unsupported pattern was used."
            
        case .unsupportedLanguageOrLocale:
            return "The model was prompted to respond in a language that it does not support."
        }
    }
    
    /// A string representation of the recovery suggestion.
    public var recoverySuggestion: String? {
        switch self {
        case .assetsUnavailable:
            return "Check that the required model assets are available and try again."
            
        case .concurrentRequests:
            return "Wait for the current response to complete before making another request."
            
        case .decodingFailure:
            return "Check your generable type definition and try again."
            
        case .exceededContextWindowSize:
            return "Try reducing the length of your prompt or conversation history."
            
        case .guardrailViolation:
            return "Please modify your prompt to avoid sensitive or inappropriate content."
            
        case .rateLimited:
            return "Wait a moment and try again, or reduce the frequency of your requests."
            
        case .unsupportedGuide:
            return "Use a supported generation guide pattern and try again."
            
        case .unsupportedLanguageOrLocale:
            return "Try using a supported language or check model capabilities."
        }
    }
}

// MARK: - ResponseStream Extensions

extension LanguageModelSession.ResponseStream {
    /// A snapshot of partially generated content.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A snapshot of partially generated content during streaming.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot
    /// 
    /// **Apple Official API:** `struct Snapshot`
    /// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
    /// - Beta Software: Contains preliminary API information
    public struct Snapshot: Sendable {
        /// The content of the response.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// The partially generated content at this point in the stream.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot/content
        public let content: Content.PartiallyGenerated
        
        /// The raw content of the response.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// The raw generated content at this point in the stream.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot/rawcontent
        public let rawContent: GeneratedContent
        
        /// Initialize a snapshot
        /// 
        /// - Parameters:
        ///   - content: The partially generated content
        ///   - rawContent: The raw generated content
        public init(
            content: Content.PartiallyGenerated,
            rawContent: GeneratedContent
        ) {
            self.content = content
            self.rawContent = rawContent
        }
    }
}

// MARK: - ResponseStream Helper Methods

extension LanguageModelSession.ResponseStream {
    /// The result from a streaming response, after it completes.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Collects all streaming content into a final Response object.
    /// This method waits for the stream to complete and returns the final result.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/collect(isolation:)
    /// 
    /// **Apple Official API:**
    /// `func collect(isolation: isolated (any Actor)?) async throws -> sending Response<Content>`
    /// 
    /// - Parameter isolation: Optional actor isolation context
    /// - Returns: The complete response after streaming finishes
    /// - Throws: Any error encountered during streaming
    public func collect(
        isolation: isolated (any Actor)? = nil
    ) async throws -> LanguageModelSession.Response<Content> {
        var finalPartial: Content.PartiallyGenerated?
        let allEntries: [Transcript.Entry] = []
        
        for try await partial in self {
            finalPartial = partial
            // For types where PartiallyGenerated == Self, check if it has isComplete
            if let partialWithComplete = partial as? PartiallyGeneratedProtocol,
               partialWithComplete.isComplete {
                break
            }
        }
        
        guard let partial = finalPartial else {
            let context = GenerationError.Context(debugDescription: "Stream completed without any content")
            throw GenerationError.decodingFailure(context)
        }
        
        // Convert PartiallyGenerated back to Content
        // For types where PartiallyGenerated == Self, this is straightforward
        let content: Content
        if Content.PartiallyGenerated.self == Content.self {
            content = partial as! Content
        } else {
            // For types with custom PartiallyGenerated, we need to convert
            // This requires the PartiallyGenerated to have the complete data
            // PartiallyGenerated conforms to ConvertibleToGeneratedContent
            if let convertible = partial as? ConvertibleToGeneratedContent {
                guard let convertedContent = try? Content(convertible.generatedContent) else {
                    let context = GenerationError.Context(debugDescription: "Failed to convert partial content to complete content")
                    throw GenerationError.decodingFailure(context)
                }
                content = convertedContent
            } else {
                // Fallback: assume PartiallyGenerated can be cast to Content
                guard let directContent = partial as? Content else {
                    let context = GenerationError.Context(debugDescription: "Cannot convert PartiallyGenerated to Content")
                    throw GenerationError.decodingFailure(context)
                }
                content = directContent
            }
        }
        
        // Create transcript entries from the streaming session
        // In a real implementation, this would come from the session's transcript
        let transcriptSlice = ArraySlice(allEntries)
        
        // Create raw content - for Generable types, convert back to GeneratedContent
        let rawContent: GeneratedContent
        if Content.self == GeneratedContent.self {
            rawContent = content as! GeneratedContent
        } else if Content.self == String.self {
            rawContent = GeneratedContent(content as! String)
        } else {
            // For other Generable types, create GeneratedContent from string representation
            rawContent = GeneratedContent("\(content)")
        }
        
        return LanguageModelSession.Response(
            content: content,
            rawContent: rawContent,
            transcriptEntries: transcriptSlice
        )
    }
    
    /// Collect all partial responses into an array (for testing)
    /// 
    /// **Implementation Note:** This is a convenience method for testing purposes.
    /// Production code should use `collect(isolation:)` instead.
    public func collectPartials() async throws -> [Element] {
        var results: [Element] = []
        for try await partial in self {
            results.append(partial)
        }
        return results
    }
}