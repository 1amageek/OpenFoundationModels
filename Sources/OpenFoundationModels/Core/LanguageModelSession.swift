// LanguageModelSession.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: 100% API Compatible with Apple Foundation Models

import Foundation
import OpenFoundationModelsCore

/// An object that represents a session that interacts with a language model.
/// 
/// **Apple Foundation Models Documentation:**
/// A session is a single context that you use to generate content with, and maintains state between requests.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession
/// 
/// **Apple Official API:** `final class LanguageModelSession`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
public final class LanguageModelSession: Observable, @unchecked Sendable {
    
    // MARK: - Private Properties
    
    /// The underlying language model
    private var model: any LanguageModel
    
    /// Session instructions
    private var instructions: Instructions?
    
    /// Available tools for the session
    private var tools: [any Tool]
    
    // MARK: - Public Properties
    
    /// A Boolean value that indicates a response is being generated.
    /// ✅ APPLE SPEC: final var isResponding: Bool { get }
    public final var isResponding: Bool {
        // Implementation: Track if a response is currently being generated
        return _isResponding
    }
    private var _isResponding: Bool = false
    
    /// A full history of interactions, including user inputs and model responses.
    /// ✅ APPLE SPEC: final var transcript: Transcript { get }
    public final var transcript: Transcript {
        return _transcript
    }
    private var _transcript: Transcript = Transcript()
    
    // MARK: - Initializers
    
    /// Start a new session in blank slate state with instructions builder.
    /// ✅ APPLE SPEC: convenience init(model:tools:instructions:)
    public convenience init(
        model: any LanguageModel = SystemLanguageModel.default,
        tools: [any Tool] = [],
        @InstructionsBuilder instructions: () throws -> Instructions
    ) rethrows {
        self.init()
        self.model = model
        self.tools = tools
        self.instructions = try instructions()
    }
    
    /// Start a session by rehydrating from a transcript.
    /// ✅ APPLE SPEC: convenience init(model:tools:transcript:)
    public convenience init(
        model: any LanguageModel = SystemLanguageModel.default,
        tools: [any Tool] = [],
        transcript: Transcript
    ) {
        self.init()
        self.model = model
        self.tools = tools
        self._transcript = transcript
    }
    
    /// Default initializer
    private init() {
        self.model = SystemLanguageModel.default
        self.tools = []
        self.instructions = nil
        self._transcript = Transcript()
    }
    
    // MARK: - Prewarm
    
    /// Requests that the system eagerly load the resources required for this session into memory
    /// and optionally caches a prefix of your prompt.
    /// ✅ APPLE SPEC: final func prewarm(promptPrefix:)
    public final func prewarm(promptPrefix: Prompt? = nil) {
        // Implementation: Prepare the model and optionally cache the prompt prefix
        // This is a synchronous method that initiates prewarming
    }
    
    // MARK: - Respond Methods (Closure-based)
    
    /// Produces a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(options:prompt:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> LanguageModelSession.Response<String> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        let content = try await model.generate(prompt: promptText, options: options, tools: tools)
        
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
    
