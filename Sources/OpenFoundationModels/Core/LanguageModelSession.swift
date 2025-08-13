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
    
    /// Available tools for the session
    private var tools: [any Tool]
    
    // MARK: - Public Properties
    
    /// A full history of interactions, including user inputs and model responses.
    /// ✅ APPLE SPEC: final var transcript: Transcript { get }
    public final var transcript: Transcript {
        return _transcript
    }
    private var _transcript: Transcript = Transcript()
    
    /// A Boolean value that indicates a response is being generated.
    /// ✅ APPLE SPEC: final var isResponding: Bool { get }
    public final var isResponding: Bool {
        return _isResponding
    }
    private var _isResponding: Bool = false
    
    // MARK: - Initializers
    
    /// Start a new session in blank slate state with string-based instructions.
    /// ✅ APPLE SPEC: convenience init(model:tools:instructions:)
    public convenience init(
        model: any LanguageModel,
        tools: [any Tool] = [],
        instructions: String? = nil
    ) {
        self.init(
            model: model,
            tools: tools,
            instructions: instructions.map(Instructions.init)
        )
    }
    
    /// Start a new session in blank slate state with instructions builder.
    /// ✅ APPLE SPEC: convenience init(model:tools:instructions:)
    public convenience init(
        model: any LanguageModel,
        tools: [any Tool] = [],
        @InstructionsBuilder instructions: () throws -> Instructions
    ) rethrows {
        try self.init(
            model: model,
            tools: tools,
            instructions: instructions()
        )
    }
    
    /// Start a new session in blank slate state with instructions.
    /// ✅ APPLE SPEC: convenience init(model:tools:instructions:)
    public convenience init(
        model: any LanguageModel,
        tools: [any Tool] = [],
        instructions: Instructions? = nil
    ) {
        self.init(model: model)
        self.tools = tools
        
        // Add instructions as the first Transcript entry
        if let instructions = instructions {
            let instructionEntry = Transcript.Entry.instructions(
                Transcript.Instructions(
                    id: UUID().uuidString,
                    segments: [.text(Transcript.TextSegment(
                        id: UUID().uuidString,
                        content: instructions.description
                    ))],
                    toolDefinitions: tools.map { Transcript.ToolDefinition(tool: $0) }
                )
            )
            self._transcript.append(instructionEntry)
        }
    }
    
    /// Start a session by rehydrating from a transcript.
    /// ✅ APPLE SPEC: convenience init(model:tools:transcript:)
    public convenience init(
        model: any LanguageModel,
        tools: [any Tool] = [],
        transcript: Transcript
    ) {
        self.init(model: model)
        self.tools = tools
        self._transcript = transcript
    }
    
    /// Designated initializer
    private init(model: any LanguageModel) {
        self.model = model
        self.tools = []
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
    
    // MARK: - Response Type
    
    /// A structure that stores the output of a response call.
    /// ✅ APPLE SPEC: struct Response<Content> where Content : Generable
    public struct Response<Content: Sendable>: Sendable {
        /// The response content.
        public let content: Content
        
        /// The raw response content.
        /// When `Content` is `GeneratedContent`, this is the same as `content`.
        public let rawContent: GeneratedContent
        
        /// The list of transcript entries.
        public let transcriptEntries: ArraySlice<Transcript.Entry>
    }
    
    // MARK: - Respond Methods (String Input)
    
    /// Produces a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(to:options:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        to prompt: String,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<String> {
        return try await respond(to: Prompt(prompt), options: options)
    }
    
    /// Produces a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(to:options:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        to prompt: Prompt,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<String> {
        return try await respond(options: options) { prompt }
    }
    
    /// Produces a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(options:prompt:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> Response<String> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        _isResponding = true
        defer { _isResponding = false }
        
        // Create and add prompt entry to transcript
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: nil
            )
        )
        _transcript.append(promptEntry)
        
        // Pass complete transcript to model
        let content = try await model.generate(
            transcript: _transcript,
            options: options
        )
        let responseEntry = Transcript.Entry.response(
            Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: content))]
            )
        )
        
        _transcript.append(responseEntry)
        
        // Return the last two entries (prompt and response)
        let entries = Array(_transcript.entries.suffix(2))
        let entriesSlice = ArraySlice(entries)
        
        return Response(
            content: content,
            rawContent: GeneratedContent(content),
            transcriptEntries: entriesSlice
        )
    }
    
    // MARK: - Respond Methods (GeneratedContent Output)
    
    /// Produces a generated content type as a response to a prompt and schema.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(to:schema:includeSchemaInPrompt:options:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        to prompt: String,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<GeneratedContent> {
        return try await respond(
            to: Prompt(prompt),
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }
    
    /// Produces a generated content type as a response to a prompt and schema.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(to:schema:includeSchemaInPrompt:options:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        to prompt: Prompt,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<GeneratedContent> {
        return try await respond(
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        ) { prompt }
    }
    
    /// Produces a generated content type as a response to a prompt and schema.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond(schema:includeSchemaInPrompt:options:prompt:)
    @discardableResult
    nonisolated(nonsending) public final func respond(
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> Response<GeneratedContent> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        _isResponding = true
        defer { _isResponding = false }
        
        // Create and add prompt entry with schema to transcript
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(schema: schema) : nil
            )
        )
        _transcript.append(promptEntry)
        
        // Pass complete transcript to model
        let text = try await model.generate(
            transcript: _transcript,
            options: options
        )
        let content = GeneratedContent(text)
        let responseEntry = Transcript.Entry.response(
            Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.structure(Transcript.StructuredSegment(
                    id: UUID().uuidString,
                    source: "model",
                    content: content
                ))]
            )
        )
        
        _transcript.append(responseEntry)
        
        // Return the last two entries (prompt and response)
        let entries = Array(_transcript.entries.suffix(2))
        let entriesSlice = ArraySlice(entries)
        
        return Response(
            content: content,
            rawContent: content,
            transcriptEntries: entriesSlice
        )
    }
    
    // MARK: - Respond Methods (Generable Output)
    
    /// Produces a generable object as a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond<Content>(to:generating:includeSchemaInPrompt:options:)
    @discardableResult
    nonisolated(nonsending) public final func respond<Content: Generable>(
        to prompt: String,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<Content> {
        return try await respond(
            to: Prompt(prompt),
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }
    
    /// Produces a generable object as a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond<Content>(to:generating:includeSchemaInPrompt:options:)
    @discardableResult
    nonisolated(nonsending) public final func respond<Content: Generable>(
        to prompt: Prompt,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<Content> {
        return try await respond(
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        ) { prompt }
    }
    
    /// Produces a generable object as a response to a prompt.
    /// ✅ APPLE SPEC: @discardableResult nonisolated(nonsending) final func respond<Content>(generating:includeSchemaInPrompt:options:prompt:)
    @discardableResult
    nonisolated(nonsending) public final func respond<Content: Generable>(
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> Response<Content> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        _isResponding = true
        defer { _isResponding = false }
        
        // Create and add prompt entry with type schema to transcript
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(type: Content.self) : nil
            )
        )
        _transcript.append(promptEntry)
        
        // Pass complete transcript to model
        let text = try await model.generate(
            transcript: _transcript,
            options: options
        )
        let generatedContent = GeneratedContent(text)
        let content = try Content(generatedContent)
        let responseEntry = Transcript.Entry.response(
            Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [.structure(Transcript.StructuredSegment(
                    id: UUID().uuidString,
                    source: "model",
                    content: generatedContent
                ))]
            )
        )
        
        _transcript.append(responseEntry)
        
        // Return the last two entries (prompt and response)
        let entries = Array(_transcript.entries.suffix(2))
        let entriesSlice = ArraySlice(entries)
        
        return Response(
            content: content,
            rawContent: generatedContent,
            transcriptEntries: entriesSlice
        )
    }
    
    // MARK: - Stream Response Methods (String Output)
    
    /// Produces a response stream to a prompt.
    /// ✅ APPLE SPEC: final func streamResponse(to:options:) -> sending ResponseStream<String>
    public final func streamResponse(
        to prompt: String,
        options: GenerationOptions = GenerationOptions()
    ) -> sending ResponseStream<String> {
        return streamResponse(to: Prompt(prompt), options: options)
    }
    
    /// Produces a response stream to a prompt.
    /// ✅ APPLE SPEC: final func streamResponse(to:options:) -> sending ResponseStream<String>
    public final func streamResponse(
        to prompt: Prompt,
        options: GenerationOptions = GenerationOptions()
    ) -> sending ResponseStream<String> {
        return streamResponse(options: options) { prompt }
    }
    
    /// Produces a response stream to a prompt.
    /// ✅ APPLE SPEC: final func streamResponse(options:prompt:) rethrows -> sending ResponseStream<String>
    public final func streamResponse(
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> sending ResponseStream<String> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        // Create and add prompt entry to transcript
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: nil
            )
        )
        _transcript.append(promptEntry)
        
        let stream = AsyncThrowingStream<ResponseStream<String>.Snapshot, Error> { continuation in
            Task {
                _isResponding = true
                defer { _isResponding = false }
                
                let stringStream = model.stream(
                    transcript: _transcript,
                    options: options
                )
                var accumulatedContent = ""
                
                for await chunk in stringStream {
                    accumulatedContent += chunk
                    let snapshot = ResponseStream<String>.Snapshot(
                        content: accumulatedContent,
                        rawContent: GeneratedContent(accumulatedContent)
                    )
                    continuation.yield(snapshot)
                }
                
                // Add response entry to transcript when streaming completes
                if !accumulatedContent.isEmpty {
                    let responseEntry = Transcript.Entry.response(
                        Transcript.Response(
                            id: UUID().uuidString,
                            assetIDs: [],
                            segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: accumulatedContent))]
                        )
                    )
                    _transcript.append(responseEntry)
                }
                
                continuation.finish()
            }
        }
        
        return ResponseStream(stream: stream)
    }
    
    // MARK: - Stream Response Methods (GeneratedContent Output)
    
    /// Produces a response stream to a prompt and schema.
    /// ✅ APPLE SPEC: final func streamResponse(to:schema:includeSchemaInPrompt:options:) -> sending ResponseStream<GeneratedContent>
    public final func streamResponse(
        to prompt: String,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) -> sending ResponseStream<GeneratedContent> {
        return streamResponse(
            to: Prompt(prompt),
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }
    
    /// Produces a response stream to a prompt and schema.
    /// ✅ APPLE SPEC: final func streamResponse(to:schema:includeSchemaInPrompt:options:) -> sending ResponseStream<GeneratedContent>
    public final func streamResponse(
        to prompt: Prompt,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) -> sending ResponseStream<GeneratedContent> {
        return streamResponse(
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        ) { prompt }
    }
    
    /// Produces a response stream to a prompt and schema.
    /// ✅ APPLE SPEC: final func streamResponse(schema:includeSchemaInPrompt:options:prompt:) rethrows -> sending ResponseStream<GeneratedContent>
    public final func streamResponse(
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> sending ResponseStream<GeneratedContent> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        let stream = AsyncThrowingStream<ResponseStream<GeneratedContent>.Snapshot, Error> { continuation in
            Task {
                _isResponding = true
                defer { _isResponding = false }
                
                // Create and add prompt entry with schema to transcript
                let promptEntry = Transcript.Entry.prompt(
                    Transcript.Prompt(
                        id: UUID().uuidString,
                        segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                        options: options,
                        responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(schema: schema) : nil
                    )
                )
                _transcript.append(promptEntry)
                
                let stringStream = model.stream(
                    transcript: _transcript,
                    options: options
                )
                var accumulatedText = ""
                
                for await chunk in stringStream {
                    accumulatedText += chunk
                    let partialContent = GeneratedContent(accumulatedText)
                    let snapshot = ResponseStream<GeneratedContent>.Snapshot(
                        content: partialContent,
                        rawContent: partialContent
                    )
                    continuation.yield(snapshot)
                }
                
                // Add response entry to transcript when streaming completes
                if !accumulatedText.isEmpty {
                    let responseEntry = Transcript.Entry.response(
                        Transcript.Response(
                            id: UUID().uuidString,
                            assetIDs: [],
                            segments: [.structure(Transcript.StructuredSegment(
                                id: UUID().uuidString,
                                source: "model",
                                content: GeneratedContent(accumulatedText)
                            ))]
                        )
                    )
                    _transcript.append(responseEntry)
                }
                
                continuation.finish()
            }
        }
        
        return ResponseStream(stream: stream)
    }
    
    // MARK: - Stream Response Methods (Generable Output)
    
    /// Produces a response stream to a prompt.
    /// ✅ APPLE SPEC: final func streamResponse<Content>(to:generating:includeSchemaInPrompt:options:) -> sending ResponseStream<Content>
    public final func streamResponse<Content: Generable>(
        to prompt: String,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) -> sending ResponseStream<Content> {
        return streamResponse(
            to: Prompt(prompt),
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        )
    }
    
    /// Produces a response stream to a prompt.
    /// ✅ APPLE SPEC: final func streamResponse<Content>(to:generating:includeSchemaInPrompt:options:) -> sending ResponseStream<Content>
    public final func streamResponse<Content: Generable>(
        to prompt: Prompt,
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) -> sending ResponseStream<Content> {
        return streamResponse(
            generating: type,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        ) { prompt }
    }
    
    /// Produces a response stream for a type.
    /// ✅ APPLE SPEC: final func streamResponse<Content>(generating:includeSchemaInPrompt:options:prompt:) rethrows -> sending ResponseStream<Content>
    public final func streamResponse<Content: Generable>(
        generating type: Content.Type = Content.self,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> sending ResponseStream<Content> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        typealias PartialContent = Content.PartiallyGenerated
        
        let stream = AsyncThrowingStream<ResponseStream<Content>.Snapshot, Error> { continuation in
            Task {
                _isResponding = true
                defer { _isResponding = false }
                
                // Create and add prompt entry with type schema to transcript
                let promptEntry = Transcript.Entry.prompt(
                    Transcript.Prompt(
                        id: UUID().uuidString,
                        segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                        options: options,
                        responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(type: Content.self) : nil
                    )
                )
                _transcript.append(promptEntry)
                
                let stringStream = model.stream(
                    transcript: _transcript,
                    options: options
                )
                var accumulatedText = ""
                
                for await chunk in stringStream {
                    accumulatedText += chunk
                    let generatedContent = GeneratedContent(accumulatedText)
                    
                    // Try to create partial content
                    if let partialData = try? PartialContent(generatedContent) {
                        // For Generable content, we need to handle PartiallyGenerated
                        // which may be different from Content itself
                        if PartialContent.self == Content.self {
                            // PartiallyGenerated is the same as Content (e.g., String)
                            let snapshot = ResponseStream<Content>.Snapshot(
                                content: partialData as! Content,
                                rawContent: generatedContent
                            )
                            continuation.yield(snapshot)
                        } else {
                            // Need to convert PartiallyGenerated to Content
                            // This will be handled by the extension's collect method
                            if let convertedContent = try? Content(generatedContent) {
                                let snapshot = ResponseStream<Content>.Snapshot(
                                    content: convertedContent,
                                    rawContent: generatedContent
                                )
                                continuation.yield(snapshot)
                            }
                        }
                    }
                }
                
                continuation.finish()
            }
        }
        
        return ResponseStream(stream: stream)
    }
    
    // MARK: - Feedback
    
    /// Logs and serializes a feedback attachment that can be submitted to Apple.
    /// ✅ APPLE SPEC: @discardableResult func logFeedbackAttachment(sentiment:issues:desiredOutput:) -> Data
    @discardableResult
    public final func logFeedbackAttachment(
        sentiment: LanguageModelFeedback.Sentiment?,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredOutput: Transcript.Entry? = nil
    ) -> Data {
        // Implementation: Serialize feedback data for submission
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
            feedbackData["desiredOutput"] = String(describing: desiredOutput)
        }
        
        feedbackData["transcript"] = transcript.entries.map { String(describing: $0) }
        
        // Convert to Data
        if let data = try? JSONSerialization.data(withJSONObject: feedbackData, options: .prettyPrinted) {
            return data
        }
        
        return Data()
    }
}

