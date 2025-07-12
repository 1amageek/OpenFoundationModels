# Testing Strategy & Design

## Overview

OpenFoundationModels testing strategy focuses on ensuring complete compatibility with Apple's Foundation Models β SDK, with special emphasis on the revolutionary **Generable functionality** that enables type-safe structured generation through guided generation.

## Test Framework

### swift-testing
- **Framework**: swift-testing (Swift 6+ native testing framework)
- **Key Features**:
  - Modern macro-based API (`@Test`, `@Suite`)
  - Expressive assertions (`#expect()`, `#require()`)
  - Native async/await support
  - Parallel execution by default
  - Parameterized testing capabilities
  - Trait-based test customization

### Basic Syntax
```swift
@Test("Test display name")
func testFunction() {
    #expect(condition == expected)
}

@Suite("Test Suite Name", .tags(.core))
struct TestSuite {
    @Test("Parameterized test", arguments: [1, 2, 3])
    func parameterizedTest(value: Int) {
        #expect(value > 0)
    }
}
```

## Test Structure

### Directory Organization
```
Tests/
├── OpenFoundationModelsTests/
│   ├── Generable/                    # 🎯 PRIORITY 1: Core Generable functionality
│   │   ├── GenerableMacroTests.swift           # @Generable macro expansion testing
│   │   ├── GuideMacroTests.swift               # @Guide constraint macro testing
│   │   ├── GenerationSchemaTests.swift         # Schema generation accuracy
│   │   ├── GuidedGenerationTests.swift         # End-to-end structured generation
│   │   ├── PartiallyGeneratedTests.swift       # Streaming partial generation
│   │   ├── TypeConversionTests.swift           # GeneratedContent → Custom Type
│   │   ├── ConstraintValidationTests.swift     # Pattern/range/enum constraints
│   │   └── GenerableErrorHandlingTests.swift   # Generation error scenarios
│   ├── Core/                         # System core components
│   │   ├── SystemLanguageModelTests.swift      # Model availability, UseCase
│   │   ├── LanguageModelSessionTests.swift     # Session management, methods
│   │   ├── ResponseTests.swift                 # Response structure validation
│   │   └── ResponseStreamTests.swift           # Streaming functionality
│   ├── Foundation/                   # Base components
│   │   ├── InstructionsTests.swift             # Instructions & InstructionsBuilder
│   │   ├── PromptTests.swift                   # Prompt structure and segments
│   │   ├── TranscriptTests.swift               # Conversation transcript
│   │   ├── GeneratedContentTests.swift         # Generated content handling
│   │   └── ProtocolConformancesTests.swift     # Protocol implementations
│   ├── Tools/                        # Tool functionality
│   │   ├── ToolTests.swift                     # Tool protocol compliance
│   │   ├── ToolCallTests.swift                 # Tool invocation mechanics
│   │   └── ToolIntegrationTests.swift          # Tool execution workflows
│   ├── Errors/                       # Error handling
│   │   ├── GenerationErrorTests.swift          # All GenerationError cases
│   │   └── ErrorContextTests.swift             # Error context validation
│   ├── Integration/                  # End-to-end tests
│   │   ├── EndToEndFlowTests.swift            # Complete generation workflows
│   │   ├── AsyncConcurrencyTests.swift        # Concurrent operations
│   │   └── StreamingIntegrationTests.swift    # Streaming integration
│   ├── Performance/                  # Performance validation (as needed)
│   │   ├── LargeSchemaTests.swift             # Large schema generation
│   │   └── ConcurrentGenerationTests.swift    # Parallel generation load
│   └── Utilities/                    # Test utilities and helpers
│       ├── MockLanguageModel.swift            # Controlled response mock
│       ├── TestDataFixtures.swift             # Predefined test data
│       ├── CustomTags.swift                   # Test categorization tags
│       └── TestHelpers.swift                  # Common test utilities
└── OpenFoundationModelsMacrosTests/
    ├── GenerableMacroExpansionTests.swift      # Detailed macro expansion
    └── MacroErrorHandlingTests.swift           # Macro error scenarios
```

