
import Foundation
import OpenFoundationModelsCore

public final class LanguageModelSession: Observable, @unchecked Sendable {
    
    private var model: any LanguageModel
    private var tools: [any Tool]
    public final var transcript: Transcript {
        return _transcript
    }
    private var _transcript: Transcript = Transcript()
    public final var isResponding: Bool {
        return _isResponding
    }
    private var _isResponding: Bool = false
    
    public convenience init(
        model: any LanguageModel,
        tools: [any Tool] = [],
        instructions: String? = nil
    ) {
        self.init(
            model: model,
            tools: tools,
            instructions: instructions.map { OpenFoundationModelsCore.Instructions($0) }
        )
    }
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
    public convenience init(
        model: any LanguageModel,
        tools: [any Tool] = [],
        instructions: Instructions? = nil
    ) {
        self.init(model: model)
        self.tools = tools
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
            var entries = _transcript.entries
            entries.append(instructionEntry)
            self._transcript = Transcript(entries: entries)
        }
    }
    
    public convenience init(
        model: any LanguageModel,
        tools: [any Tool] = [],
        transcript: Transcript
    ) {
        self.init(model: model)
        self.tools = tools
        self._transcript = transcript
    }
    
    private init(model: any LanguageModel) {
        self.model = model
        self.tools = []
        self._transcript = Transcript()
    }
    
    
    public final func prewarm(promptPrefix: Prompt? = nil) {
    }
    
    
    public struct Response<Content: Sendable>: Sendable {
        public let content: Content
        
        public let rawContent: GeneratedContent
        
        public let transcriptEntries: ArraySlice<Transcript.Entry>
    }
    
    
    @discardableResult
    nonisolated(nonsending) public final func respond(
        to prompt: String,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<String> {
        return try await respond(to: Prompt(prompt), options: options)
    }
    
    @discardableResult
    nonisolated(nonsending) public final func respond(
        to prompt: Prompt,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<String> {
        return try await respond(options: options) { prompt }
    }
    
    @discardableResult
    nonisolated(nonsending) public final func respond(
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) async throws -> Response<String> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        _isResponding = true
        defer { _isResponding = false }
        
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: nil
            )
        )
        var entries = _transcript.entries
        entries.append(promptEntry)
        _transcript = Transcript(entries: entries)
        
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
        
        var transcriptEntries = _transcript.entries
        transcriptEntries.append(responseEntry)
        _transcript = Transcript(entries: transcriptEntries)
        
        let recentEntries = Array(_transcript.entries.suffix(2))
        let entriesSlice = ArraySlice(recentEntries)
        
        return Response(
            content: content,
            rawContent: GeneratedContent(content),
            transcriptEntries: entriesSlice
        )
    }
    
    
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
        
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(schema: schema) : nil
            )
        )
        var entries = _transcript.entries
        entries.append(promptEntry)
        _transcript = Transcript(entries: entries)
        
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
        
        var transcriptEntries = _transcript.entries
        transcriptEntries.append(responseEntry)
        _transcript = Transcript(entries: transcriptEntries)
        
        let recentEntries = Array(_transcript.entries.suffix(2))
        let entriesSlice = ArraySlice(recentEntries)
        
        return Response(
            content: content,
            rawContent: content,
            transcriptEntries: entriesSlice
        )
    }
    
    
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
        
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(type: Content.self) : nil
            )
        )
        var entries = _transcript.entries
        entries.append(promptEntry)
        _transcript = Transcript(entries: entries)
        
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
        
        var transcriptEntries = _transcript.entries
        transcriptEntries.append(responseEntry)
        _transcript = Transcript(entries: transcriptEntries)
        
        let recentEntries = Array(_transcript.entries.suffix(2))
        let entriesSlice = ArraySlice(recentEntries)
        
        return Response(
            content: content,
            rawContent: generatedContent,
            transcriptEntries: entriesSlice
        )
    }
    
    
    public final func streamResponse(
        to prompt: String,
        options: GenerationOptions = GenerationOptions()
    ) -> sending ResponseStream<String> {
        return streamResponse(to: Prompt(prompt), options: options)
    }
    
    public final func streamResponse(
        to prompt: Prompt,
        options: GenerationOptions = GenerationOptions()
    ) -> sending ResponseStream<String> {
        return streamResponse(options: options) { prompt }
    }
    
    public final func streamResponse(
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> sending ResponseStream<String> {
        let promptValue = try prompt()
        let promptText = promptValue.description
        
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: nil
            )
        )
        var entries = _transcript.entries
        entries.append(promptEntry)
        _transcript = Transcript(entries: entries)
        
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
                
                if !accumulatedContent.isEmpty {
                    let responseEntry = Transcript.Entry.response(
                        Transcript.Response(
                            id: UUID().uuidString,
                            assetIDs: [],
                            segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: accumulatedContent))]
                        )
                    )
                    var transcriptEntries = _transcript.entries
        transcriptEntries.append(responseEntry)
        _transcript = Transcript(entries: transcriptEntries)
                }
                
                continuation.finish()
            }
        }
        
        return ResponseStream(stream: stream)
    }
    
    
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
                
                let promptEntry = Transcript.Entry.prompt(
                    Transcript.Prompt(
                        id: UUID().uuidString,
                        segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                        options: options,
                        responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(schema: schema) : nil
                    )
                )
                var entries = _transcript.entries
        entries.append(promptEntry)
        _transcript = Transcript(entries: entries)
                
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
                    var transcriptEntries = _transcript.entries
        transcriptEntries.append(responseEntry)
        _transcript = Transcript(entries: transcriptEntries)
                }
                
                continuation.finish()
            }
        }
        
        return ResponseStream(stream: stream)
    }
    
    
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
                
                let promptEntry = Transcript.Entry.prompt(
                    Transcript.Prompt(
                        id: UUID().uuidString,
                        segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                        options: options,
                        responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(type: Content.self) : nil
                    )
                )
                var entries = _transcript.entries
        entries.append(promptEntry)
        _transcript = Transcript(entries: entries)
                
                let stringStream = model.stream(
                    transcript: _transcript,
                    options: options
                )
                var accumulatedText = ""
                
                for await chunk in stringStream {
                    accumulatedText += chunk
                    let generatedContent = GeneratedContent(accumulatedText)
                    
                    if let partialData = try? PartialContent(generatedContent) {
                        if PartialContent.self == Content.self {
                            let snapshot = ResponseStream<Content>.Snapshot(
                                content: partialData as! Content,
                                rawContent: generatedContent
                            )
                            continuation.yield(snapshot)
                        } else {
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
    
    
    @discardableResult
    public final func logFeedbackAttachment(
        sentiment: LanguageModelFeedback.Sentiment?,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredOutput: Transcript.Entry? = nil
    ) -> Data {
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
        
        if let data = try? JSONSerialization.data(withJSONObject: feedbackData, options: .prettyPrinted) {
            return data
        }
        
        return Data()
    }
}


extension LanguageModelSession {
    
    public struct ResponseStream<Content: Sendable>: AsyncSequence, Sendable {
        
        public struct Snapshot: Sendable {
            public var content: Content
            
            public var rawContent: GeneratedContent
        }
        
        public typealias Element = Snapshot
        
        public struct AsyncIterator: AsyncIteratorProtocol, @unchecked Sendable {
            private var iterator: AsyncThrowingStream<Snapshot, Error>.AsyncIterator
            
            init(stream: AsyncThrowingStream<Snapshot, Error>) {
                self.iterator = stream.makeAsyncIterator()
            }
            
            public mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> Snapshot? {
                return try await iterator.next()
            }
        }
        
        private let stream: AsyncThrowingStream<Snapshot, Error>
        
        init(stream: AsyncThrowingStream<Snapshot, Error>) {
            self.stream = stream
        }
        
        public func makeAsyncIterator() -> AsyncIterator {
            return AsyncIterator(stream: stream)
        }
        
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


extension LanguageModelSession.ResponseStream where Content: Generable {
    
    nonisolated(nonsending) public func collect() async throws -> sending LanguageModelSession.Response<Content> {
        var finalSnapshot: Snapshot?
        let allEntries = ArraySlice<Transcript.Entry>()
        
        for try await snapshot in self {
            finalSnapshot = snapshot
        }
        
        guard let snapshot = finalSnapshot else {
            let context = LanguageModelSession.GenerationError.Context(debugDescription: "Stream completed without any content")
            throw LanguageModelSession.GenerationError.decodingFailure(context)
        }
        
        return LanguageModelSession.Response(
            content: snapshot.content,
            rawContent: snapshot.rawContent,
            transcriptEntries: allEntries
        )
    }
}


extension LanguageModelSession {
    
    public enum GenerationError: Error, LocalizedError, Sendable {
        
        public struct Context: Sendable {
            public let debugDescription: String
            
            public init(debugDescription: String) {
                self.debugDescription = debugDescription
            }
        }
        
        public struct Refusal: Sendable {
            private let transcriptEntries: [Transcript.Entry]
            
            public init(transcriptEntries: [Transcript.Entry]) {
                self.transcriptEntries = transcriptEntries
            }
            
            public var explanation: Response<String> {
                get async throws {
                    return Response(
                        content: "The model refused to generate content for this request.",
                        rawContent: GeneratedContent("The model refused to generate content for this request."),
                        transcriptEntries: ArraySlice(transcriptEntries)
                    )
                }
            }
            
            public var explanationStream: ResponseStream<String> {
                typealias StringSnapshot = ResponseStream<String>.Snapshot
                let stream = AsyncThrowingStream<StringSnapshot, Error> { continuation in
                    continuation.finish()
                }
                return ResponseStream<String>(stream: stream)
            }
        }
        
        case exceededContextWindowSize(Context)
        
        case assetsUnavailable(Context)
        
        case guardrailViolation(Context)
        
        case unsupportedGuide(Context)
        
        case unsupportedLanguageOrLocale(Context)
        
        case decodingFailure(Context)
        
        case rateLimited(Context)
        
        case concurrentRequests(Context)
        
        case refusal(Refusal, Context)
        
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
        
        public var failureReason: String? {
            return errorDescription
        }
    }
    
    public struct ToolCallError: Error, LocalizedError, Sendable {
        
        public var tool: any Tool
        
        public var underlyingError: any Error
        
        public init(tool: any Tool, underlyingError: any Error) {
            self.tool = tool
            self.underlyingError = underlyingError
        }
        
        public var errorDescription: String? {
            return "Tool call error in '\(tool.name)': \(underlyingError.localizedDescription)"
        }
    }
}
