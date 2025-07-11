# OpenFoundationModels

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An open-source Swift implementation of Apple's Foundation Models framework, enabling developers to use Foundation Models APIs without depending on Apple platforms or Apple Intelligence.

⚠️ **IMPORTANT**: This project aims for **100% API compatibility** with Apple's Foundation Models. Users should be able to switch from `import FoundationModels` to `import OpenFoundationModels` with **zero code changes**.

## Overview

OpenFoundationModels is a complete OSS reimplementation of Apple's Foundation Models framework introduced at WWDC 2025. It provides the exact same developer experience and API surface while being platform-agnostic and extensible to work with various LLM providers like OpenAI, Anthropic, and local models.

**Current Status**: Pre-1.0 - Major API changes in progress to achieve Apple compatibility

### Key Features

- 🚀 **Swift 6.1+ Native**: Built with modern Swift concurrency (async/await, actors)
- 🔒 **Privacy-First**: Designed for on-device processing (when providers support it)
- 📱 **Cross-Platform**: iOS, macOS, tvOS, watchOS, visionOS support
- 🛠 **Tool Integration**: Function calling with parallel execution
- 📊 **Structured Generation**: Type-safe JSON generation with Swift types
- 🌊 **Streaming Support**: Real-time response streaming with backpressure handling
- 🧠 **Session Management**: Stateful conversations with automatic context management

## Installation

### Swift Package Manager

Add OpenFoundationModels to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/OpenFoundationModels.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/1amageek/OpenFoundationModels.git`

## Quick Start

### Basic Usage

```swift
import OpenFoundationModels

// Check model availability
let model = SystemLanguageModel.default
let status = await model.availability

guard status.isAvailable else {
    print("Model not available: \(status)")
    return
}

// Create a session
let session = LanguageModelSession()

// Generate a response
let response = try await session.respond(to: "Hello, world!")
print(response.content)
```

### Streaming Responses

```swift
let stream = session.streamResponse(to: "Tell me a story")

for try await partial in stream {
    print(partial.delta, terminator: "")
    if partial.isComplete {
        print("\n--- Complete ---")
    }
}
```

### Structured Generation

```swift
// Define your structure (macro support coming soon)
struct Recipe: Generable {
    let name: String
    let ingredients: [String]
    let prepTimeMinutes: Int
    
    // Manual schema implementation for now
    static var schema: JSONSchema {
        JSONSchema(
            type: .object,
            properties: [
                "name": JSONSchema(type: .string, description: "Recipe name"),
                "ingredients": JSONSchema(type: .array, description: "List of ingredients"),
                "prepTimeMinutes": JSONSchema(type: .integer, description: "Preparation time")
            ],
            required: ["name", "ingredients", "prepTimeMinutes"]
        )
    }
    
    static func fromGeneratedContent(_ content: String) throws -> Recipe {
        // JSON decoding implementation
        // ...
    }
    
    func toGeneratedContent() throws -> String {
        // JSON encoding implementation
        // ...
    }
}

// Generate structured data
let stream = session.streamResponse(
    to: "Create a simple pasta recipe",
    generating: Recipe.self
)

for try await partial in stream {
    if let recipe = partial.partial {
        print("Current recipe: \(recipe)")
    }
}
```

### Tool Calling

```swift
struct WeatherTool: Tool {
    typealias Arguments = WeatherArgs
    
    var name = "get_weather"
    var description = "Get current weather for a city"
    
    func call(arguments: WeatherArgs) async throws -> ToolOutput {
        // Fetch weather data
        let weather = try await fetchWeather(for: arguments.city)
        return ToolOutput(content: "Weather in \(arguments.city): \(weather)")
    }
}

struct WeatherArgs: Generable {
    let city: String
    
    // Schema implementation...
}

// Session with tools
let session = LanguageModelSession(tools: [WeatherTool()])
let response = try await session.respond(to: "What's the weather in Tokyo?")
```

### Custom Instructions

```swift
let instructions = Instructions("""
    You are a helpful assistant that always responds in a friendly tone.
    Keep responses concise and accurate.
""", priority: .high)

let session = LanguageModelSession(instructions: instructions)
```

## Architecture

### Core Components

- **`SystemLanguageModel`**: Singleton access to the default model
- **`LanguageModelSession`**: Stateful conversation management with tools
- **`Transcript`**: Thread-safe conversation history with automatic compaction
- **`LanguageModel`**: Protocol for model implementations
- **`Generable`**: Protocol for structured data generation
- **`Tool`**: Protocol for function calling

### Session Management

Sessions automatically handle:
- Context window management (4096 token default)
- Tool execution and response integration
- Error recovery and retry logic
- Memory optimization with transcript compaction

### Concurrency Model

Built with Swift 6.1 concurrency:
- `actor Transcript` for thread-safe history management
- `actor LanguageModelSession` for session state
- Structured concurrency for tool execution
- `AsyncThrowingStream` for streaming responses

## Provider Integration

Currently includes placeholder implementations. Provider adapters can be added for:

- **OpenAI** (GPT-3.5, GPT-4, etc.)
- **Anthropic** (Claude family)
- **Local Models** (Ollama, llama.cpp, etc.)
- **Apple Intelligence** (when available)

## Configuration

### Session Configuration

```swift
let config = SessionConfiguration(
    maxTokens: 8192,
    contextWindowSize: 30,
    defaultOptions: GenerationOptions(
        temperature: 0.7,
        maxTokens: 1000
    ),
    autoExecuteTools: true
)

let session = LanguageModelSession(configuration: config)
```

### Generation Options

```swift
let options = GenerationOptions(
    temperature: 0.8,
    topP: 0.9,
    maxTokens: 500,
    samplingMethod: .random
)

let response = try await session.respond(to: prompt, options: options)
```

## Development

### Building

```bash
swift build
```

### Testing

```bash
swift test
```

### Documentation

Documentation is built with DocC:

```bash
swift package generate-documentation
```

## Roadmap to Version 1.0

### Current Status (Pre-1.0)
- [x] Core API structure implemented
- [x] Basic types and protocols defined
- [ ] **Apple API compliance fixes** (breaking changes needed)
- [ ] Working macro implementation (`@Generable`, `@Guide`)
- [ ] At least one working LLM provider integration
- [ ] Comprehensive test coverage
- [ ] Complete documentation

### Version 1.0 Requirements
- [ ] 100% Apple Foundation Models API compliance
- [ ] Functional `@Generable` and `@Guide` macros
- [ ] OpenAI provider integration
- [ ] Full streaming support
- [ ] Tool calling functionality
- [ ] Production-ready error handling
- [ ] Complete API documentation
- [ ] Migration guide from current API

### Post-1.0 Features
Future versions will add:
- Additional LLM providers (Anthropic, local models)
- Advanced tool orchestration
- Performance optimizations
- Enterprise features

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Clone the repository
2. Open in Xcode or use Swift Package Manager
3. Run tests to ensure everything works
4. Make your changes
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple for the Foundation Models framework design and API
- The Swift community for excellent concurrency and macro tools
- Contributors and early adopters

## Related Projects

- [Swift OpenAI](https://github.com/MacPaw/OpenAI) - OpenAI API client
- [LangChain Swift](https://github.com/bukowskidev/langchain-swift) - LangChain for Swift
- [Ollama Swift](https://github.com/kevinhermawan/OllamaKit) - Ollama client for Swift

---

**Note**: This is an independent open-source implementation and is not affiliated with Apple Inc. Apple, Foundation Models, and related trademarks are property of Apple Inc.