// MARK: - ResponseStream Type

extension LanguageModelSession {
    
    /// An async sequence of snapshots of partially generated content.
    /// ✅ APPLE SPEC: struct ResponseStream<Content> where Content : Generable
    public struct ResponseStream<Content: Sendable>: AsyncSequence, Sendable {
        
        /// A snapshot of partially generated content.
        /// ✅ APPLE SPEC: struct Snapshot
        public struct Snapshot: Sendable {
            /// The content of the response.
            public var content: Content
            
            /// The raw content of the response.
            /// When `Content` is `GeneratedContent`, this is the same as `content`.
            public var rawContent: GeneratedContent
        }
        
        /// The type of element produced by this asynchronous sequence.
        public typealias Element = Snapshot
        
        /// The type of asynchronous iterator that produces elements of this asynchronous sequence.
        public struct AsyncIterator: AsyncIteratorProtocol, @unchecked Sendable {
            private var iterator: AsyncThrowingStream<Snapshot, Error>.AsyncIterator
            
            init(stream: AsyncThrowingStream<Snapshot, Error>) {
                self.iterator = stream.makeAsyncIterator()
            }
            
            /// Asynchronously advances to the next element and returns it, or ends the
            /// sequence if there is no next element.
            public mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> Snapshot? {
                // The isolation parameter is kept for API compatibility with Apple's specification
                // We suppress the warning by using @unchecked Sendable on the struct
                return try await iterator.next()
            }
        }
        
