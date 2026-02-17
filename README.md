# OpenFoundationModels

[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2026%2B%20%7C%20macOS%2026%2B%20%7C%20visionOS%2026%2B-blue.svg)](https://developer.apple.com)
[![Tests](https://img.shields.io/badge/Tests-328%20passing-brightgreen.svg)](#testing)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/1amageek/OpenFoundationModels)

**100% Apple Foundation Models β SDK Compatible Implementation**

OpenFoundationModels is a complete **open-source implementation** of Apple's Foundation Models framework (iOS 26.0+/macOS 26.0+), providing 100% API compatibility while enabling integration with any LLM provider.

## Why OpenFoundationModels?

### Apple Foundation Models Limitations

Apple Foundation Models is an excellent framework, but has significant limitations:

- **Apple Intelligence Required**: Only available on Apple Intelligence-enabled devices
- **Apple Platform Exclusive**: Works only on iOS 26+, macOS 15+
- **Provider Locked**: Only Apple-provided models supported
- **On-Device Only**: No integration with external LLM services

### OpenFoundationModels Value

OpenFoundationModels solves these limitations as an **Apple-compatible alternative implementation**:

```swift
// Apple Foundation Models (Apple ecosystem only)
#if canImport(FoundationModels)
import FoundationModels
let model = SystemLanguageModel.default
#else
// OpenFoundationModels with any provider
import OpenFoundationModels
import OpenFoundationModelsOpenAI  // or MLX, Anthropic, etc.
let model = OpenAILanguageModel(apiKey: "your-key")
#endif

// 🎯 100% API Compatible - Same code works with any backend
let session = LanguageModelSession(model: model) {
    Instructions("You are a helpful assistant")
}
```

**✅ Apple Official API Compliant**: Same API as Apple Foundation Models
**✅ Provider Freedom**: OpenAI, Anthropic, MLX, Ollama, and more
**✅ Seamless Migration**: Switch between Apple's model and third-party providers
**✅ Enterprise Ready**: Integrates with existing infrastructure

## Quick Start

Get started with [AnyFoundationModels](https://github.com/1amageek/AnyFoundationModels):

### Basic Usage

```swift
import OpenFoundationModels
import ClaudeFoundationModels  // Or ResponseFoundationModels, OllamaFoundationModels, MLXFoundationModels

// Create a model from any provider
let model = ClaudeLanguageModel(
    configuration: ClaudeConfiguration(apiKey: "sk-..."),
    modelName: "claude-sonnet-4-5-20250929"
)

// Apple-compatible API works with any backend
let session = LanguageModelSession(model: model) {
    Instructions("You are a helpful assistant")
}

let response = try await session.respond {
    Prompt("Hello, OpenFoundationModels!")
}
print(response.content)
```

## Key Features

✅ **100% Apple API Compatible** - Same API as Apple Foundation Models
✅ **Transcript-Centric Design** - Apple's official conversation management system
✅ **Provider Freedom** - OpenAI, Anthropic, MLX, Ollama, or any LLM provider
✅ **Structured Generation** - Type-safe data with `@Generable` macro
✅ **Real-time Streaming** - Responsive UI with partial updates
✅ **Tool Calling** - Let LLMs execute your functions
✅ **Production Ready** - 328 tests passing, memory efficient, thread-safe

## Installation

### Recommended: AnyFoundationModels (All-in-One)

[**AnyFoundationModels**](https://github.com/1amageek/AnyFoundationModels) is the recommended way to use OpenFoundationModels with LLM providers. It bundles the core framework and all backends (Claude, OpenAI, Ollama, MLX) in a single package with trait-gated compilation.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/1amageek/AnyFoundationModels.git", branch: "main"),
]

// Enable only the backends you need via traits:
targets: [
    .executableTarget(
        name: "MyApp",
        dependencies: [
            .product(name: "OpenFoundationModels", package: "AnyFoundationModels"),
            .product(name: "ClaudeFoundationModels", package: "AnyFoundationModels",
                     condition: .when(traits: ["Claude"])),
            .product(name: "ResponseFoundationModels", package: "AnyFoundationModels",
                     condition: .when(traits: ["Response"])),
            .product(name: "OllamaFoundationModels", package: "AnyFoundationModels",
                     condition: .when(traits: ["Ollama"])),
            .product(name: "MLXFoundationModels", package: "AnyFoundationModels",
                     condition: .when(traits: ["MLX"])),
        ]
    )
]
```

```bash
# Build with the backends you need
swift build --traits Claude,Response,Ollama
```

### Core Framework Only

If you only need the core framework (protocols, macros, session management) without any provider backends:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/1amageek/OpenFoundationModels.git", from: "1.0.0"),
]
```

## Usage

### 1. Basic Text Generation

```swift
import OpenFoundationModels
import OpenFoundationModelsOpenAI  // Or MLX, Anthropic, etc.

// Create model from your chosen provider
let model = OpenAILanguageModel(apiKey: "your-key")

// Check model availability
guard model.isAvailable else {
    print("Model not available")
    return
}

// Create session with instructions (Apple Official API)
// Instructions and tools are stored in Transcript as the first entry
let session = LanguageModelSession(model: model) {
    Instructions("You are a helpful assistant")
}

// Apple Official closure-based prompt
// Each prompt is added to the Transcript, maintaining full conversation history
let response = try await session.respond {
    Prompt("Tell me about Swift 6.2 new features")
}

print(response.content)

// Access the complete conversation history via Transcript
print("Total conversation entries: \(session.transcript.count)")
```

### 2. Type-Safe Structured Generation

```swift
// Define your data structure with validation rules
@Generable
struct ProductReview {
    @Guide(description: "Product name", .pattern("^[A-Za-z0-9\\s]+$"))
    let productName: String
    
    @Guide(description: "Rating from 1 to 5", .range(1...5))
    let rating: Int
    
    @Guide(description: "Review between 50-500 chars", .count(50...500))
    let comment: String
    
    @Guide(description: "Recommendation level", .anyOf(["Highly Recommend", "Recommend", "Neutral", "Not Recommend"]))
    let recommendation: String
}

// LLM generates validated, type-safe data
let response = try await session.respond(
    generating: ProductReview.self
) {
    Prompt("Generate a review for iPhone 15 Pro")
}

// Direct property access - no JSON parsing needed!
print("Product: \(response.content.productName)")
print("Rating: \(response.content.rating)/5")
print("Comment: \(response.content.comment)")
```

### 3. Streaming Responses

```swift
// Apple Official streaming API
let stream = session.streamResponse {
    Prompt("Explain the history of Swift programming language in detail")
}

for try await snapshot in stream {
    print(snapshot.content, terminator: "")
}

// The stream completes when generation is done
let finalResponse = try await stream.collect()
print("\n--- Generation Complete ---")
```

### 4. Stream Complex Data Structures

```swift
@Generable
struct BlogPost {
    let title: String
    let content: String
    let tags: [String]
}

let stream = session.streamResponse(
    generating: BlogPost.self
) {
    Prompt("Write a blog post about Swift Concurrency")
}

for try await partial in stream {
    if let post = partial.content as? BlogPost {
        print("Title: \(post.title)")
        print("Progress: \(post.content.count) characters")
    }
    
    // Stream continues until completion
}

// Collect final response when stream ends
let finalArticle = try await stream.collect()
print("Article generation complete!")
print("Final article: \(finalArticle.content)"
}
```

### 5. Function Calling (Tools)

```swift
// Define a tool that LLMs can call
struct WeatherTool: Tool {
    static let name = "get_weather"
    static let description = "Get current weather for a city"
    
    // Type-safe arguments
    @Generable
    struct Arguments {
        @Guide(description: "City name")
        let city: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        // Your actual API call here
        let weather = try await weatherAPI.fetch(city: arguments.city)
        return ToolOutput("Weather in \(arguments.city): \(weather)°C")
    }
}

// LLM decides when to call tools
let session = LanguageModelSession(
    model: model,  // Any LanguageModel provider
    tools: [WeatherTool()]
) {
    Instructions("You are a helpful assistant that can check weather")
}

let response = try await session.respond {
    Prompt("What's the weather in Tokyo and Paris?")
}
// LLM calls WeatherTool twice and combines results
// Output: "Tokyo is 22°C and sunny, while Paris is 15°C with clouds."
```

### 6. Generation Control & Response Format

```swift
// Fine-tune generation behavior
let options = GenerationOptions(
    sampling: .greedy,                    // Deterministic output
    // sampling: .random(top: 50, seed: 42), // Top-K sampling
    // sampling: .random(probabilityThreshold: 0.9, seed: nil), // Top-P sampling
    temperature: 0.7,                     // Creativity level (0.0-1.0)
    maximumResponseTokens: 500            // Length limit
)

// Apply custom instructions
let session = LanguageModelSession(model: model) {
    Instructions("""
        You are a Swift expert.
        Use modern Swift 6.2+ features.
        Include error handling in all examples.
        """)
}

let response = try await session.respond(options: options) {
    Prompt("Write a networking function")
}

// Response Format for structured output
// ResponseFormat is automatically set when using respond(generating:)
@Generable
struct CodeReview {
    let summary: String
    let issues: [Issue]
    let rating: Int
}

// When using respond(generating:), ResponseFormat is automatically included
let review = try await session.respond(generating: CodeReview.self) {
    Prompt("Review this Swift code: \(code)")
}
// Internally sets: responseFormat: Transcript.ResponseFormat(type: CodeReview.self)

// Or explicitly with schema
let schema = GenerationSchema(
    type: CodeReview.self,
    description: "Code review structure",
    properties: [...]
)

let review = try await session.respond(to: prompt, schema: schema)
// Internally sets: responseFormat: Transcript.ResponseFormat(schema: schema)
```

### 7. Use Any LLM Provider

```swift
import OpenFoundationModels

// Same API, different providers - all using Transcript-based interface
// Use AnyFoundationModels to access all backends
import ClaudeFoundationModels
let claude = ClaudeLanguageModel(
    configuration: ClaudeConfiguration(apiKey: "sk-..."),
    modelName: "claude-sonnet-4-5-20250929"
)

import OllamaFoundationModels
let ollama = OllamaLanguageModel(
    configuration: OllamaConfiguration(),
    modelName: "llama3.2"
)

// Write once, run with any provider
let session = LanguageModelSession(model: claude)  // Or ollama, or any LanguageModel
let response = try await session.respond {
    Prompt("Explain quantum computing")
}

// All advanced features work with all providers
@Generable
struct Analysis {
    let summary: String
    let keyPoints: [String]
    let confidence: Double
}

let analysis = try await session.respond(
    generating: Analysis.self
) {
    Prompt("Analyze this code: \(codeSnippet)")
}
```

## Real-World Use Cases

### 🤖 AI Chatbots
```swift
// Build chatbots that work with any provider
let chatbot = LanguageModelSession(model: model) {
    Instructions("You are a helpful chatbot assistant")
}
let response = try await chatbot.respond {
    Prompt(userMessage)
}
```

### 📊 Data Extraction
```swift
// Extract structured data from unstructured text
@Generable
struct Invoice {
    let invoiceNumber: String
    let totalAmount: Double
    let items: [LineItem]
}

let invoice = try await session.respond(generating: Invoice.self) {
    Prompt("Extract invoice data from: \(pdfText)")
}
```

### 🔍 Content Analysis
```swift
// Analyze and categorize content
@Generable
struct ContentAnalysis {
    @Guide(description: "Sentiment", .anyOf(["positive", "neutral", "negative"]))
    let sentiment: String
    let topics: [String]
    let summary: String
}
```

### 🛠️ Code Generation
```swift
// Generate code with validation
@Generable
struct SwiftFunction {
    @Guide(description: "Valid Swift function signature")
    let signature: String
    let implementation: String
    let tests: [String]
}
```

## Architecture

### Transcript-Centric Design

OpenFoundationModels follows Apple's Foundation Models design philosophy where `Transcript` is the single source of truth for all conversation context:

```swift
// Transcript manages the complete conversation
public struct Transcript {
    public enum Entry {
        case instructions(Instructions)  // System instructions & tool definitions
        case prompt(Prompt)              // User input with optional ResponseFormat
        case response(Response)          // Model output
        case toolCalls(ToolCalls)        // Tool invocations
        case toolOutput(ToolOutput)      // Tool results
    }
    
    // Prompt includes ResponseFormat for structured output
    public struct Prompt {
        var segments: [Segment]
        var options: GenerationOptions
        var responseFormat: ResponseFormat?  // Optional structured output format
    }
    
    // ResponseFormat defines expected output structure
    public struct ResponseFormat {
        public init(schema: GenerationSchema)      // From explicit schema
        public init<Content: Generable>(type: Content.Type)  // From Generable type
        public var name: String { get }
    }
}

// LanguageModelSession manages Transcript
let session = LanguageModelSession(model: model, tools: tools) {
    Instructions("You are a helpful assistant")
    // Automatically added as first Transcript.Entry
}

// Each interaction updates the Transcript
let response = try await session.respond {
    Prompt("Hello")  // Added to Transcript before sending to model
}
// Response is added to Transcript after generation

// Structured output with ResponseFormat
let response = try await session.respond(generating: ProductReview.self) {
    Prompt("Review the iPhone 15")
    // ResponseFormat(type: ProductReview.self) automatically added to Prompt
}

// LanguageModel receives complete context
protocol LanguageModel {
    // Receives full Transcript with all history, instructions, tools, and ResponseFormat
    func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry
    func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error>
}
```

This design ensures:
- **Stateless Models**: LanguageModel implementations don't manage state
- **Complete Context**: Every request includes full conversation history
- **Clear Responsibilities**: Session manages Transcript, Model generates responses

## Differences from Apple Foundation Models

### Image Segment Support (OpenFoundationModels Extension)

OpenFoundationModels extends Apple's `Transcript.Segment` with `.image(ImageSegment)` for Vision Language Model (VLM) support. **This is not part of Apple's Foundation Models API.**

| | Apple FoundationModels | OpenFoundationModels |
|---|---|---|
| `.text(TextSegment)` | Yes | Yes |
| `.structure(StructuredSegment)` | Yes | Yes |
| `.image(ImageSegment)` | No | **Yes (Extension)** |

`ImageSegment` supports two source types:
- `.base64(data:mediaType:)` — Inline base64-encoded image data with MIME type
- `.url(URL)` — Remote image URL reference

```swift
let prompt = Transcript.Prompt(segments: [
    .image(Transcript.ImageSegment(source: .base64(
        data: imageData.base64EncodedString(),
        mediaType: "image/png"
    ))),
    .text(Transcript.TextSegment(content: "Describe this image."))
])
let response = try await session.respond(to: prompt)
```

## Development

### Build

```bash
swift build
```

### Format

```bash
swift-format --in-place --recursive Sources/ Tests/
```

### Documentation

```bash
swift package generate-documentation
```

## Ecosystem

### Recommended: AnyFoundationModels

**[AnyFoundationModels](https://github.com/1amageek/AnyFoundationModels)** is the unified package that bundles the core framework and all provider backends with trait-gated compilation. This is the recommended way to use OpenFoundationModels in your projects.

| Backend | Trait | Description |
|---------|-------|-------------|
| `ClaudeFoundationModels` | `Claude` | Anthropic Claude API |
| `ResponseFoundationModels` | `Response` | OpenAI Responses API |
| `OllamaFoundationModels` | `Ollama` | Ollama local server |
| `MLXFoundationModels` | `MLX` | Apple MLX on-device inference |

### Deprecated Provider Packages

> **Warning**: The following standalone provider packages are **deprecated**. Please migrate to [AnyFoundationModels](https://github.com/1amageek/AnyFoundationModels).

- ~~[OpenFoundationModels-OpenAI](https://github.com/1amageek/OpenFoundationModels-OpenAI)~~ → Use `ResponseFoundationModels` from AnyFoundationModels
- ~~[OpenFoundationModels-Claude](https://github.com/1amageek/OpenFoundationModels-Claude)~~ → Use `ClaudeFoundationModels` from AnyFoundationModels
- ~~[OpenFoundationModels-MLX](https://github.com/1amageek/OpenFoundationModels-MLX)~~ → Use `MLXFoundationModels` from AnyFoundationModels
- ~~[OpenFoundationModels-Ollama](https://github.com/1amageek/OpenFoundationModels-Ollama)~~ → Use `OllamaFoundationModels` from AnyFoundationModels

### Sample Applications
- **[OpenFoundationModels-Samples](https://github.com/1amageek/OpenFoundationModels-Samples)**
  - Interactive CLI applications with full streaming support

## Why Choose OpenFoundationModels?

### For Developers
- **Zero Learning Curve**: If you know Apple's API, you already know ours
- **Platform Freedom**: Deploy anywhere - cloud, edge, mobile, embedded
- **Provider Flexibility**: Switch LLMs without changing code
- **Type Safety**: Catch errors at compile time, not runtime

### For Businesses  
- **Vendor Independence**: No lock-in to Apple or any LLM provider
- **Cost Control**: Use local models or choose the most cost-effective provider
- **Compliance Ready**: Keep data on-premise with local models
- **Future Proof**: Easy migration path when Apple's API goes public

## Testing

```bash
# Run all 328 tests
swift test

# Test specific components
swift test --filter GenerableTests      # @Generable macro
swift test --filter LanguageModelTests  # Core functionality
swift test --filter StreamingTests      # Async streaming
```

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```bash
# Quick start
git clone https://github.com/1amageek/OpenFoundationModels.git
cd OpenFoundationModels
swift test  # Verify setup
# Make your changes
git checkout -b feature/your-feature
# Submit PR
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple for the Foundation Models framework design and API
- The Swift community for excellent concurrency and macro tools
- Contributors and early adopters

## Related Projects

- **[AnyFoundationModels](https://github.com/1amageek/AnyFoundationModels)** - Unified package with all provider backends (Recommended)
- **[OpenFoundationModels-Samples](https://github.com/1amageek/OpenFoundationModels-Samples)** - Sample chat applications and demos

### Community Swift AI Projects

- [MLX Swift](https://github.com/ml-explore/mlx-swift) - Apple's MLX framework for Swift

---

**Note**: This is an independent open-source implementation and is not affiliated with Apple Inc. Apple, Foundation Models, and related trademarks are property of Apple Inc.