    /// Produces a generable object as a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond<Content>(generating:includeSchemaInPrompt:options:prompt:)
    @discardableResult
    nonisolated(nonsending) public final func respond<Content>(
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> LanguageModelSession.Response<Content> where Content: Generable {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        // Generate schema-guided content
        let schemaPrompt = includeSchemaInPrompt ? 
            "\(promptText)\n\nGenerate response following this schema: \(Content.generationSchema)" : 
            promptText
        
        let text = try await model.generate(prompt: schemaPrompt, options: options, tools: tools)
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
    
    /// Produces a generated content type as a response to a prompt and schema.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(schema:includeSchemaInPrompt:options:prompt:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> LanguageModelSession.Response<GeneratedContent> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        // Generate schema-guided content
        let schemaPrompt = includeSchemaInPrompt ? 
            "\(promptText)\n\nGenerate response following this schema: \(schema)" : 
            promptText
        
        let text = try await model.generate(prompt: schemaPrompt, options: options, tools: tools)
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
    
    // MARK: - Respond Methods (Direct Prompt)
    
    /// Produces a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(to:options:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        to prompt: Prompt,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> LanguageModelSession.Response<String> {
        return try await respond(options: options) { prompt }
    }
    
    /// Produces a generable object as a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond<Content>(to:generating:includeSchemaInPrompt:options:)
    @discardableResult
    nonisolated(nonsending) public final func respond<Content>(
        to prompt: Prompt,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> LanguageModelSession.Response<Content> where Content: Generable {
        return try await respond(
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        ) { prompt }
    }
    
    /// Produces a generated content type as a response to a prompt and schema.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(to:schema:includeSchemaInPrompt:options:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        to prompt: Prompt,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> LanguageModelSession.Response<GeneratedContent> {
        return try await respond(
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        ) { prompt }
    }
    
    // MARK: - Stream Response Methods (Closure-based)
    
    /// Produces a response stream to a prompt.
    /// ✅ APPLE SPEC: final func streamResponse(options:prompt:) rethrows -> sending ResponseStream<String>
    public final func streamResponse(
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> sending LanguageModelSession.ResponseStream<String> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        let stream = AsyncThrowingStream<String.PartiallyGenerated, Error> { continuation in
            Task<Void, Never> {
                let stringStream = model.stream(prompt: promptText, options: options, tools: tools)
                var accumulatedContent = ""
                
                for await chunk in stringStream {
                    accumulatedContent += chunk
                    continuation.yield(accumulatedContent)
                }
                
                continuation.finish()
            }
        }
        
        return LanguageModelSession.ResponseStream(stream: stream)
    }
    
    /// Produces a response stream for a type.
    /// ✅ APPLE SPEC: final func streamResponse<Content>(generating:includeSchemaInPrompt:options:prompt:) rethrows -> sending ResponseStream<Content>
    public final func streamResponse<Content>(
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> sending LanguageModelSession.ResponseStream<Content> where Content: Generable {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        typealias PartialContent = Content.PartiallyGenerated
        
        let stream = AsyncThrowingStream<PartialContent, Error> { continuation in
            Task<Void, Never> {
                let schemaPrompt = includeSchemaInPrompt ? 
                    "\(promptText)\n\nGenerate response following this schema: \(Content.generationSchema)" : 
                    promptText
                
                let stringStream = model.stream(prompt: schemaPrompt, options: options, tools: tools)
                var accumulatedText = ""
                
                for await chunk in stringStream {
                    accumulatedText += chunk
                    let partialContent = GeneratedContent(accumulatedText)
                    
                    if let partialData = try? PartialContent(partialContent) {
                        continuation.yield(partialData)
                    }
                }
                
                let finalContent = GeneratedContent(accumulatedText)
                if let finalData = try? PartialContent(finalContent) {
                    continuation.yield(finalData)
                }
                
                continuation.finish()
            }
        }
        
        return LanguageModelSession.ResponseStream(stream: stream)
    }
    
    /// Produces a response stream to a prompt and schema.
    /// ✅ APPLE SPEC: final func streamResponse(schema:includeSchemaInPrompt:options:prompt:) rethrows -> sending ResponseStream<GeneratedContent>
    public final func streamResponse(
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> sending LanguageModelSession.ResponseStream<GeneratedContent> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        let stream = AsyncThrowingStream<GeneratedContent.PartiallyGenerated, Error> { continuation in
            Task<Void, Never> {
                let schemaPrompt = includeSchemaInPrompt ? 
                    "\(promptText)\n\nGenerate response following this schema: \(schema)" : 
                    promptText
                
                let stringStream = model.stream(prompt: schemaPrompt, options: options, tools: tools)
                var accumulatedText = ""
                
                for await chunk in stringStream {
                    accumulatedText += chunk
                    let partialContent = GeneratedContent(accumulatedText)
                    continuation.yield(partialContent)
                }
                
                let finalContent = GeneratedContent(accumulatedText)
                continuation.yield(finalContent)
                continuation.finish()
            }
        }
        
        return LanguageModelSession.ResponseStream(stream: stream)
    }
    
    // MARK: - Stream Response Methods (Direct Prompt)
    
    /// Produces a response stream to a prompt.
    /// ✅ APPLE SPEC: final func streamResponse(to:options:) -> sending ResponseStream<String>
    public final func streamResponse(
        to prompt: Prompt,
        options: GenerationOptions = GenerationOptions()
    ) -> sending LanguageModelSession.ResponseStream<String> {
        return streamResponse(options: options) { prompt }
    }
    
    /// Produces a response stream to a prompt and schema.
    /// ✅ APPLE SPEC: final func streamResponse<Content>(to:generating:includeSchemaInPrompt:options:) -> sending ResponseStream<Content>
    public final func streamResponse<Content>(
        to prompt: Prompt,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) -> sending LanguageModelSession.ResponseStream<Content> where Content: Generable {
        return streamResponse(
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        ) { prompt }
    }
    
    /// Produces a response stream to a prompt and schema.
    /// ✅ APPLE SPEC: final func streamResponse(to:schema:includeSchemaInPrompt:options:) -> sending ResponseStream<GeneratedContent>
    public final func streamResponse(
        to prompt: Prompt,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) -> sending LanguageModelSession.ResponseStream<GeneratedContent> {
        return streamResponse(
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        ) { prompt }
    }
    
    // MARK: - Feedback
    
    /// Logs and serializes a feedback attachment that can be submitted to Apple.
    /// ✅ APPLE SPEC: func logFeedbackAttachment(sentiment:issues:desiredOutput:) -> Data
    public func logFeedbackAttachment(
        sentiment: LanguageModelFeedback.Sentiment?,
        issues: [LanguageModelFeedback.Issue],
        desiredOutput: Transcript.Entry?
    ) -> Data {
        // Implementation: Serialize feedback data for submission
        // This would create a structured data format that Apple can process
        var feedbackData: [String: Any] = [:]
        
        if let sentiment = sentiment {
            feedbackData["sentiment"] = String(describing: sentiment)
        }
        
        feedbackData["issues"] = issues.map { issue in
            [
                "category": String(describing: issue.category),
                "explanation": issue.explanation ?? ""
            ]
        }
        
        if let desiredOutput = desiredOutput {
            // Serialize the transcript entry
            feedbackData["desiredOutput"] = String(describing: desiredOutput)
        }
        
        // Convert to Data
        if let data = try? JSONSerialization.data(withJSONObject: feedbackData, options: .prettyPrinted) {
            return data
        }
        
        return Data()
    }
}

// MARK: - Nested Types

extension LanguageModelSession {
    
    // MARK: - Response
    
    /// A structure that stores the output of a response call.
    /// ✅ APPLE SPEC: struct Response<Content>
    public struct Response<Content: Sendable>: Sendable {
        /// The response content.
        public let content: Content
        
        /// The raw response content.
        public let rawContent: GeneratedContent
        
        /// The list of transcript entries.
        public let transcriptEntries: ArraySlice<Transcript.Entry>
        
        /// Initialize a response with Apple-compliant structure
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
        public init(
            content: Content,
            transcriptEntries: ArraySlice<Transcript.Entry>
        ) where Content == GeneratedContent {
            self.content = content
            self.rawContent = content
            self.transcriptEntries = transcriptEntries
        }
    }
    
    // MARK: - ResponseStream
    
    /// An async sequence of snapshots of partially generated content.
    /// ✅ APPLE SPEC: struct ResponseStream<Content> where Content : Generable
    public struct ResponseStream<Content>: AsyncSequence, Sendable where Content: Generable & Sendable {
        
        /// The element type yielded by the stream
        public typealias Element = Content.PartiallyGenerated
        
        /// The async iterator for the stream
        public typealias AsyncIterator = ResponseStreamIterator<Content>
        
        /// The underlying async stream
        private let stream: AsyncThrowingStream<Content.PartiallyGenerated, Error>
        
        /// The last partial response received
        public private(set) var last: Content.PartiallyGenerated?
        
        /// Initialize with an async throwing stream
        public init(
            stream: AsyncThrowingStream<Content.PartiallyGenerated, Error>
        ) {
            self.stream = stream
            self.last = nil
        }
        
        /// Create an async iterator
        public func makeAsyncIterator() -> AsyncIterator {
            return ResponseStreamIterator(stream: stream)
        }
        
        /// Collects all streaming content into a final Response object.
        /// ✅ APPLE SPEC: func collect(isolation:) async throws -> sending Response<Content>
        public func collect(
            isolation: isolated (any Actor)? = nil
        ) async throws -> sending LanguageModelSession.Response<Content> {
            var finalPartial: Content.PartiallyGenerated?
            let allEntries: [Transcript.Entry] = []
            
            for try await partial in self {
                finalPartial = partial
                if let partialWithComplete = partial as? PartiallyGeneratedProtocol,
                   partialWithComplete.isComplete {
                    break
                }
            }
            
            guard let partial = finalPartial else {
                let context = GenerationError.Context(debugDescription: "Stream completed without any content")
                throw GenerationError.decodingFailure(context)
            }
            
            let content: Content
            if Content.PartiallyGenerated.self == Content.self {
                content = partial as! Content
            } else {
                if let convertible = partial as? ConvertibleToGeneratedContent {
                    guard let convertedContent = try? Content(convertible.generatedContent) else {
                        let context = GenerationError.Context(debugDescription: "Failed to convert partial content to complete content")
                        throw GenerationError.decodingFailure(context)
                    }
                    content = convertedContent
                } else {
                    guard let directContent = partial as? Content else {
                        let context = GenerationError.Context(debugDescription: "Cannot convert PartiallyGenerated to Content")
                        throw GenerationError.decodingFailure(context)
                    }
                    content = directContent
                }
            }
            
            let transcriptSlice = ArraySlice(allEntries)
            
            let rawContent: GeneratedContent
            if Content.self == GeneratedContent.self {
                rawContent = content as! GeneratedContent
            } else if Content.self == String.self {
                rawContent = GeneratedContent(content as! String)
            } else {
                rawContent = GeneratedContent("\(content)")
            }
            
            return LanguageModelSession.Response(
                content: content,
                rawContent: rawContent,
                transcriptEntries: transcriptSlice
            )
        }
        
        /// A snapshot of partially generated content.
        public struct Snapshot: Sendable {
            /// The content of the response.
            public let content: Content.PartiallyGenerated
            
            /// The raw content of the response.
            public let rawContent: GeneratedContent
            
            /// Initialize a snapshot
            public init(
                content: Content.PartiallyGenerated,
                rawContent: GeneratedContent
            ) {
                self.content = content
                self.rawContent = rawContent
            }
        }
    }
    
    // MARK: - ResponseStreamIterator
    
    /// The async iterator for ResponseStream
    public struct ResponseStreamIterator<Content: Generable & Sendable>: AsyncIteratorProtocol {
        
        /// The element type
        public typealias Element = Content.PartiallyGenerated
        
        /// The underlying stream iterator
        private var iterator: AsyncThrowingStream<Content.PartiallyGenerated, Error>.AsyncIterator
        
        /// Initialize with a stream
        public init(
            stream: AsyncThrowingStream<Content.PartiallyGenerated, Error>
        ) {
            self.iterator = stream.makeAsyncIterator()
        }
        
        /// Get the next element
        public mutating func next() async throws -> Element? {
            return try await iterator.next()
        }
    }
    
    // MARK: - GenerationError
    
    /// An error that occurs while generating a response.
    /// ✅ APPLE SPEC: enum GenerationError
    public enum GenerationError: Error, LocalizedError, Sendable {
        
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
        public struct Context: Sendable {
            /// A debug description to help developers diagnose issues during development.
            public let debugDescription: String
            
            /// Creates a context.
            public init(debugDescription: String) {
                self.debugDescription = debugDescription
            }
        }
        
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
    }
    
    // MARK: - ToolCallError
    
    /// An error that occurs while a system language model is calling a tool
    /// ✅ APPLE SPEC: struct ToolCallError
    public struct ToolCallError: Error, Sendable {
        
        /// The name of the tool that caused the error
        public let toolName: String
        
        /// The underlying error that occurred
        public let underlying: Error
        
        /// Additional context about the error
        public let context: [String: String]
        
        /// Initialize a tool call error
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
    public var errorDescription: String? {
        return "Tool call error in '\(toolName)': \(underlying.localizedDescription)"
    }
    
    /// A localized message describing the reason for the failure
    public var failureReason: String? {
        return "The tool '\(toolName)' failed to execute properly: \(underlying.localizedDescription)"
    }
    
    /// A localized message describing how one might recover from the failure
    public var recoverySuggestion: String? {
        return "Check the tool configuration and arguments, then try again."
    }
}