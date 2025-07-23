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
    /// ✅ CONFIRMED: Uses SystemLanguageModel as default
    /// ✅ PHASE 4.1: Now uses LanguageModel protocol for dependency injection
    private let model: LanguageModel
    
    /// Session instructions
    /// ✅ CONFIRMED: Instructions property exists
    public let instructions: Instructions?
    
    /// Available tools for the session
    /// ✅ CONFIRMED: Tools array property
    public let tools: [any Tool]
    
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
        model: SystemLanguageModel = SystemLanguageModel.default,
        guardrails: LanguageModelSession.Guardrails = .default,
        tools: [any Tool] = [],
        instructions: Instructions? = nil
    ) {
        self.init(model: model as LanguageModel)
        // Store guardrails and other parameters
        // Note: Guardrails implementation needed
    }
    
    /// Apple's official convenience initializer with transcript
    /// ✅ APPLE SPEC: convenience init(model:guardrails:tools:transcript:)
    public convenience init(
        model: SystemLanguageModel = SystemLanguageModel.default,
        guardrails: Guardrails = .default,
        tools: [any Tool] = [],
        transcript: Transcript
    ) {
        self.init(model: model as LanguageModel)
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
    public init(model: LanguageModel) {
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
        let promptText = promptValue.segments.map { $0.text }.joined(separator: " ")
        let startTime = Date()
        let content = try await model.generate(prompt: promptText, options: options)
        let duration = Date().timeIntervalSince(startTime)
        
        // Create transcript entry
        let entry = Transcript.Entry(
            prompt: promptText,
            response: content,
            timestamp: Date(),
            duration: duration
        )
        
        return Response(
            content: content,
            transcriptEntries: [entry][...]
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
        let promptText = promptValue.segments.map { $0.text }.joined(separator: " ")
        let startTime = Date()
        
        // Generate schema-guided content
        let schemaPrompt = includeSchemaInPrompt ? 
            "\(promptText)\n\nGenerate response following this schema: \(Content.generationSchema)" : 
            promptText
        
        let text = try await model.generate(prompt: schemaPrompt, options: options)
        let generatedContent = GeneratedContent(text)
        let content = try Content(generatedContent)
        let duration = Date().timeIntervalSince(startTime)
        
        // Create transcript entry
        let entry = Transcript.Entry(
            prompt: promptText,
            response: "\(content)",
            timestamp: Date(),
            duration: duration
        )
        
        return Response(
            content: content,
            transcriptEntries: [entry][...]
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
        let promptText = promptValue.segments.map { $0.text }.joined(separator: " ")
        let startTime = Date()
        
        // Generate schema-guided content
        let schemaPrompt = includeSchemaInPrompt ? 
            "\(promptText)\n\nGenerate response following this schema: \(schema)" : 
            promptText
        
        let text = try await model.generate(prompt: schemaPrompt, options: options)
        let content = GeneratedContent(text)
        let duration = Date().timeIntervalSince(startTime)
        
        // Create transcript entry
        let entry = Transcript.Entry(
            prompt: promptText,
            response: "\(content)",
            timestamp: Date(),
            duration: duration
        )
        
        return Response(
            content: content,
            transcriptEntries: [entry][...]
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
        let promptText = promptValue.segments.map { $0.text }.joined(separator: " ")
        
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
        let promptText = promptValue.segments.map { $0.text }.joined(separator: " ")
        
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
        let promptText = promptValue.segments.map { $0.text }.joined(separator: " ")
        
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