## Test Priorities & Implementation Phases

### 🎯 Phase 1: Generable Core (Week 1) - HIGHEST PRIORITY

**Focus**: Apple's guided generation feature - the core innovation that enables type-safe structured generation.

#### 1.1 Macro Foundation
- **GenerableMacroTests**: Validate `@Generable` macro expansion
  - Simple struct expansion
  - Complex nested types
  - Generic type support
  - Inheritance scenarios
  
- **GuideMacroTests**: Validate `@Guide` constraint macro
  - Pattern constraint generation (`.pattern(regex)`)
  - Range constraint generation (`.range(min...max)`)
  - Enumeration constraint generation (`.enumeration([values])`)
  - Multiple constraint combinations

#### 1.2 Schema Generation
- **GenerationSchemaTests**: Core schema creation
  - Basic property schemas
  - Nested object schemas
  - Array property schemas
  - Optional property handling
  - Custom type integration

#### 1.3 Constraint Validation
- **ConstraintValidationTests**: Runtime constraint enforcement
  - Pattern validation with regex
  - Range boundary testing
  - Enumeration value verification
  - Constraint violation error handling

#### 1.4 Type System Integration
- **TypeConversionTests**: Seamless type conversions
  - `GeneratedContent` → Custom Type conversion
  - `PartiallyGenerated` type handling
  - Error scenarios and recovery

### 🔧 Phase 2: System Core (Week 2)

#### 2.1 Language Model Foundation
- **SystemLanguageModelTests**: Core model functionality
  - Default instance availability
  - UseCase initialization (general, contentTagging)
  - Availability status handling
  - Supported languages validation

#### 2.2 Session Management  
- **LanguageModelSessionTests**: Session lifecycle
  - Initialization patterns (instructions, tools, transcript)
  - Respond method variants
  - Streaming method functionality
  - Prewarm operations

#### 2.3 Response Handling
- **ResponseTests**: Response structure integrity
- **ResponseStreamTests**: Streaming mechanics and AsyncSequence compliance

### 🔗 Phase 3: Integration Testing (Week 3)

#### 3.1 End-to-End Workflows
- **GuidedGenerationTests**: Complete structured generation flows
- **PartiallyGeneratedTests**: Streaming generation with progressive updates
- **StreamingIntegrationTests**: Full streaming pipeline validation

#### 3.2 Advanced Scenarios
- **AsyncConcurrencyTests**: Concurrent operation safety
- **ToolIntegrationTests**: Tool calling workflows
- **ErrorHandlingTests**: Comprehensive error scenario coverage

### ⚡ Phase 4: Comprehensive Coverage (Week 4)

#### 4.1 Performance & Scale
- **LargeSchemaTests**: Large-scale schema generation
- **ConcurrentGenerationTests**: Parallel generation under load
- **MemoryEfficiencyTests**: Resource usage validation

#### 4.2 Edge Cases & Reliability
- **BoundaryValueTests**: Edge case handling
- **InvalidDataTests**: Malformed input processing
- **ErrorRecoveryTests**: Graceful failure handling

## Testing Methodology

### Custom Tags
```swift
// CustomTags.swift
extension Tag {
    // Feature-specific tags
    @Tag static var generable: Self      // 🎯 Highest priority
    @Tag static var guide: Self
    @Tag static var schema: Self
    @Tag static var constraints: Self
    
    // Layer-specific tags
    @Tag static var core: Self
    @Tag static var foundation: Self
    @Tag static var tools: Self
    @Tag static var errors: Self
    
    // Test type tags
    @Tag static var macros: Self
    @Tag static var integration: Self
    @Tag static var streaming: Self
    @Tag static var performance: Self
}
```

