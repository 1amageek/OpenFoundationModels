
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
            var instructionContent = instructions.content
            
            // Add tool schemas to the instructions
            let toolInstructions = formatToolInstructions(for: tools)
            if !toolInstructions.isEmpty {
                instructionContent += toolInstructions
            }
            
            let instructionEntry = Transcript.Entry.instructions(
                Transcript.Instructions(
                    id: UUID().uuidString,
                    segments: [.text(Transcript.TextSegment(
                        id: UUID().uuidString,
                        content: instructionContent
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
    
    
    public struct Response<Content> where Content: Generable {
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
        let promptText = promptValue.content
        
        _isResponding = true
        defer { _isResponding = false }
        
        // Add prompt to transcript
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
        
        // Tool execution loop - continue until we get a response entry
        while true {
            // Get entry from model
            let entry = try await model.generate(
                transcript: _transcript,
                options: options
            )
            
            // Add entry to transcript
            var transcriptEntries = _transcript.entries
            transcriptEntries.append(entry)
            _transcript = Transcript(entries: transcriptEntries)
            
            switch entry {
            case .toolCalls(let toolCalls):
                // Execute tools and continue loop
                try await executeAllToolCalls(toolCalls)
                continue
                
            case .response(let response):
                // Final response - extract content and return
                let content = response.segments.compactMap { segment -> String? in
                    switch segment {
                    case .text(let textSegment):
                        return textSegment.content
                    case .structure(let structuredSegment):
                        return structuredSegment.content.text
                    case .image:
                        return nil
                    }
                }.joined()
                
                let recentEntries = Array(_transcript.entries.suffix(2))
                let entriesSlice = ArraySlice(recentEntries)
                
                return Response(
                    content: content,
                    rawContent: GeneratedContent(content),
                    transcriptEntries: entriesSlice
                )
                
            default:
                throw GenerationError.decodingFailure(
                    GenerationError.Context(
                        debugDescription: "Unexpected entry type: \(entry)"
                    )
                )
            }
        }
    }


    @discardableResult
    nonisolated(nonsending) public final func respond(
        to prompt: Transcript.Prompt
    ) async throws -> Response<String> {
        _isResponding = true
        defer { _isResponding = false }

        // Add prompt directly to transcript
        let promptEntry = Transcript.Entry.prompt(prompt)
        var entries = _transcript.entries
        entries.append(promptEntry)
        _transcript = Transcript(entries: entries)

        // Tool execution loop - continue until we get a response entry
        while true {
            let entry = try await model.generate(
                transcript: _transcript,
                options: prompt.options
            )

            var transcriptEntries = _transcript.entries
            transcriptEntries.append(entry)
            _transcript = Transcript(entries: transcriptEntries)

            switch entry {
            case .toolCalls(let toolCalls):
                try await executeAllToolCalls(toolCalls)
                continue

            case .response(let response):
                let content = response.segments.compactMap { segment -> String? in
                    switch segment {
                    case .text(let textSegment):
                        return textSegment.content
                    case .structure(let structuredSegment):
                        return structuredSegment.content.text
                    case .image:
                        return nil
                    }
                }.joined()

                let recentEntries = Array(_transcript.entries.suffix(2))
                let entriesSlice = ArraySlice(recentEntries)

                return Response(
                    content: content,
                    rawContent: GeneratedContent(content),
                    transcriptEntries: entriesSlice
                )

            default:
                throw GenerationError.decodingFailure(
                    GenerationError.Context(
                        debugDescription: "Unexpected entry type: \(entry)"
                    )
                )
            }
        }
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
        let promptText = promptValue.content
        
        _isResponding = true
        defer { _isResponding = false }
        
        // Add prompt to transcript
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
        
        // Tool execution loop - continue until we get a response entry
        while true {
            // Get entry from model
            let entry = try await model.generate(
                transcript: _transcript,
                options: options
            )
            
            // Add entry to transcript
            var transcriptEntries = _transcript.entries
            transcriptEntries.append(entry)
            _transcript = Transcript(entries: transcriptEntries)
            
            switch entry {
            case .toolCalls(let toolCalls):
                // Execute tools and continue loop
                try await executeAllToolCalls(toolCalls)
                continue
                
            case .response(let response):
                // Final response - extract structured content and return
                var content: GeneratedContent?
                for segment in response.segments {
                    if case .structure(let structuredSegment) = segment {
                        content = structuredSegment.content
                        break
                    } else if case .text(let textSegment) = segment {
                        // Try to parse text as JSON
                        content = try? GeneratedContent(json: textSegment.content)
                    }
                }
                
                guard let finalContent = content else {
                    throw GenerationError.decodingFailure(
                        GenerationError.Context(
                            debugDescription: "Failed to extract structured content from response"
                        )
                    )
                }
                
                let recentEntries = Array(_transcript.entries.suffix(2))
                let entriesSlice = ArraySlice(recentEntries)
                
                return Response(
                    content: finalContent,
                    rawContent: finalContent,
                    transcriptEntries: entriesSlice
                )
                
            default:
                throw GenerationError.decodingFailure(
                    GenerationError.Context(
                        debugDescription: "Unexpected entry type: \(entry)"
                    )
                )
            }
        }
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
        let promptText = promptValue.content
        
        _isResponding = true
        defer { _isResponding = false }
        
        // Add prompt to transcript
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
        
        // Tool execution loop - continue until we get a response entry
        while true {
            // Get entry from model
            let entry = try await model.generate(
                transcript: _transcript,
                options: options
            )
            
            // Add entry to transcript
            var transcriptEntries = _transcript.entries
            transcriptEntries.append(entry)
            _transcript = Transcript(entries: transcriptEntries)
            
            switch entry {
            case .toolCalls(let toolCalls):
                // Execute tools and continue loop
                try await executeAllToolCalls(toolCalls)
                continue
                
            case .response(let response):
                // Final response - extract structured content and return
                var generatedContent: GeneratedContent?
                for segment in response.segments {
                    if case .structure(let structuredSegment) = segment {
                        generatedContent = structuredSegment.content
                        break
                    } else if case .text(let textSegment) = segment {
                        // Try to parse text as JSON
                        generatedContent = try? GeneratedContent(json: textSegment.content)
                    }
                }
                
                guard let finalContent = generatedContent else {
                    throw GenerationError.decodingFailure(
                        GenerationError.Context(
                            debugDescription: "Failed to extract structured content from response"
                        )
                    )
                }
                
                let content = try Content(finalContent)
                
                let recentEntries = Array(_transcript.entries.suffix(2))
                let entriesSlice = ArraySlice(recentEntries)
                
                return Response(
                    content: content,
                    rawContent: finalContent,
                    transcriptEntries: entriesSlice
                )
                
            default:
                throw GenerationError.decodingFailure(
                    GenerationError.Context(
                        debugDescription: "Unexpected entry type: \(entry)"
                    )
                )
            }
        }
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
        appendPromptEntry(
            promptText: promptValue.content,
            options: options,
            responseFormat: nil
        )
        return makeStreamingResponseStream(
            options: options,
            strategy: TextStreamAggregationStrategy()
        )
    }


    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)`` method to
    /// reduce the likelihood of encountering ``LanguageModelSession/GenerationError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - prompt: A prompt for the model to respond to.
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    public final func streamResponse(
        to prompt: String,
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) -> sending ResponseStream<GeneratedContent> {
        return streamResponse(
            schema: schema,
            includeSchemaInPrompt: includeSchemaInPrompt,
            options: options
        ) { Prompt(prompt) }
    }

    /// Produces a response stream to a prompt and schema.
    ///
    /// Consider using the default value of `true` for `includeSchemaInPrompt`.
    /// The exception to the rule is when the model has knowledge about the expected response format, either
    /// because it has been trained on it, or because it has seen exhaustive examples during this session.
    ///
    /// - Important: If running in the background, use the non-streaming
    /// ``LanguageModelSession/respond(to:options:)`` method to
    /// reduce the likelihood of encountering ``LanguageModelSession/GenerationError/rateLimited(_:)`` errors.
    ///
    /// - Parameters:
    ///   - schema: A schema to guide the output with.
    ///   - includeSchemaInPrompt: Inject the schema into the prompt to bias the model.
    ///   - options: Options that control how tokens are sampled from the distribution the model produces.
    ///   - prompt: A prompt for the model to respond to.
    /// - Returns: A response stream that produces ``GeneratedContent`` containing the fields and values defined in the schema.
    public final func streamResponse(
        schema: GenerationSchema,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions(),
        @PromptBuilder prompt: () throws -> Prompt
    ) rethrows -> sending ResponseStream<GeneratedContent> {
        let promptValue = try prompt()
        appendPromptEntry(
            promptText: promptValue.content,
            options: options,
            responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(schema: schema) : nil
        )
        return makeStreamingResponseStream(
            options: options,
            strategy: GeneratedContentStreamAggregationStrategy()
        )
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
        appendPromptEntry(
            promptText: promptValue.content,
            options: options,
            responseFormat: includeSchemaInPrompt ? Transcript.ResponseFormat(type: Content.self) : nil
        )
        return makeStreamingResponseStream(
            options: options,
            strategy: GenerableStreamAggregationStrategy<Content>()
        )
    }

    private protocol StreamAggregationStrategy: Sendable {
        associatedtype OutputContent: Generable

        mutating func makeSnapshot(for entry: Transcript.Entry) -> ResponseStream<OutputContent>.Snapshot?
        mutating func transcriptEntry(for finalEntry: Transcript.Entry) -> Transcript.Entry
    }

    private struct TextStreamAggregationStrategy: StreamAggregationStrategy {
        typealias OutputContent = String

        private var accumulatedContent = ""

        mutating func makeSnapshot(for entry: Transcript.Entry) -> ResponseStream<String>.Snapshot? {
            switch entry {
            case .response(let response):
                for segment in response.segments {
                    switch segment {
                    case .text(let textSegment):
                        accumulatedContent += textSegment.content
                    case .structure(let structuredSegment):
                        accumulatedContent += structuredSegment.content.text
                    case .image:
                        break
                    }
                }
                return ResponseStream<String>.Snapshot(
                    content: accumulatedContent,
                    rawContent: GeneratedContent(accumulatedContent)
                )
            case .toolCalls:
                // Keep yielding the latest accumulated text so UIs can refresh status.
                return ResponseStream<String>.Snapshot(
                    content: accumulatedContent,
                    rawContent: GeneratedContent(accumulatedContent)
                )
            default:
                return nil
            }
        }

        mutating func transcriptEntry(for finalEntry: Transcript.Entry) -> Transcript.Entry {
            guard case .response = finalEntry else { return finalEntry }
            return LanguageModelSession.makeTextResponseEntry(content: accumulatedContent)
        }
    }

    private struct StructuredStreamAccumulator: Sendable {
        private(set) var accumulatedContent: GeneratedContent?
        private var jsonBuffer = ""

        mutating func ingest(_ response: Transcript.Response) {
            for segment in response.segments {
                switch segment {
                case .structure(let structuredSegment):
                    accumulatedContent = structuredSegment.content
                    jsonBuffer = ""
                case .text(let textSegment):
                    ingestTextSegment(textSegment.content)
                case .image:
                    break
                }
            }
        }

        private mutating func ingestTextSegment(_ text: String) {
            jsonBuffer += text
            do {
                accumulatedContent = try GeneratedContent(json: jsonBuffer)
            } catch {
                // Keep partial textual state while JSON is still incomplete.
                accumulatedContent = GeneratedContent(jsonBuffer)
            }
        }
    }

    private struct GeneratedContentStreamAggregationStrategy: StreamAggregationStrategy {
        typealias OutputContent = GeneratedContent

        private var accumulator = StructuredStreamAccumulator()

        mutating func makeSnapshot(for entry: Transcript.Entry) -> ResponseStream<GeneratedContent>.Snapshot? {
            guard case .response(let response) = entry else { return nil }
            accumulator.ingest(response)
            guard let content = accumulator.accumulatedContent else { return nil }
            return ResponseStream<GeneratedContent>.Snapshot(
                content: content,
                rawContent: content
            )
        }

        mutating func transcriptEntry(for finalEntry: Transcript.Entry) -> Transcript.Entry {
            guard case .response = finalEntry,
                  let content = accumulator.accumulatedContent else {
                return finalEntry
            }
            return LanguageModelSession.makeStructuredResponseEntry(content: content)
        }
    }

    private struct GenerableStreamAggregationStrategy<Content: Generable>: StreamAggregationStrategy {
        typealias OutputContent = Content

        private var accumulator = StructuredStreamAccumulator()

        mutating func makeSnapshot(for entry: Transcript.Entry) -> ResponseStream<Content>.Snapshot? {
            guard case .response(let response) = entry else { return nil }
            accumulator.ingest(response)
            guard let generatedContent = accumulator.accumulatedContent else { return nil }

            do {
                let partial = try Content.PartiallyGenerated(generatedContent)
                return ResponseStream<Content>.Snapshot(
                    content: partial,
                    rawContent: generatedContent
                )
            } catch {
                return nil
            }
        }

        mutating func transcriptEntry(for finalEntry: Transcript.Entry) -> Transcript.Entry {
            guard case .response = finalEntry,
                  let content = accumulator.accumulatedContent else {
                return finalEntry
            }
            return LanguageModelSession.makeStructuredResponseEntry(content: content)
        }
    }

    private func makeStreamingResponseStream<Strategy: StreamAggregationStrategy>(
        options: GenerationOptions,
        strategy initialStrategy: Strategy
    ) -> ResponseStream<Strategy.OutputContent> {
        let stream = AsyncThrowingStream<ResponseStream<Strategy.OutputContent>.Snapshot, Error> { continuation in
            Task {
                _isResponding = true
                defer { _isResponding = false }

                var strategy = initialStrategy

                while true {
                    let entryStream = model.stream(
                        transcript: _transcript,
                        options: options
                    )
                    var finalEntry: Transcript.Entry?

                    do {
                        for try await entry in entryStream {
                            finalEntry = entry
                            if let snapshot = strategy.makeSnapshot(for: entry) {
                                continuation.yield(snapshot)
                            }
                        }
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }

                    guard let finalEntry else {
                        continuation.finish(throwing: makeStreamingError(
                            "Model stream ended without entries"
                        ))
                        return
                    }

                    let entryForTranscript = strategy.transcriptEntry(for: finalEntry)
                    appendTranscriptEntry(entryForTranscript)

                    switch entryForTranscript {
                    case .toolCalls(let toolCalls):
                        do {
                            try await executeAllToolCalls(toolCalls)
                            continue
                        } catch {
                            continuation.finish(throwing: error)
                            return
                        }
                    case .response:
                        continuation.finish()
                        return
                    default:
                        continuation.finish(throwing: makeStreamingError(
                            "Unexpected entry type during streaming: \(entryForTranscript)"
                        ))
                        return
                    }
                }
            }
        }

        return ResponseStream(stream: stream)
    }

    private func appendPromptEntry(
        promptText: String,
        options: GenerationOptions,
        responseFormat: Transcript.ResponseFormat?
    ) {
        let promptEntry = Transcript.Entry.prompt(
            Transcript.Prompt(
                id: UUID().uuidString,
                segments: [.text(Transcript.TextSegment(id: UUID().uuidString, content: promptText))],
                options: options,
                responseFormat: responseFormat
            )
        )
        appendTranscriptEntry(promptEntry)
    }

    private func appendTranscriptEntry(_ entry: Transcript.Entry) {
        var entries = _transcript.entries
        entries.append(entry)
        _transcript = Transcript(entries: entries)
    }

    private func makeStreamingError(_ debugDescription: String) -> GenerationError {
        return .decodingFailure(
            GenerationError.Context(
                debugDescription: debugDescription
            )
        )
    }


    // MARK: - Tool Execution
    
    private func executeAllToolCalls(_ toolCalls: Transcript.ToolCalls) async throws {
        let callsArray = Array(toolCalls)

        // Single tool call: sequential execution (backward compatible)
        guard callsArray.count > 1 else {
            for toolCall in callsArray {
                let output = try await executeToolCall(toolCall)
                appendToolOutput(toolCall: toolCall, output: output)
            }
            return
        }

        // Multiple tool calls: parallel execution with best-effort collection
        let results = await withTaskGroup(
            of: (Int, Transcript.ToolCall, Result<String, Error>).self
        ) { group in
            for (index, toolCall) in callsArray.enumerated() {
                group.addTask {
                    do {
                        let output = try await self.executeToolCall(toolCall)
                        return (index, toolCall, .success(output))
                    } catch {
                        return (index, toolCall, .failure(error))
                    }
                }
            }
            var collected: [(Int, Transcript.ToolCall, Result<String, Error>)] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        // Sort by original order
        let sorted = results.sorted { $0.0 < $1.0 }

        // Check if all tools failed
        let failures = sorted.compactMap { (_, _, result) -> Error? in
            if case .failure(let error) = result { return error }
            return nil
        }

        if failures.count == sorted.count {
            throw failures[0]
        }

        // Append results to transcript (success = normal output, failure = error message)
        for (_, toolCall, result) in sorted {
            switch result {
            case .success(let output):
                appendToolOutput(toolCall: toolCall, output: output)
            case .failure(let error):
                let errorMessage = "[Tool Error] \(toolCall.toolName): \(error.localizedDescription)"
                appendToolOutput(toolCall: toolCall, output: errorMessage)
            }
        }
    }

    private func appendToolOutput(toolCall: Transcript.ToolCall, output: String) {
        let outputEntry = Transcript.Entry.toolOutput(
            Transcript.ToolOutput(
                id: UUID().uuidString,
                toolName: toolCall.toolName,
                segments: [.text(Transcript.TextSegment(
                    id: UUID().uuidString,
                    content: output
                ))]
            )
        )
        var entries = _transcript.entries
        entries.append(outputEntry)
        _transcript = Transcript(entries: entries)
    }

    private static func makeTextResponseEntry(content: String) -> Transcript.Entry {
        return .response(
            Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [
                    .text(Transcript.TextSegment(id: UUID().uuidString, content: content))
                ]
            )
        )
    }

    private static func makeStructuredResponseEntry(content: GeneratedContent) -> Transcript.Entry {
        return .response(
            Transcript.Response(
                id: UUID().uuidString,
                assetIDs: [],
                segments: [
                    .structure(
                        Transcript.StructuredSegment(
                            id: UUID().uuidString,
                            source: "generated",
                            content: content
                        )
                    )
                ]
            )
        )
    }
    
    private func executeToolCall(_ toolCall: Transcript.ToolCall) async throws -> String {
        // Find the tool instance from available tools
        guard let tool = self.tools.first(where: { $0.name == toolCall.toolName }) else {
            throw GenerationError.decodingFailure(
                GenerationError.Context(
                    debugDescription: "Tool '\(toolCall.toolName)' not found in available tools"
                )
            )
        }

        do {
            // Use a helper method that can handle the existential type
            return try await executeToolWithHelper(tool, arguments: toolCall.arguments)

        } catch let error as ToolCallError {
            throw error
        } catch {
            throw ToolCallError(tool: tool, underlyingError: error)
        }
    }
    
    private func executeToolWithHelper<T: Tool>(_ tool: T, arguments: GeneratedContent) async throws -> String {
        let typedArguments = try T.Arguments(arguments)
        let output = try await tool.call(arguments: typedArguments)
        return output.promptRepresentation.content
    }
    
    private func formatToolInstructions(for tools: [any Tool]) -> String {
        guard !tools.isEmpty else { return "" }

        var sections: [String] = []
        sections.append("")
        sections.append("# Tools")
        sections.append("In this environment you have access to a set of tools you can use to answer the user's question.")
        sections.append("")
        sections.append("Check that all the required parameters for each tool call are provided or can reasonably be inferred from context. IF there are no relevant tools or there are missing values for required parameters, ask the user to supply these values; otherwise proceed with the tool calls. If the user provides a specific value for a parameter, make sure to use that value EXACTLY.")
        sections.append("")

        for tool in tools {
            var toolSection = "## \(tool.name)\n\n"
            toolSection += tool.description

            if tool.includesSchemaInInstructions {
                toolSection += "\n\n```json\n"
                toolSection += formatJSONSchema(tool.parameters)
                toolSection += "\n```"
            }

            sections.append(toolSection)
        }

        return sections.joined(separator: "\n\n")
    }
    
    private func formatJSONSchema(_ schema: GenerationSchema) -> String {
        // Since GenerationSchema is Codable, we can encode it to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let data = try? encoder.encode(schema),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        // Fallback to debug description
        return schema.debugDescription
    }
    
    /// Logs and serializes a feedback attachment that can be submitted to Apple.
    ///
    /// This method creates a structured feedback attachment containing the session's transcript
    /// and any provided feedback information. The attachment can be saved to a file and submitted
    /// to Apple using Feedback Assistant.
    ///
    /// - Parameters:
    ///   - sentiment: An optional sentiment rating about the model's output (positive, negative, or neutral).
    ///   - issues: An array of specific issues identified with the model's response. Defaults to an empty array.
    ///   - desiredOutput: An optional transcript entry showing what the desired output should have been.
    /// - Returns: A `Data` object containing the JSON-encoded feedback attachment that can be submitted to Feedback Assistant.
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

    /// Logs and serializes a feedback attachment with a desired response text.
    ///
    /// - Parameters:
    ///   - sentiment: An optional sentiment rating about the model's output.
    ///   - issues: An array of specific issues identified with the model's response.
    ///   - desiredResponseText: An optional string showing what the desired response text should have been.
    /// - Returns: A `Data` object containing the JSON-encoded feedback attachment.
    @discardableResult
    public final func logFeedbackAttachment(
        sentiment: LanguageModelFeedback.Sentiment?,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredResponseText: String?
    ) -> Data {
        let desiredOutput: Transcript.Entry?
        if let text = desiredResponseText {
            let textSegment = Transcript.TextSegment(id: UUID().uuidString, content: text)
            let segment = Transcript.Segment.text(textSegment)
            let response = Transcript.Response(id: UUID().uuidString, assetIDs: [], segments: [segment])
            desiredOutput = .response(response)
        } else {
            desiredOutput = nil
        }
        return logFeedbackAttachment(sentiment: sentiment, issues: issues, desiredOutput: desiredOutput)
    }

    /// Logs and serializes a feedback attachment with a desired response content.
    ///
    /// - Parameters:
    ///   - sentiment: An optional sentiment rating about the model's output.
    ///   - issues: An array of specific issues identified with the model's response.
    ///   - desiredResponseContent: An optional content conforming to `ConvertibleToGeneratedContent` showing what the desired response should have been.
    /// - Returns: A `Data` object containing the JSON-encoded feedback attachment.
    @discardableResult
    public final func logFeedbackAttachment(
        sentiment: LanguageModelFeedback.Sentiment?,
        issues: [LanguageModelFeedback.Issue] = [],
        desiredResponseContent: (any ConvertibleToGeneratedContent)?
    ) -> Data {
        let desiredOutput: Transcript.Entry?
        if let content = desiredResponseContent {
            let structuredSegment = Transcript.StructuredSegment(
                id: UUID().uuidString,
                source: String(describing: type(of: content)),
                content: content.generatedContent
            )
            let segment = Transcript.Segment.structure(structuredSegment)
            let response = Transcript.Response(id: UUID().uuidString, assetIDs: [], segments: [segment])
            desiredOutput = .response(response)
        } else {
            desiredOutput = nil
        }
        return logFeedbackAttachment(sentiment: sentiment, issues: issues, desiredOutput: desiredOutput)
    }
}


extension LanguageModelSession {

    /// An async sequence of snapshots of partially generated content.
    public struct ResponseStream<Content> where Content: Generable {

        /// A snapshot of partially generated content.
        public struct Snapshot {

            /// The content of the response.
            public var content: Content.PartiallyGenerated

            /// The raw content of the response.
            ///
            /// When `Content` is `GeneratedContent`, this is the same as `content`.
            public var rawContent: GeneratedContent
        }

        internal let stream: AsyncThrowingStream<Snapshot, Error>

        internal init(stream: AsyncThrowingStream<Snapshot, Error>) {
            self.stream = stream
        }
    }
}

extension LanguageModelSession.ResponseStream: AsyncSequence {

    /// The type of element produced by this asynchronous sequence.
    public typealias Element = Snapshot

    /// The type of asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    public struct AsyncIterator: AsyncIteratorProtocol, @unchecked Sendable {
        private var iterator: AsyncThrowingStream<Snapshot, Error>.AsyncIterator

        internal init(stream: AsyncThrowingStream<Snapshot, Error>) {
            self.iterator = stream.makeAsyncIterator()
        }

        /// Asynchronously advances to the next element and returns it, or ends the
        /// sequence if there is no next element.
        ///
        /// - Returns: The next element, if it exists, or `nil` to signal the end of
        ///   the sequence.
        public mutating func next(isolation actor: isolated (any Actor)? = #isolation) async throws -> Snapshot? {
            return try await iterator.next()
        }

        public typealias Element = Snapshot
    }

    /// Creates the asynchronous iterator that produces elements of this
    /// asynchronous sequence.
    ///
    /// - Returns: An instance of the `AsyncIterator` type used to produce
    /// elements of the asynchronous sequence.
    public func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(stream: stream)
    }

    /// The result from a streaming response, after it completes.
    ///
    /// If the streaming response was finished successfully before calling
    /// `collect()`, this method `Response` returns immediately.
    ///
    /// If the streaming response was finished with an error before calling
    /// `collect()`, this method propagates that error.
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

        // Convert from PartiallyGenerated to full Content
        let content = try Content(snapshot.rawContent)

        return LanguageModelSession.Response(
            content: content,
            rawContent: snapshot.rawContent,
            transcriptEntries: allEntries
        )
    }
}




