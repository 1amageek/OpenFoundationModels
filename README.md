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

## Key Features

✅ **100% Apple API Compatible** - Same code as Apple Foundation Models, just change the import  
✅ **Multi-Platform** - Works everywhere: Linux, Windows, Android, Docker, CI/CD  
✅ **Provider Freedom** - OpenAI, Anthropic, Ollama, or any LLM provider  
✅ **Structured Generation** - Type-safe data with `@Generable` macro  
✅ **Real-time Streaming** - Responsive UI with partial updates  
✅ **Tool Calling** - Let LLMs execute your functions  
✅ **Production Ready** - 154 tests passing, memory efficient, thread-safe

## Installation

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    // Core framework
    .package(url: "https://github.com/1amageek/OpenFoundationModels.git", from: "1.0.0"),
    
    // Optional: OpenAI provider
    .package(url: "https://github.com/1amageek/OpenFoundationModels-OpenAI.git", from: "1.0.0")
]
```

### Try Sample Apps (No Setup Required)

```bash
# Clone and run sample applications
git clone https://github.com/1amageek/OpenFoundationModels-Samples.git
cd OpenFoundationModels-Samples

# Option 1: On-device chat (no API key needed)
swift run foundation-chat

# Option 2: OpenAI-powered chat
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

for try await partial in stream {
    print(partial.content, terminator: "")
    
    if partial.isComplete {
        print("\n--- Generation Complete ---")
        break
    }
}
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
    
    if partial.isComplete {
        print("Article generation complete!")
    }
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
    tools: [WeatherTool()]
)

let response = try await session.respond {
    Prompt("What's the weather in Tokyo and Paris?")
}
// LLM calls WeatherTool twice and combines results
// Output: "Tokyo is 22°C and sunny, while Paris is 15°C with clouds."
```

### 6. Generation Control

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
let session = LanguageModelSession {
    "You are a Swift expert."
    "Use modern Swift 6.1+ features."
    "Include error handling in all examples."
}

let response = try await session.respond(options: options) {
    Prompt("Write a networking function")
}
```

### 7. Use Any LLM Provider

```swift
import OpenFoundationModels
import OpenFoundationModelsOpenAI  // Or Anthropic, Ollama, etc.

// Same API, different providers
let session = LanguageModelSession(
    model: OpenAIProvider(apiKey: key).gpt4o        // OpenAI
    // model: AnthropicProvider(apiKey: key).claude3  // Anthropic
    // model: OllamaProvider().llama3                 // Local
    // model: SystemLanguageModel.default             // Apple
)

// Write once, run with any provider
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
// Build chatbots that work on any platform
let chatbot = LanguageModelSession(model: provider.model)
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
# Run all 154 tests
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

### Official OpenFoundationModels Extensions

- **[OpenFoundationModels-OpenAI](https://github.com/1amageek/OpenFoundationModels-OpenAI)** - Complete OpenAI provider integration
- **[OpenFoundationModels-Samples](https://github.com/1amageek/OpenFoundationModels-Samples)** - Sample chat applications and demos

### Community Swift AI Projects

- [Swift OpenAI](https://github.com/MacPaw/OpenAI) - OpenAI API client
- [LangChain Swift](https://github.com/bukowskidev/langchain-swift) - LangChain for Swift
- [Ollama Swift](https://github.com/kevinhermawan/OllamaKit) - Ollama client for Swift

---

**Note**: This is an independent open-source implementation and is not affiliated with Apple Inc. Apple, Foundation Models, and related trademarks are property of Apple Inc.