### Assertion Strategy
```swift
// Non-fatal validation - test continues on failure
#expect(value == expected)
#expect(value != nil, "Value should not be nil")

// Fatal validation - test stops on failure
#require(let unwrapped = optionalValue)

// Async event validation
await confirmation("Event occurred", expectedCount: 1) { confirmed in
    eventHandler = { confirmed() }
    triggerEvent()
}

// Error validation
#expect(throws: GenerationError.self) {
    try problematicOperation()
}
```

### Mock Strategy
```swift
// MockLanguageModel.swift - Controlled response generation
actor MockLanguageModel: LanguageModel {
    private var responses: [String] = []
    private var shouldThrowError = false
    
    func setResponse(_ response: String) {
        responses.append(response)
    }
    
    func setError(_ shouldThrow: Bool) {
        shouldThrowError = shouldThrow
    }
    
    func generate(prompt: String, options: GenerationOptions?) async throws -> String {
        if shouldThrowError {
            throw GenerationError.rateLimited(
                GenerationError.Context(debugDescription: "Mock rate limit")
            )
        }
        return responses.isEmpty ? "Mock response" : responses.removeFirst()
    }
}
```

## Key Test Scenarios

### Generable Core Testing
```swift
@Test("Complex guided generation with constraints")
func complexGuidedGeneration() async throws {
    @Generable
    struct UserProfile {
        @Guide(description: "Username", .pattern("[a-zA-Z0-9_]+"))
        let username: String
        
        @Guide(description: "Age", .range(13...120))
        let age: Int
        
        @Guide(description: "Role", .enumeration(["admin", "user", "guest"]))
        let role: String
    }
    
    let session = LanguageModelSession()
    let response = try await session.respond(
        to: "Generate a user profile",
        generating: UserProfile.self
    )
    
    // Validate type safety
    #expect(response.content is UserProfile)
    
    // Validate constraint enforcement
    let profile = response.content
    #expect(profile.age >= 13 && profile.age <= 120)
    #expect(["admin", "user", "guest"].contains(profile.role))
    #expect(!profile.username.isEmpty)
    
    // Validate username pattern
    let usernameRegex = try Regex("[a-zA-Z0-9_]+")
    #expect(profile.username.wholeMatch(of: usernameRegex) != nil)
}
```

### Streaming Generation Testing
```swift
@Test("Streaming generation with partial updates", .timeLimit(.seconds(30)))
func streamingPartialUpdates() async throws {
    @Generable
    struct Article {
        let title: String
        let content: String
        let tags: [String]
    }
    
    let session = LanguageModelSession()
    let stream = session.streamResponse(
        to: "Write an article about AI",
        generating: Article.self
    )
    
    var partialCount = 0
    
    await confirmation("Receives partial updates", expectedCount: 1...) { confirmed in
        for try await partial in stream {
            partialCount += 1
            confirmed()
            
            #expect(partial.content != nil)
            
            if partial.isComplete {
                #expect(partialCount > 0)
                break
            }
        }
    }
}
```

### Error Handling Testing
```swift
@Test("Constraint violation produces appropriate error")
func constraintViolationError() async throws {
    @Generable
    struct StrictType {
        @Guide(description: "Only digits", .pattern("\\d+"))
        let numericString: String
    }
    
    let session = LanguageModelSession()
    
    #expect(throws: GenerationError.self) {
        // Force constraint violation by requesting non-numeric content
        try await session.respond(
            to: "Generate alphabetic text",
            generating: StrictType.self
        )
    }
}
```

### Macro Expansion Testing
```swift
@Test("@Generable macro generates correct code")
func generableMacroExpansion() throws {
    assertMacroExpansion(
        """
        @Generable
        struct Person {
            let name: String
            let age: Int
        }
        """,
        expandedSource: """
        struct Person {
            let name: String
            let age: Int
            
            init(_ generatedContent: GeneratedContent) throws {
                // Validate expanded initialization code
            }
            
            static var generationSchema: GenerationSchema {
                // Validate expanded schema generation
            }
        }
        """,
        macros: testMacros
    )
}
```