extension LanguageModelSession {
    
    public enum GenerationError: Error, LocalizedError, Sendable {

        /// The context in which the error occurred.
        public struct Context: Sendable {

            /// A debug description to help developers diagnose issues during development.
            ///
            /// This string is not localized and is not appropriate for display to end users.
            public let debugDescription: String

            /// Creates a context.
            ///
            /// - Parameters:
            ///   - debugDescription: The debug description to help developers diagnose issues during development.
            public init(debugDescription: String) {
                self.debugDescription = debugDescription
            }
        }

        /// A refusal produced by a language model.
        ///
        /// Refusal errors indicate that the model chose not to respond to a prompt. To make the model
        /// explain why it refused, catch the refusal error and access one of its explanation properties.
        public struct Refusal: Sendable {
            private let transcriptEntries: [Transcript.Entry]

            public init(transcriptEntries: [Transcript.Entry]) {
                self.transcriptEntries = transcriptEntries
            }

            /// An explanation for why the model refused to respond.
            public var explanation: Response<String> {
                get async throws {
                    return Response(
                        content: "The model refused to generate content for this request.",
                        rawContent: GeneratedContent("The model refused to generate content for this request."),
                        transcriptEntries: ArraySlice(transcriptEntries)
                    )
                }
            }

            /// A stream containing an explanation about why the model refused to respond.
            public var explanationStream: ResponseStream<String> {
                typealias StringSnapshot = ResponseStream<String>.Snapshot
                let stream = AsyncThrowingStream<StringSnapshot, Error> { continuation in
                    continuation.finish()
                }
                return ResponseStream<String>(stream: stream)
            }
        }