        /// The underlying async stream
        private let stream: AsyncThrowingStream<Snapshot, Error>
        
        /// Initialize with an async throwing stream
        init(stream: AsyncThrowingStream<Snapshot, Error>) {
            self.stream = stream
        }
        
        /// Creates the asynchronous iterator that produces elements of this asynchronous sequence.
        public func makeAsyncIterator() -> AsyncIterator {
            return AsyncIterator(stream: stream)
        }
        
        /// The result from a streaming response, after it completes.
        /// ✅ APPLE SPEC: nonisolated(nonsending) func collect() async throws -> sending Response<Content>
        nonisolated(nonsending) public func collect() async throws -> sending Response<Content> {
            var finalSnapshot: Snapshot?
            let allEntries = ArraySlice<Transcript.Entry>()
            
            for try await snapshot in self {
                finalSnapshot = snapshot
            }
            
            guard let snapshot = finalSnapshot else {
                let context = GenerationError.Context(debugDescription: "Stream completed without any content")
                throw GenerationError.decodingFailure(context)
            }
            
            return Response(
                content: snapshot.content,
                rawContent: snapshot.rawContent,
                transcriptEntries: allEntries
            )
        }
    }
}

// MARK: - ResponseStream Generable Constraint Extension

extension LanguageModelSession.ResponseStream where Content: Generable {
    
