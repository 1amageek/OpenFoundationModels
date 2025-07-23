# OpenFoundationModels

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://developer.apple.com)
[![Tests](https://img.shields.io/badge/Tests-154%20passing-brightgreen.svg)](#testing)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/1amageek/OpenFoundationModels)

**100% Apple Foundation Models β SDK Compatible Implementation**

OpenFoundationModels is a complete **open-source implementation** of Apple's Foundation Models framework (iOS 26/macOS 15 Xcode 17b3), providing 100% API compatibility while enabling use outside Apple's ecosystem.

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
import FoundationModels

// OpenFoundationModels (works everywhere)
import OpenFoundationModels

// 🎯 100% API Compatible - No code changes required
let session = LanguageModelSession(
    model: SystemLanguageModel.default,
    guardrails: .default,
    tools: [],
    instructions: nil
)
```

**✅ Apple Official API Compliant**: Code migration with just `import` change  
**✅ Multi-Platform**: Works on Linux, Windows, Android, etc.  
**✅ Provider Choice**: OpenAI, Anthropic, local models, and more  
**✅ Enterprise Ready**: Integrates with existing infrastructure

## Quick Start

Get started with OpenFoundationModels in minutes:

### Try Sample Applications

```bash
# Clone and run sample chat applications
git clone https://github.com/1amageek/OpenFoundationModels-Samples.git
cd OpenFoundationModels-Samples

# Option 1: On-device chat (no setup required)
swift run foundation-chat

# Option 2: OpenAI-powered chat
export OPENAI_API_KEY="your_api_key_here"
swift run openai-chat
```

### Basic Usage

```swift
import OpenFoundationModels

// Apple's official API - works everywhere
let session = LanguageModelSession()
let response = try await session.respond {
    Prompt("Hello, OpenFoundationModels!")
}
print(response.content)
```

### With OpenAI

```swift
import OpenFoundationModels
import OpenFoundationModelsOpenAI

let provider = OpenAIProvider(apiKey: "your_key")
let session = LanguageModelSession(model: provider.gpt4o)
let response = try await session.respond {
    Prompt("Explain Swift concurrency")
}
```

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                    │
├─────────────────────────────────────────────────────────┤
│  LanguageModelSession  │  SystemLanguageModel  │ Tools  │
├─────────────────────────────────────────────────────────┤
│     Response<T>        │   ResponseStream<T>    │ @Macro │
├─────────────────────────────────────────────────────────┤
│   Generable Protocol   │ GenerationSchema │ Transcript  │
├─────────────────────────────────────────────────────────┤
│                   Provider Abstraction                  │
├─────────────────────────────────────────────────────────┤
│    OpenAI    │  Anthropic  │  Local Models  │   Mock    │
└─────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. **SystemLanguageModel** - Model Access Hub
Apple's official model access point

```swift
public final class SystemLanguageModel: LanguageModel, Observable, Sendable {
    /// Apple Official: Single default model instance
    public static let `default`: SystemLanguageModel
    
    /// Apple Official: Model availability status
    public var availability: AvailabilityStatus { get }
    
    /// Apple Official: Convenience availability property
    public var isAvailable: Bool { get }
}
```

#### 2. **LanguageModelSession** - Session Management
Main class managing conversation state and context

```swift
public final class LanguageModelSession: Observable, @unchecked Sendable {
    /// Apple Official initialization pattern
    public convenience init(
        model: SystemLanguageModel = SystemLanguageModel.default,
        guardrails: Guardrails = .default,
        tools: [any Tool] = [],
        instructions: Instructions? = nil
    )
    
    /// Apple Official response generation (closure-based)
    public func respond(
        options: GenerationOptions = .default,
        isolation: isolated (any Actor)? = nil,
        prompt: () throws -> Prompt
    ) async throws -> Response<String>
    
    /// Apple Official structured generation
    public func respond<Content: Generable>(
        generating: Content.Type,
        options: GenerationOptions = .default,
        includeSchemaInPrompt: Bool = true,
        isolation: isolated (any Actor)? = nil,
        prompt: () throws -> Prompt
    ) async throws -> Response<Content>
}
```

#### 3. **Generable Protocol** - Structured Generation
Core protocol for type-safe structured data generation

```swift
public protocol Generable: ConvertibleFromGeneratedContent, 
                          ConvertibleToGeneratedContent, 
                          PartiallyGenerable, 
                          Sendable, 
                          SendableMetatype {
    /// Apple Official: Compile-time schema generation
    static var generationSchema: GenerationSchema { get }
    
    /// Apple Official: Conversion from GeneratedContent
    static func from(generatedContent: GeneratedContent) throws -> Self
}
```

#### 4. **Tool Protocol** - Function Calling
Protocol for LLM function execution

```swift
public protocol Tool: Sendable, SendableMetatype {
    associatedtype Arguments: Generable
    
    /// Apple Official: Tool name
    static var name: String { get }
    
    /// Apple Official: Tool description
    static var description: String { get }
    
    /// Apple Official: Execution method
    func call(arguments: Arguments) async throws -> ToolOutput
}
```

#### 5. **Response System** - Response Processing
Type-safe response processing and streaming

```swift
/// Apple Official: Generic response
public struct Response<Content: Sendable>: Sendable {
    public let content: Content
    public let transcriptEntries: ArraySlice<Transcript.Entry>
}

/// Apple Official: Streaming response
public struct ResponseStream<Content: Sendable>: AsyncSequence, Sendable {
    public typealias Element = Response<Content>.Partial
}
```

## Installation

### Swift Package Manager

#### Core Framework
```swift
dependencies: [
    .package(url: "https://github.com/1amageek/OpenFoundationModels.git", from: "1.0.0")
]
```

#### With OpenAI Provider
```swift
dependencies: [
    .package(url: "https://github.com/1amageek/OpenFoundationModels.git", from: "1.0.0"),
    .package(url: "https://github.com/1amageek/OpenFoundationModels-OpenAI.git", from: "1.0.0")
]
```

### Sample Applications

Try the complete sample applications immediately:

```bash
# Clone samples repository
git clone https://github.com/1amageek/OpenFoundationModels-Samples.git
cd OpenFoundationModels-Samples

# Run on-device chat (no API key required)
swift run foundation-chat

# Run OpenAI chat (requires API key)
export OPENAI_API_KEY="your_api_key_here"
swift run openai-chat
```

## Usage

### 1. Basic Text Generation

```swift
import OpenFoundationModels

// Check model availability
let model = SystemLanguageModel.default
guard model.isAvailable else {
    print("Model not available")
    return
}

// Create session (Apple Official API)
let session = LanguageModelSession(
    model: model,
    guardrails: .default,
    tools: [],
    instructions: nil
)

// Apple Official closure-based prompt
let response = try await session.respond {
    Prompt("Tell me about Swift 6.1 new features")
}

print(response.content)
```

### 2. Structured Generation (@Generable Macro)

```swift
// Apple Official @Generable macro (fully implemented)
@Generable
struct ProductReview {
    @Guide(description: "Product name", .pattern("^[A-Za-z0-9\\s]+$"))
    let productName: String
    
    @Guide(description: "Rating score", .range(1...5))
    let rating: Int
    
    @Guide(description: "Review comment", .count(50...500))
    let comment: String
    
    @Guide(description: "Recommendation", .enumeration(["Highly Recommend", "Recommend", "Neutral", "Not Recommend"]))
    let recommendation: String
}

// Generate structured data
let response = try await session.respond(
    generating: ProductReview.self,
    includeSchemaInPrompt: true
) {
    Prompt("Generate a review for iPhone 15 Pro")
}

// Type-safe access
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

for try await partial in stream {
    print(partial.content, terminator: "")
    
    if partial.isComplete {
        print("\n--- Generation Complete ---")
        break
    }
}
```

### 4. Structured Data Streaming

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
    
    if partial.isComplete {
        print("Article generation complete!")
    }
}
```

### 5. Tool Calling

```swift
// Apple Official Tool protocol implementation
struct WeatherTool: Tool {
    typealias Arguments = WeatherQuery
    
    static let name = "get_weather"
    static let description = "Get current weather for a city"
    
    func call(arguments: WeatherQuery) async throws -> ToolOutput {
        // Weather API call (implementation example)
        let weather = try await fetchWeather(city: arguments.city)
        return ToolOutput("🌤️ Weather in \(arguments.city): \(weather)")
    }
}

@Generable
struct WeatherQuery {
    @Guide(description: "City name", .pattern("^[\\p{L}\\s]+$"))
    let city: String
}

// Session with tools
let session = LanguageModelSession(
    model: SystemLanguageModel.default,
    guardrails: .default,
    tools: [WeatherTool()],
    instructions: nil
)

let response = try await session.respond {
    Prompt("What's the weather like in Tokyo today?")
}

// LLM automatically calls WeatherTool and incorporates results
print(response.content)
```

### 6. Advanced Features

#### Instructions and Guardrails

```swift
// Apple Official @InstructionsBuilder pattern
let session = LanguageModelSession {
    "You are a helpful and knowledgeable Swift programming instructor."
    "Explain concepts clearly with practical examples for beginners."
    "Include appropriate comments in code samples."
}

// Guardrails configuration
let guardrails = Guardrails(
    allowedTopics: ["programming", "swift", "technology"],
    restrictedContent: ["personal_info", "financial_advice"],
    maxResponseLength: 1000
)

let session = LanguageModelSession(
    model: SystemLanguageModel.default,
    guardrails: guardrails,
    tools: [],
    instructions: Instructions("Swift technical advisor specialist")
)
```

### 7. OpenAI Provider Integration

```swift
import OpenFoundationModels
import OpenFoundationModelsOpenAI

// Initialize OpenAI provider
let openAIProvider = OpenAIProvider(apiKey: "your_api_key_here")

// Create session with OpenAI model (same Apple API!)
let session = LanguageModelSession(
    model: openAIProvider.gpt4o,  // GPT-4o model
    guardrails: .default,
    tools: [],
    instructions: nil
)

// Same Apple API, powered by OpenAI
let response = try await session.respond {
    Prompt("Explain quantum computing in simple terms")
}

print(response.content)

// Structured generation with OpenAI
@Generable
struct TechnicalExplanation {
    @Guide(description: "Main concept", .count(20...100))
    let concept: String
    
    @Guide(description: "Simple explanation", .count(100...300))
    let explanation: String
    
    @Guide(description: "Real-world applications", .count(50...200))
    let applications: [String]
}

let structuredResponse = try await session.respond(
    generating: TechnicalExplanation.self
) {
    Prompt("Explain quantum computing")
}

print("Concept: \(structuredResponse.content.concept)")
print("Explanation: \(structuredResponse.content.explanation)")
```

## Testing and Quality Assurance

### 154 Tests Passing

```bash
# Run all tests
swift test

# Category-specific tests
swift test --filter tag:generable  # Structured generation tests
swift test --filter tag:core       # Core API tests
swift test --filter tag:integration # Integration tests
swift test --filter tag:performance # Performance tests
```

### Apple Compatibility Verification

- ✅ **SystemLanguageModel**: 100% Apple official specification compliance
- ✅ **LanguageModelSession**: All initialization patterns supported
- ✅ **Tool Protocol**: SendableMetatype conformance verified
- ✅ **Generable Protocol**: Fully implemented
- ✅ **Response/ResponseStream**: Generic type support
- ✅ **@Generable Macro**: Complete functionality verified
- ✅ **Transcript**: All nested types implemented

For detailed verification information, see [TESTING.md](./TESTING.md).

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

OpenFoundationModels provides a complete ecosystem with core framework, provider integrations, and sample applications:

### 🏗️ Core Framework
- **[OpenFoundationModels](https://github.com/1amageek/OpenFoundationModels)** - Apple Foundation Models compatible core framework
- 100% API compatibility with Apple's official specification
- 154 tests passing with comprehensive coverage

### 🔗 Provider Integrations
- **[OpenFoundationModels-OpenAI](https://github.com/1amageek/OpenFoundationModels-OpenAI)** ✅ **Complete**
  - Full GPT model support (GPT-4o, GPT-4o Mini, GPT-4 Turbo, o1, o1-pro, o3, o3-pro, o4-mini)
  - Streaming and multimodal capabilities
  - Production-ready with rate limiting and error handling

### 📱 Sample Applications
- **[OpenFoundationModels-Samples](https://github.com/1amageek/OpenFoundationModels-Samples)** ✅ **Complete**
  - `foundation-chat`: On-device chat using Apple's SystemLanguageModel
  - `openai-chat`: Cloud-based chat using OpenAI models
  - Interactive CLI applications with full streaming support

### 🔮 Planned Integrations
Provider adapters can be added for:
- **Anthropic** (Claude 3 Haiku, Sonnet, Opus, etc.)
- **Google** (Gemini Pro, Ultra, etc.)
- **Local Models** (Ollama, llama.cpp, etc.)
- **Azure OpenAI Service**
- **AWS Bedrock**

## Performance

- **Warning-Free Compilation**: Zero compiler warnings
- **Memory Efficient**: Proper memory management with transcript compaction
- **Concurrent**: Full Swift 6.1+ concurrency support
- **154 Tests Passing**: Comprehensive test coverage
- **Type Safe**: Generic response system with compile-time checking

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Clone the repository
2. Run `swift test` to verify everything works
3. Implement your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple for the Foundation Models framework design and API
- The Swift community for excellent concurrency and macro tools
- Contributors and early adopters

## Related Projects

### Official OpenFoundationModels Extensions

- **[OpenFoundationModels-OpenAI](https://github.com/1amageek/OpenFoundationModels-OpenAI)** - Complete OpenAI provider integration
- **[OpenFoundationModels-Samples](https://github.com/1amageek/OpenFoundationModels-Samples)** - Sample chat applications and demos

### Community Swift AI Projects

- [Swift OpenAI](https://github.com/MacPaw/OpenAI) - OpenAI API client
- [LangChain Swift](https://github.com/bukowskidev/langchain-swift) - LangChain for Swift
- [Ollama Swift](https://github.com/kevinhermawan/OllamaKit) - Ollama client for Swift

---

**Note**: This is an independent open-source implementation and is not affiliated with Apple Inc. Apple, Foundation Models, and related trademarks are property of Apple Inc.