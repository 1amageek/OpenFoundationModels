import Foundation

/// A stateful session for interacting with a language model
public actor LanguageModelSession {
    /// The underlying language model
    private let model: LanguageModel
    
    /// Session instructions
    public let instructions: Instructions?
    
    /// Available tools
    public let tools: [any Tool]
    
    /// Conversation transcript
    public let transcript: Transcript
    
    /// Whether the session is currently responding
    private(set) public var isResponding: Bool = false
    
    /// Session configuration
    public let configuration: SessionConfiguration
    
    /// Initialize a new session
    /// - Parameters:
    ///   - model: The language model to use (defaults to system model)
    ///   - instructions: Optional system instructions
    ///   - tools: Available tools for the session
    ///   - configuration: Session configuration
    public init(
        model: LanguageModel? = nil,
        instructions: Instructions? = nil,
        tools: [any Tool] = [],
        configuration: SessionConfiguration = .default
    ) {
        self.model = model ?? SystemLanguageModel.default
        self.instructions = instructions
        self.tools = tools
        self.transcript = Transcript(maxTokens: configuration.maxTokens)
        self.configuration = configuration
    }
    
    /// Convenience initializer with just instructions
    public init(_ instructions: Instructions) {
        self.init(instructions: instructions)
    }
    
    /// Generate a response to a prompt
    /// - Parameters:
    ///   - prompt: The user prompt
    ///   - options: Generation options
    /// - Returns: The generated response
    public func respond(to prompt: Prompt, options: GenerationOptions? = nil) async throws -> Response {
        guard !isResponding else {
            throw LanguageModelError.invalidInput("Session is already responding")
        }
        
        isResponding = true
        defer { isResponding = false }
        
        // Add user message to transcript
        await transcript.add(.user(prompt.text))
        
        // Build full prompt with context
        let fullPrompt = await buildFullPrompt(with: prompt)
        
        // Generate response
        let content = try await model.generate(
            prompt: fullPrompt,
            options: options ?? configuration.defaultOptions
        )
        
        // Add assistant response to transcript
        await transcript.add(.assistant(content))
        
        return Response(content: content)
    }
    
    /// Stream a response to a prompt
    /// - Parameters:
    ///   - prompt: The user prompt
    ///   - options: Generation options
    /// - Returns: An async stream of partial responses
    public func streamResponse(
        to prompt: Prompt,
        options: GenerationOptions? = nil
    ) -> AsyncThrowingStream<PartialResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard !isResponding else {
                    continuation.finish(throwing: LanguageModelError.invalidInput("Session is already responding"))
                    return
                }
                
                isResponding = true
                defer { isResponding = false }
                
                // Add user message to transcript
                await transcript.add(.user(prompt.text))
                
                // Build full prompt with context
                let fullPrompt = await buildFullPrompt(with: prompt)
                
                // Stream response
                let stream = model.stream(
                    prompt: fullPrompt,
                    options: options ?? configuration.defaultOptions
                )
                
                var accumulated = ""
                
                do {
                    for try await delta in stream {
                        accumulated += delta
                        let partial = PartialResponse(
                            delta: delta,
                            isComplete: false,
                            accumulated: accumulated
                        )
                        continuation.yield(partial)
                    }
                    
                    // Add complete response to transcript
                    await transcript.add(.assistant(accumulated))
                    
                    // Send final partial
                    continuation.yield(PartialResponse(
                        delta: "",
                        isComplete: true,
                        accumulated: accumulated
                    ))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Stream a structured response
    /// - Parameters:
    ///   - prompt: The user prompt
    ///   - type: The type to generate
    ///   - options: Generation options
    /// - Returns: An async stream of partially generated instances
    public func streamResponse<T: Generable>(
        to prompt: Prompt,
        generating type: T.Type,
        options: GenerationOptions? = nil
    ) -> AsyncThrowingStream<PartiallyGenerated<T>, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // Add schema information to prompt
                let schemaPrompt = Prompt(
                    prompt.text + "\n\nGenerate response as JSON matching schema: \(T.schema)",
                    metadata: prompt.metadata
                )
                
                let stream = streamResponse(to: schemaPrompt, options: options)
                
                do {
                    for try await partial in stream {
                        guard let accumulated = partial.accumulated else { continue }
                        
                        // Try to parse partial JSON
                        if let instance = try? T.fromGeneratedContent(accumulated) {
                            continuation.yield(PartiallyGenerated(
                                partial: instance,
                                isComplete: partial.isComplete,
                                rawContent: accumulated
                            ))
                        } else {
                            continuation.yield(PartiallyGenerated(
                                partial: nil,
                                isComplete: false,
                                rawContent: accumulated
                            ))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Prewarm the model to reduce initial latency
    public func prewarm() async throws {
        _ = try await model.generate(
            prompt: "Hello",
            options: GenerationOptions(maxTokens: 1)
        )
    }
    
    // MARK: - Private
    
    private func buildFullPrompt(with prompt: Prompt) async -> String {
        var parts: [String] = []
        
        // Add instructions
        if let instructions = instructions {
            parts.append("System: \(instructions.text)")
        }
        
        // Add tool descriptions
        if !tools.isEmpty {
            let toolDescriptions = tools.map { tool in
                "Tool: \(tool.name) - \(tool.description)"
            }.joined(separator: "\n")
            parts.append("Available tools:\n\(toolDescriptions)")
        }
        
        // Add recent transcript
        let recentEntries = await transcript.lastEntries(configuration.contextWindowSize)
        if !recentEntries.isEmpty {
            let history = recentEntries.map { entry in
                "\(entry.role.rawValue.capitalized): \(entry.content ?? "")"
            }.joined(separator: "\n")
            parts.append("Conversation history:\n\(history)")
        }
        
        // Add current prompt
        parts.append("User: \(prompt.text)")
        
        return parts.joined(separator: "\n\n")
    }
}

/// Configuration for a language model session
public struct SessionConfiguration: Sendable {
    /// Maximum tokens in transcript
    public let maxTokens: Int
    
    /// Number of recent entries to include in context
    public let contextWindowSize: Int
    
    /// Default generation options
    public let defaultOptions: GenerationOptions
    
    /// Whether to automatically handle tool calls
    public let autoExecuteTools: Bool
    
    public init(
        maxTokens: Int = 4096,
        contextWindowSize: Int = 20,
        defaultOptions: GenerationOptions = GenerationOptions(),
        autoExecuteTools: Bool = true
    ) {
        self.maxTokens = maxTokens
        self.contextWindowSize = contextWindowSize
        self.defaultOptions = defaultOptions
        self.autoExecuteTools = autoExecuteTools
    }
    
    /// Default configuration
    public static let `default` = SessionConfiguration()
}