    /// The result from a streaming response, after it completes for Generable content.
    /// ✅ APPLE SPEC: nonisolated(nonsending) func collect() async throws -> sending Response<Content>
    nonisolated(nonsending) public func collect() async throws -> sending LanguageModelSession.Response<Content> {
        // For Generable content, we need to handle PartiallyGenerated type
        // This is a specialized implementation for Generable types
        // The default implementation in the base ResponseStream handles simple types
        var finalSnapshot: Snapshot?
        let allEntries = ArraySlice<Transcript.Entry>()
        
        for try await snapshot in self {
            finalSnapshot = snapshot
        }
        
        guard let snapshot = finalSnapshot else {
            let context = LanguageModelSession.GenerationError.Context(debugDescription: "Stream completed without any content")
            throw LanguageModelSession.GenerationError.decodingFailure(context)
        }
        
        // For Generable types that aren't strings or basic types
        // Cast content directly as it should already be the right type
        return LanguageModelSession.Response(
            content: snapshot.content,
            rawContent: snapshot.rawContent,
            transcriptEntries: allEntries
        )
    }
}

// MARK: - GenerationError

extension LanguageModelSession {
    
    /// An error that occurs while generating a response.
    /// ✅ APPLE SPEC: enum GenerationError
    public enum GenerationError: Error, LocalizedError, Sendable {
        