        /// An error that signals the session reached its context window size limit.
        ///
        /// This error occurs when you use the available tokens for the context window of 4,096 tokens. The
        /// token count includes instructions, prompts, and outputs for a session instance. A single token
        /// corresponds to approximately three to four characters in languages like English, Spanish, or
        /// German, and one token per character in languages like Japanese, Chinese, and Korean.
        ///
        /// Start a new session when you exceed the content window size, and try again using a shorter
        /// prompt or shorter output length.
        case exceededContextWindowSize(Context)

        /// An error that indicates the assets required for the session are unavailable.
        ///
        /// This may happen if you forget to check model availability to begin with,
        /// or if the model assets are deleted. This can happen if the user disables
        /// AppleIntelligence while your app is running.
        ///
        /// You may be able to recover from this error by retrying later after the
        /// device has freed up enough space to redownload model assets.
        case assetsUnavailable(Context)

        /// An error that indicates the system's safety guardrails are triggered by content in a
        /// prompt or the response generated by the model.
        case guardrailViolation(Context)

        /// An error that indicates a generation guide with an unsupported pattern was used.
        case unsupportedGuide(Context)

        /// An error that indicates an error that occurs if the model is prompted to respond in a language
        /// that it does not support.
        case unsupportedLanguageOrLocale(Context)

        /// An error that indicates the session failed to deserialize a valid generable type from model output.
        ///
        /// This can happen if generation was terminated early.
        case decodingFailure(Context)

        /// An error that indicates your session has been rate limited.
        ///
        /// This error will only happen if your app is running in the background
        /// and exceeds the system defined rate limit.
        case rateLimited(Context)

        /// An error that happens if you attempt to make a session respond to a
        /// second prompt while it's still responding to the first one.
        case concurrentRequests(Context)

        /// An error indicating that the model refused to answer.
        ///
        /// This error can happen for prompts that do not violate any guardrail policy, but
        /// the model isn't able to provide the kind of response you requested. You can
        /// choose to handle this error by showing a predetermined message of your choice,
        /// or you can use the `Refusal` to generate an explanation from the model itself.
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
