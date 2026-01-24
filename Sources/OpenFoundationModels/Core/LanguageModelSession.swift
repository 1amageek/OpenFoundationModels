
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
            let toolInstructions = generateToolInstructions(for: tools)
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
                throw GenerationError.unexpectedEntryType(
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
                throw GenerationError.unexpectedEntryType(
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
                throw GenerationError.unexpectedEntryType(
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
        let promptText = promptValue.content
        
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
                
                var accumulatedContent = ""
                
                // Tool execution loop - continue until we get a response entry
                while true {
                    let entryStream = model.stream(
                        transcript: _transcript,
                        options: options
                    )
                    var currentEntry: Transcript.Entry?
                    
                    // Process streaming entries
                    do {
                        for try await entry in entryStream {
                            currentEntry = entry

                            switch entry {
                        case .response(let response):
                            // Extract text from response segments and yield
                            for segment in response.segments {
                                switch segment {
                                case .text(let textSegment):
                                    accumulatedContent += textSegment.content
                                case .structure(let structuredSegment):
                                    accumulatedContent += structuredSegment.content.text
                                }
                            }
                            
                            let snapshot = ResponseStream<String>.Snapshot(
                                content: accumulatedContent,
                                rawContent: GeneratedContent(accumulatedContent)
                            )
                            continuation.yield(snapshot)
                            
                        case .toolCalls:
                            // For toolCalls, optionally yield intermediate state
                            let snapshot = ResponseStream<String>.Snapshot(
                                content: accumulatedContent,
                                rawContent: GeneratedContent(accumulatedContent)
                            )
                            continuation.yield(snapshot)
                            
                            default:
                                // Other entries are stored but not yielded
                                break
                            }
                        }
                    } catch {
                        // Forward stream errors
                        continuation.finish(throwing: error)
                        return
                    }
                    
                    // Add entry to transcript and handle based on type
                    if let finalEntry = currentEntry {
                        var transcriptEntries = _transcript.entries
                        transcriptEntries.append(finalEntry)
                        _transcript = Transcript(entries: transcriptEntries)
                        
                        switch finalEntry {
                        case .toolCalls(let toolCalls):
                            // Execute tools and continue loop
                            do {
                                try await executeAllToolCalls(toolCalls)
                                continue // Continue to next iteration
                            } catch {
                                continuation.finish(throwing: error)
                                return
                            }
                            
                        case .response:
                            // Final response received - end streaming
                            continuation.finish()
                            return
                            
                        default:
                            continuation.finish(throwing: GenerationError.unexpectedEntryType(
                                GenerationError.Context(
                                    debugDescription: "Unexpected entry type during streaming: \(finalEntry)"
                                )
                            ))
                            return
                        }
                    }
                }
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
        let promptText = promptValue.content

        // Add prompt to transcript (outside the loop, done once)
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

        let stream = AsyncThrowingStream<ResponseStream<GeneratedContent>.Snapshot, Error> { continuation in
            Task {
                _isResponding = true
                defer { _isResponding = false }

                var accumulatedContent: GeneratedContent?

                // Tool execution loop - continue until we get a response entry
                while true {
                    let entryStream = model.stream(
                        transcript: _transcript,
                        options: options
                    )
                    var currentEntry: Transcript.Entry?

                    // Process streaming entries
                    do {
                        for try await entry in entryStream {
                            currentEntry = entry

                            switch entry {
                            case .response(let response):
                                // Extract structured content from response
                                for segment in response.segments {
                                    if case .structure(let structuredSegment) = segment {
                                        accumulatedContent = structuredSegment.content
                                    } else if case .text(let textSegment) = segment {
                                        // Try to parse as JSON or use as is
                                        accumulatedContent = try? GeneratedContent(json: textSegment.content)
                                        if accumulatedContent == nil {
                                            accumulatedContent = GeneratedContent(textSegment.content)
                                        }
                                    }
                                }

                                if let content = accumulatedContent {
                                    let snapshot = ResponseStream<GeneratedContent>.Snapshot(
                                        content: content,
                                        rawContent: content
                                    )
                                    continuation.yield(snapshot)
                                }

                            case .toolCalls:
                                // Tool calls will be handled after stream ends
                                break

                            default:
                                break
                            }
                        }
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }

                    // Add entry to transcript and handle based on type
                    if let finalEntry = currentEntry {
                        var transcriptEntries = _transcript.entries
                        transcriptEntries.append(finalEntry)
                        _transcript = Transcript(entries: transcriptEntries)

                        switch finalEntry {
                        case .toolCalls(let toolCalls):
                            // Execute tools and continue loop
                            do {
                                try await executeAllToolCalls(toolCalls)
                                continue // Continue to next iteration
                            } catch {
                                continuation.finish(throwing: error)
                                return
                            }

                        case .response:
                            // Final response received - end streaming
                            continuation.finish()
                            return

                        default:
                            continuation.finish(throwing: GenerationError.unexpectedEntryType(
                                GenerationError.Context(
                                    debugDescription: "Unexpected entry type during streaming: \(finalEntry)"
                                )
                            ))
                            return
                        }
                    }
                }
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
        let promptText = promptValue.content

        typealias PartialContent = Content.PartiallyGenerated

        // Add prompt to transcript (outside the loop, done once)
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

        let stream = AsyncThrowingStream<ResponseStream<Content>.Snapshot, Error> { continuation in
            Task {
                _isResponding = true
                defer { _isResponding = false }

                var accumulatedContent: GeneratedContent?

                // Tool execution loop - continue until we get a response entry
                while true {
                    let entryStream = model.stream(
                        transcript: _transcript,
                        options: options
                    )
                    var currentEntry: Transcript.Entry?

                    // Process streaming entries
                    do {
                        
                        var jsonBuffer: String = ""
                        for try await entry in entryStream {
                            currentEntry = entry

                            switch entry {
                            case .response(let response):
                                // Extract structured content from response
                                for segment in response.segments {
                                    if case .structure(let structuredSegment) = segment {
                                        accumulatedContent = structuredSegment.content
                                    } else if case .text(let textSegment) = segment {
//                                        
                                        jsonBuffer = jsonBuffer + textSegment.content
                                
                                        // Try to parse as JSON
                                        accumulatedContent = try? GeneratedContent(json: jsonBuffer)

                                        if accumulatedContent == nil {
                                            accumulatedContent = GeneratedContent(textSegment.content)
                                        }
                                    }
                                }

                                if let generatedContent = accumulatedContent {
                                    // Try to parse as PartialContent and yield
                                    if let partialData = try? PartialContent(generatedContent) {
                                        let snapshot = ResponseStream<Content>.Snapshot(
                                            content: partialData,
                                            rawContent: generatedContent
                                        )
                                        continuation.yield(snapshot)
                                    }
                                }

                            case .toolCalls:
                                // Tool calls will be handled after stream ends
                                break

                            default:
                                break
                            }
                        }
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }

                    // Add entry to transcript and handle based on type
                    if let finalEntry = currentEntry {
                        var transcriptEntries = _transcript.entries
                        transcriptEntries.append(finalEntry)
                        _transcript = Transcript(entries: transcriptEntries)

                        switch finalEntry {
                        case .toolCalls(let toolCalls):
                            // Execute tools and continue loop
                            do {
                                try await executeAllToolCalls(toolCalls)
                                continue // Continue to next iteration
                            } catch {
                                continuation.finish(throwing: error)
                                return
                            }

                        case .response:
                            // Final response received - end streaming
                            continuation.finish()
                            return

                        default:
                            continuation.finish(throwing: GenerationError.unexpectedEntryType(
                                GenerationError.Context(
                                    debugDescription: "Unexpected entry type during streaming: \(finalEntry)"
                                )
                            ))
                            return
                        }
                    }
                }
            }
        }

        return ResponseStream(stream: stream)
    }
    
    
    // MARK: - Tool Execution
    
    private func executeAllToolCalls(_ toolCalls: Transcript.ToolCalls) async throws {
        for toolCall in toolCalls {
            let output = try await executeToolCall(toolCall)
            
            // Add tool output to transcript
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
    }
    
    private func executeToolCall(_ toolCall: Transcript.ToolCall) async throws -> String {
        // Find the tool instance from available tools
        guard let tool = self.tools.first(where: { $0.name == toolCall.toolName }) else {
            throw GenerationError.toolNotFound(
                toolCall.toolName,
                GenerationError.Context(
                    debugDescription: "Tool '\(toolCall.toolName)' not found in available tools"
                )
            )
        }
        
        do {
            // Use a helper method that can handle the existential type
            return try await executeToolWithHelper(tool, arguments: toolCall.arguments)
            
        } catch {
            throw GenerationError.toolExecutionFailed(
                toolCall.toolName,
                error,
                GenerationError.Context(
                    debugDescription: "Failed to execute tool '\(toolCall.toolName)': \(error.localizedDescription)"
                )
            )
        }
    }
    
    private func executeToolWithHelper<T: Tool>(_ tool: T, arguments: GeneratedContent) async throws -> String {
        let typedArguments = try T.Arguments(arguments)
        let output = try await tool.call(arguments: typedArguments)
        return output.promptRepresentation.content
    }
    
    private func generateToolInstructions(for tools: [any Tool]) -> String {
        guard !tools.isEmpty else { return "" }
        
        var instructions = "\n\n## Available Tools\n"
        
        for tool in tools {
            instructions += "\n### Tool: \(tool.name)\n"
            instructions += "Description: \(tool.description)\n"
            
            if tool.includesSchemaInInstructions {
                instructions += "Parameters:\n```json\n"
                instructions += formatJSONSchema(tool.parameters)
                instructions += "\n```\n"
            }
        }
        
        return instructions
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
    
    public struct ResponseStream<Content>: AsyncSequence where Content: Generable {
        
        public struct Snapshot {
            public var content: Content.PartiallyGenerated
            
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
            
            // Convert from PartiallyGenerated to full Content
            let content = try Content(snapshot.rawContent)
            
            return Response(
                content: content,
                rawContent: snapshot.rawContent,
                transcriptEntries: allEntries
            )
        }
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
        
        case toolNotFound(String, Context)
        
        case toolExecutionFailed(String, Error, Context)
        
        case unexpectedEntryType(Context)
        
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
            case .toolNotFound(let toolName, let context):
                return "Tool not found: '\(toolName)' - \(context.debugDescription)"
            case .toolExecutionFailed(let toolName, let error, let context):
                return "Tool execution failed: '\(toolName)' - \(error.localizedDescription) - \(context.debugDescription)"
            case .unexpectedEntryType(let context):
                return "Unexpected entry type: \(context.debugDescription)"
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
            case .toolNotFound:
                return "Ensure the tool is included in the session's tools array."
            case .toolExecutionFailed:
                return "Check the tool arguments and implementation for errors."
            case .unexpectedEntryType:
                return "This is likely an internal error - please report if persistent."
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