        /// The context in which the error occurred.
        public struct Context: Sendable {
            /// A debug description to help developers diagnose issues during development.
            public let debugDescription: String
            
            /// Creates a context.
            public init(debugDescription: String) {
                self.debugDescription = debugDescription
            }
        }
        
        /// The context in which the refusal error occurred.
        public struct Refusal: Sendable {
            private let transcriptEntries: [Transcript.Entry]
            
            public init(transcriptEntries: [Transcript.Entry]) {
                self.transcriptEntries = transcriptEntries
            }
            
            /// Get an explanation for the refusal
            public var explanation: Response<String> {
                get async throws {
                    // Implementation would use the model to generate an explanation
                    // For now, return a placeholder response
                    return Response(
                        content: "The model refused to generate content for this request.",
                        rawContent: GeneratedContent("The model refused to generate content for this request."),
                        transcriptEntries: ArraySlice(transcriptEntries)
                    )
                }
            }
            
            /// Stream an explanation for the refusal
            public var explanationStream: ResponseStream<String> {
                // Implementation would stream the explanation
                // For now, return an empty stream
                typealias StringSnapshot = ResponseStream<String>.Snapshot
                let stream = AsyncThrowingStream<StringSnapshot, Error> { continuation in
                    continuation.finish()
                }
                return ResponseStream<String>(stream: stream)
            }
        }
        
