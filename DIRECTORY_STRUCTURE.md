# 🗂 OpenFoundationModels Directory Structure

## Overview
This document describes the organized directory structure of OpenFoundationModels, following Apple Foundation Models β SDK conventions.

## Structure

```
Sources/OpenFoundationModels/
├── Core/                           # Core API Components
│   ├── LanguageModelSession.swift  # Main session management
│   ├── SystemLanguageModel.swift   # On-device language model
│   ├── Response.swift              # Response<Content> generic type
│   └── ResponseStream.swift        # ResponseStream<Content> async sequence
│
├── Types/                          # Type Definitions
│   ├── Generable.swift             # Generable protocol
│   ├── GenerationOptions.swift     # Generation configuration
│   ├── Instructions.swift          # Session instructions
│   ├── Prompt.swift                # Prompt structure
│   ├── Transcript.swift            # Conversation transcript
│   ├── TranscriptEntry.swift       # Transcript entries
│   ├── PartialResponse.swift       # Partial response types
│   ├── AvailabilityStatus.swift    # Model availability status
│   └── UnavailabilityReason.swift  # Unavailability reasons
│
├── Tools/                          # Tool Calling System
│   ├── Tool.swift                  # Tool protocol
│   ├── ToolCall.swift              # Tool call structure
│   ├── ToolCalls.swift             # Tool calls collection
│   ├── ToolOutput.swift            # Tool output types
│   └── ToolOutputApple.swift       # Apple-specific tool output
│
├── Protocols/                      # Protocol Definitions
│   └── LanguageModel.swift         # Language model protocol
│
├── Foundation/                     # Foundation Components
│   ├── GenerationSchema.swift      # Schema generation
│   ├── GeneratedContent.swift      # Generated content handling
│   ├── Guardrails.swift            # Content safety guardrails
│   ├── PromptBuilder.swift         # Prompt builder @resultBuilder
│   ├── ProtocolConformances.swift  # Protocol conformances
│   ├── ConvertibleFromGeneratedContent.swift
│   └── ConvertibleToGeneratedContent.swift
│
├── Errors/                         # Error Handling
│   ├── GenerationError.swift       # Apple-spec generation errors
│   ├── LanguageModelError.swift    # Language model errors
│   └── ToolCallError.swift         # Tool call errors
│
├── Testing/                        # Testing Support
│   ├── MockLanguageModel.swift     # Mock implementation
│   └── MockLanguageModelTests.swift # Mock tests
│
├── Examples/                       # Usage Examples
│   └── ContentTaggingExample.swift # Content tagging example
│
└── OpenFoundationModels.swift      # Main module file
```

## Design Principles

### 1. **Apple Foundation Models β SDK Compliance**
- Directory structure mirrors Apple's official organization
- Core APIs are centralized in `Core/`
- Type definitions are organized in `Types/`

### 2. **Separation of Concerns**
- **Core**: Main API components that users interact with
- **Types**: Data structures and type definitions
- **Tools**: Tool calling system components
- **Protocols**: Interface definitions
- **Foundation**: Supporting functionality
- **Errors**: Error handling types
- **Testing**: Test utilities and mocks
- **Examples**: Usage demonstrations

### 3. **Discoverability**
- Related functionality is grouped together
- Clear naming conventions
- Logical hierarchy from general to specific

### 4. **Maintainability**
- Each directory has a specific purpose
- Files are organized by functionality
- Dependencies flow from specific to general

## Key Files

### Core API
- `LanguageModelSession.swift`: Main interface for model interaction
- `SystemLanguageModel.swift`: On-device model implementation
- `Response.swift`: Generic response type `Response<Content>`
- `ResponseStream.swift`: Streaming response type `ResponseStream<Content>`

### Type System
- `Generable.swift`: Protocol for generatable types
- `Prompt.swift`: Apple-compliant prompt structure
- `Transcript.swift`: Conversation history management

### Tool System
- `Tool.swift`: Tool protocol definition
- `ToolCall.swift`: Tool invocation structure
- `ToolOutput.swift`: Tool execution results

### Safety & Errors
- `Guardrails.swift`: Content safety system
- `GenerationError.swift`: Apple-compliant error types
- `ToolCallError.swift`: Tool-specific errors

## Future Expansion

This structure supports easy addition of new components:
- New types go in `Types/`
- New tools go in `Tools/`
- New errors go in `Errors/`
- New examples go in `Examples/`
- Core functionality extensions go in `Core/`

The organization ensures scalability while maintaining clarity and Apple β SDK compliance.