## Quality Targets

### Coverage Goals
- **Unit Test Coverage**: 95%+ for Generable functionality
- **Integration Coverage**: 100% of major user workflows
- **Error Coverage**: All defined error cases and recovery paths
- **Performance Coverage**: All time-critical operations under load

### Reliability Standards
- **Zero Flaky Tests**: All tests must be deterministic
- **Performance Bounds**: All tests complete under 30 seconds (.timeLimit)
- **Resource Efficiency**: No memory leaks or resource exhaustion
- **Concurrent Safety**: All async operations are thread-safe

### Code Quality
- **Documentation**: Every test suite and complex test documented
- **Maintainability**: Clear test structure and helper utilities
- **Readability**: Self-documenting test names and assertions
- **Extensibility**: Easy to add new test scenarios

## Implementation Guidelines

### 1. Generable-First Development
- **Priority**: Start with @Generable and @Guide functionality
- **Quality**: Core innovation must be rock-solid and fully tested
- **Coverage**: Every constraint type, every macro expansion scenario

### 2. Test-Driven Development
- **Approach**: Write tests before implementing fixes
- **Validation**: Tests serve as specification and documentation
- **Regression**: Prevent breaking changes to core functionality

### 3. Incremental Quality
- **Phase-based**: Each phase builds on previous stability
- **Continuous**: Run tests frequently during development
- **Integration**: Validate component interactions early

### 4. Performance Awareness
- **Timeouts**: Use `.timeLimit()` traits appropriately
- **Resource**: Monitor memory and CPU usage in tests
- **Scale**: Test with realistic data sizes

### 5. Documentation Synchronization
- **Living Docs**: Tests serve as executable documentation
- **Examples**: Test code provides usage examples
- **Accuracy**: Keep test documentation current with implementation

## Running Tests

### Basic Commands
```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run specific test suite
swift test --filter "GenerableMacroTests"
```

### Filtered Test Execution
```bash
# Priority 1: Core Generable functionality
swift test --filter tag:generable

# System layers
swift test --filter tag:core
swift test --filter tag:foundation
swift test --filter tag:tools

# Test types
swift test --filter tag:macros
swift test --filter tag:integration
swift test --filter tag:performance

# Streaming functionality
swift test --filter tag:streaming

# Error handling
swift test --filter tag:errors
```

### Continuous Integration
```bash
# Quick validation (unit tests only)
swift test --filter tag:unit

# Full validation (all tests)
swift test

# Performance validation
swift test --filter tag:performance
```

## Test Data Management

### Fixtures and Helpers
- **TestDataFixtures**: Predefined complex data structures
- **MockLanguageModel**: Controlled response generation
- **TestHelpers**: Common setup and assertion utilities
- **AppleExamples**: Real-world usage patterns from documentation

### Test Isolation
- **Independent**: Each test runs in isolation
- **Stateless**: No shared state between test cases
- **Deterministic**: Consistent results across runs
- **Parallel-Safe**: Tests can run concurrently without conflicts

## Maintenance and Evolution

### Regular Updates
- **Apple Compatibility**: Update tests when Apple releases new versions
- **Performance Benchmarks**: Establish and maintain performance baselines
- **Coverage Monitoring**: Track and improve test coverage over time
- **Documentation Sync**: Keep testing docs current with implementation

### Quality Assurance
- **Code Review**: All test code reviewed for quality and completeness
- **Performance Monitoring**: Track test execution time and resource usage
- **Reliability Tracking**: Monitor and eliminate flaky tests
- **Coverage Analysis**: Regular coverage reports and gap analysis

---

This testing strategy ensures the highest quality implementation of Apple's Foundation Models compatibility, with special focus on the revolutionary Generable functionality that enables type-safe structured generation. The comprehensive test suite serves as both quality assurance and living documentation of the framework's capabilities.