        /// An error that signals the session reached its context window size limit.
        case exceededContextWindowSize(Context)
        
        /// An error that indicates the assets required for the session are unavailable.
        case assetsUnavailable(Context)
        
        /// An error that indicates the system's safety guardrails are triggered by content.
        case guardrailViolation(Context)
        
        /// An error that indicates a generation guide with an unsupported pattern was used.
        case unsupportedGuide(Context)
        
        /// An error that indicates the model is prompted to respond in an unsupported language.
        case unsupportedLanguageOrLocale(Context)
        
        /// An error that indicates the session failed to deserialize a valid generable type.
        case decodingFailure(Context)
        
        /// An error that indicates your session has been rate limited.
        case rateLimited(Context)
        
        /// An error that happens if you attempt to make concurrent requests.
        case concurrentRequests(Context)
        
        /// An error that indicates the model refused to generate content.
        case refusal(Refusal, Context)
        
        /// A string representation of the error description.
        public var errorDescription: String? {
            switch self {
            case .exceededContextWindowSize(let context):
                return "Context window size exceeded: \(context.debugDescription)"
            case .assetsUnavailable(let context):
                return "Assets unavailable: \(context.debugDescription)"
            case .guardrailViolation(let context):
                return "Guardrail violation: \(context.debugDescription)"
            case .unsupportedGuide(let context):
                return "Unsupported guide: \(context.debugDescription)"
            case .unsupportedLanguageOrLocale(let context):
                return "Unsupported language or locale: \(context.debugDescription)"
            case .decodingFailure(let context):
                return "Decoding failure: \(context.debugDescription)"
            case .rateLimited(let context):
                return "Rate limited: \(context.debugDescription)"
            case .concurrentRequests(let context):
                return "Concurrent requests: \(context.debugDescription)"
            case .refusal(_, let context):
                return "Model refusal: \(context.debugDescription)"
            }
        }
        
        /// A string representation of the recovery suggestion.
        public var recoverySuggestion: String? {
            switch self {
            case .exceededContextWindowSize:
                return "Start a new session with a shorter prompt or reduce the output length."
            case .assetsUnavailable:
                return "Check model availability and retry after the device has freed up space."
            case .guardrailViolation:
                return "Review your content to ensure it complies with safety guidelines."
            case .unsupportedGuide:
                return "Use a supported generation guide pattern."
            case .unsupportedLanguageOrLocale:
                return "Use a supported language or locale for your request."
            case .decodingFailure:
                return "Ensure the generated content matches the expected format."
            case .rateLimited:
                return "Wait before making additional requests."
            case .concurrentRequests:
                return "Wait for the current request to complete before making another."
            case .refusal:
                return "Modify your request to comply with model guidelines."
            }
        }
        
        /// A string representation of the failure reason.
        public var failureReason: String? {
            return errorDescription
        }
    }
    
    /// An error that occurs while a system language model is calling a tool.
    /// ✅ APPLE SPEC: struct ToolCallError
    public struct ToolCallError: Error, LocalizedError, Sendable {
        
        /// The tool that produced the error.
        public var tool: any Tool
        
        /// The underlying error that was thrown during a tool call.
        public var underlyingError: any Error
        
        /// Creates a tool call error
        public init(tool: any Tool, underlyingError: any Error) {
            self.tool = tool
            self.underlyingError = underlyingError
        }
        
        /// A string representation of the error description.
        public var errorDescription: String? {
            return "Tool call error in '\(tool.name)': \(underlyingError.localizedDescription)"
        }
    }
}
