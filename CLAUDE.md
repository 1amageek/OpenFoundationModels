# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
**100% Apple Foundation Models β SDK Compatible Implementation**

OSS implementation of Apple's Foundation Models framework (iOS 26/macOS 15 Xcode 17b3), providing on-device LLM capabilities with structured generation, tool calling, and streaming support.

## Implementation Policy

### Deprecated API Handling
- **Deprecated APIは実装しない**: Apple Foundation ModelsのDeprecatedとマークされたAPIは追加しません
- **不要になったものは削除**: 古くなったAPIは削除して対応します
- **ベータ版への対応**: Foundation Modelsはベータ版のため、厳密な互換性追従は不要です

### Development Principles
1. **実用性を重視**: 100%の互換性よりも、実際に動作する実装を優先
2. **クリーンなAPI**: Deprecatedなものを含めず、モダンで使いやすいAPIを提供
3. **前向きな進化**: ベータ版の変更に柔軟に対応し、常に最新のベストプラクティスに従う

## Build Commands
- Build: `swift build`
- Test: `swift test`
- Test specific: `swift test --filter TestName`
- Release build: `swift build -c release`
- Lint/Format: `swift-format --in-place --recursive Sources/ Tests/`

## Apple Foundation Models 完全仕様

### Generable プロトコルとJSON Schema の関係

Apple の Generable は TypeScript の JSON Schema に相当する機能で、LLM の出力を構造化するための仕組みです。

#### JSON Schema との対応表

| JSON Schema | Apple Generable | 説明 |
|------------|----------------|------|
| `type: "object"` | `@Generable struct` | オブジェクト型 |
| `type: "string"` | `String` | 文字列型 |
| `type: "integer"` | `Int` | 整数型 |
| `type: "number"` | `Double/Float` | 数値型 |
| `type: "boolean"` | `Bool` | 真偽値型 |
| `type: "array"` | `[T]` | 配列型 |
| `enum: [...]` | `enum` または `.anyOf()` | 列挙型 |
| `pattern: "regex"` | `.pattern(/regex/)` | 正規表現制約 |
| `minimum/maximum` | `.range(min...max)` | 範囲制約 |
| `minItems/maxItems` | `.minimumCount()/.maximumCount()` | 配列要素数制約 |
| `required: [...]` | 非Optional プロパティ | 必須フィールド |
| `properties: {...}` | `GenerationSchema.Property` | プロパティ定義 |

### PartiallyGenerated の設計思想

PartiallyGenerated は Apple Foundation Models の素晴らしい機能で、ストリーミングレスポンス中の部分的なデータを UI で利用可能にするための仕組みです。

#### 動作原理

```swift
// ストリーミング中の状態遷移例
@Generable
struct UserProfile {
    let name: String
    let age: Int
    let bio: String
}

// 1. 初期状態: {}
// isComplete: false
let partial1 = UserProfile.PartiallyGenerated(GeneratedContent(json: "{}"))

// 2. name が到着: {"name": "John"}
// isComplete: false
let partial2 = UserProfile.PartiallyGenerated(GeneratedContent(json: #"{"name": "John"}"#))

// 3. 完全なJSON: {"name": "John", "age": 25, "bio": "Developer"}
// isComplete: true
let complete = UserProfile(GeneratedContent(json: #"{"name": "John", "age": 25, "bio": "Developer"}"#))
```

### GeneratedContent の詳細設計

#### Kind enum

GeneratedContent は JSON 互換のデータ構造を表現します：

```swift
public enum Kind: Sendable, Equatable {
    case null                                                           // JSON null
    case bool(Bool)                                                     // JSON boolean
    case number(Double)                                                 // JSON number
    case string(String)                                                 // JSON string
    case array([GeneratedContent])                                      // JSON array
    case structure(properties: [String: GeneratedContent], orderedKeys: [String])  // JSON object
    case partial(json: String)                                          // 不完全なJSON（ストリーミング中）
}
```

#### isComplete の判定ロジック

```swift
public var isComplete: Bool {
    switch kind {
    case .structure(_, _):
        // JSON として完全にパース可能か
        return isValidCompleteJSON()
    case .array(let elements):
        // すべての要素が complete か
        return elements.allSatisfy { $0.isComplete }
    case .partial:
        // 部分的なJSONは常に incomplete
        return false
    case .string, .number, .bool, .null:
        // プリミティブ型は常に complete
        return true
    }
}
```

### @Generable マクロの生成コード仕様

#### 構造体の場合

```swift
@Generable(description: "User profile data")
struct UserProfile {
    @Guide(description: "User's full name", .pattern(/^[A-Za-z ]+$/))
    let name: String
    
    @Guide(description: "Age in years", .range(0...150))
    let age: Int
}

// マクロが生成するコード:
extension UserProfile: Generable {
    // ConvertibleFromGeneratedContent 要件
    public init(_ content: GeneratedContent) throws {
        let props = try content.properties()
        
        // 各プロパティの取得（部分的なパースも許容）
        self.name = try props["name"]?.value(String.self) ?? ""
        self.age = try props["age"]?.value(Int.self) ?? 0
    }
    
    // ConvertibleToGeneratedContent 要件
    public var generatedContent: GeneratedContent {
        GeneratedContent(
            kind: .structure(
                properties: [
                    "name": GeneratedContent(kind: .string(self.name)),
                    "age": GeneratedContent(kind: .number(Double(self.age)))
                ],
                orderedKeys: ["name", "age"]  // スキーマ順序を保持
            )
        )
    }
    
    // Generable 要件
    public static var generationSchema: GenerationSchema {
        GenerationSchema(
            type: UserProfile.self,
            description: "User profile data",
            properties: [
                GenerationSchema.Property(
                    name: "name",
                    description: "User's full name",
                    type: String.self,
                    guides: [/^[A-Za-z ]+$/]
                ),
                GenerationSchema.Property(
                    name: "age",
                    description: "Age in years",
                    type: Int.self,
                    guides: [GenerationGuide.range(0...150)]
                )
            ]
        )
    }
    
    // PartiallyGenerated 型（必要な場合のみ生成）
    public struct PartiallyGenerated: ConvertibleFromGeneratedContent {
        public let name: String?
        public let age: Int?
        private let content: GeneratedContent
        
        public init(_ content: GeneratedContent) throws {
            self.content = content
            
            // 部分的なパースを許容
            if let props = try? content.properties() {
                self.name = try? props["name"]?.value(String.self)
                self.age = try? props["age"]?.value(Int.self)
            } else {
                self.name = nil
                self.age = nil
            }
        }
        
        public var isComplete: Bool {
            content.isComplete
        }
    }
    
    // デフォルト実装
    public func asPartiallyGenerated() -> PartiallyGenerated {
        try! PartiallyGenerated(self.generatedContent)
    }
}
```

#### 列挙型の場合

```swift
@Generable
enum Status {
    case active
    case inactive
    case pending(reason: String)
}

// マクロが生成するコード:
extension Status: Generable {
    public init(_ content: GeneratedContent) throws {
        // 単純な列挙型として試行
        if let stringValue = try? content.value(String.self) {
            switch stringValue {
            case "active": self = .active
            case "inactive": self = .inactive
            default: break
            }
        }
        
        // Discriminated Union として試行
        let props = try content.properties()
        guard let caseContent = props["case"],
              let caseName = try? caseContent.value(String.self) else {
            throw GenerationError.invalidValue
        }
        
        switch caseName {
        case "active": self = .active
        case "inactive": self = .inactive
        case "pending":
            let valueContent = props["value"] ?? GeneratedContent("")
            let reason = try valueContent.value(String.self)
            self = .pending(reason: reason)
        default:
            throw GenerationError.invalidValue
        }
    }
    
    public var generatedContent: GeneratedContent {
        switch self {
        case .active:
            return GeneratedContent(kind: .string("active"))
        case .inactive:
            return GeneratedContent(kind: .string("inactive"))
        case .pending(let reason):
            return GeneratedContent(
                kind: .structure(
                    properties: [
                        "case": GeneratedContent(kind: .string("pending")),
                        "value": GeneratedContent(kind: .string(reason))
                    ],
                    orderedKeys: ["case", "value"]
                )
            )
        }
    }
    
    public static var generationSchema: GenerationSchema {
        // 関連値がない場合は単純な anyOf
        // 関連値がある場合は discriminated union
        GenerationSchema(
            type: Status.self,
            description: "Status enumeration",
            properties: [
                GenerationSchema.Property(
                    name: "case",
                    description: "Enum case identifier",
                    type: String.self
                ),
                GenerationSchema.Property(
                    name: "value",
                    description: "Associated value",
                    type: String.self
                )
            ]
        )
    }
}
```

### @Guide マクロの詳細

@Guide マクロは peer macro として、プロパティに JSON Schema 相当の制約を付与：

```swift
// 文字列パターン
@Guide(description: "Email address", .pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/))
var email: String

// 数値範囲
@Guide(description: "Score percentage", .range(0...100))
var score: Int

// 配列要素数
@Guide(description: "Tag list", .minimumCount(1), .maximumCount(10))
var tags: [String]

// 列挙値
@Guide(description: "Status", .anyOf(["draft", "published", "archived"]))
var status: String
```

### GenerationSchema.Property の設計

```swift
public struct Property {
    // 内部ストレージ
    internal let name: String
    internal let description: String?
    internal let type: any Sendable.Type
    internal let guides: [Any]  // GenerationGuide または Regex
    
    // Generable 型用
    public init<Value: Generable>(
        name: String,
        description: String? = nil,
        type: Value.Type,
        guides: [GenerationGuide<Value>] = []
    )
    
    // String 型用（正規表現付き）
    public init<RegexOutput>(
        name: String,
        description: String? = nil,
        type: String.Type,
        guides: [Regex<RegexOutput>] = []
    )
    
    // Optional 型用
    public init<Value: Generable>(
        name: String,
        description: String? = nil,
        type: Value?.Type,
        guides: [GenerationGuide<Value>] = []
    )
}
```

### 型変換とデフォルト値

#### 型マッピング

| Swift 型 | GeneratedContent.Kind | デフォルト値 |
|---------|---------------------|------------|
| String | .string(_) | "" |
| Int | .number(_) | 0 |
| Double | .number(_) | 0.0 |
| Float | .number(_) | 0.0 |
| Bool | .bool(_) | false |
| [T] | .array(_) | [] |
| T? | .null または 該当Kind | nil |

### ストリーミング対応

```swift
// ResponseStream での使用例
let stream = session.streamResponse(
    to: "Generate user profile",
    generating: UserProfile.self
)

for try await partial in stream {
    // partial.content は UserProfile.PartiallyGenerated 型
    if let name = partial.content.name {
        updateNameLabel(name)  // 部分的なデータでUIを更新
    }
    
    if partial.isComplete {
        let complete = try UserProfile(partial.content.generatedContent)
        saveToDatabase(complete)
    }
}
```

### エラーハンドリング

```swift
public enum GenerationError: Error {
    case invalidValue                           // 無効な値
    case missingRequiredProperty(String)        // 必須プロパティの欠如
    case typeMismatch(expected: String, actual: String)  // 型の不一致
    case invalidJSON(String)                     // 無効なJSON
    case schemaViolation(String)                 // スキーマ違反
    case partialContent                          // 部分的なコンテンツ（完全でない）
}
```

## Transcript-Centric Design Philosophy

Apple Foundation ModelsはTranscriptを中心とした設計を採用しています：

### Transcriptの役割
- **Single Source of Truth**: すべての会話コンテキストを一元管理
- **Instructions**: システム指示とToolDefinitionsを含む  
- **Conversation History**: Prompt/Response/ToolCalls/ToolOutputの履歴
- **Stateless Model Interface**: LanguageModelはTranscriptを受け取って処理

### 責任の分離
- **LanguageModelSession**: 
  - Transcriptの管理（エントリの追加・保持）
  - Instructions/ToolsをTranscript.Entryとして初期化時に設定
  - 各respond呼び出しでPrompt/Responseエントリを追加
- **LanguageModel**: 
  - Transcriptを受け取って解釈（実装依存）
  - 応答生成のみに集中
  - コンテキスト管理はしない

### Transcript.Entry の種類
```swift
public enum Entry {
    case instructions(Transcript.Instructions)  // システム指示とツール定義
    case prompt(Transcript.Prompt)              // ユーザー入力
    case response(Transcript.Response)          // モデル応答
    case toolCalls(Transcript.ToolCalls)        // ツール呼び出し
    case toolOutput(Transcript.ToolOutput)      // ツール結果
}
```

## Architecture

### Core Components
1. **SystemLanguageModel**
   - Static `default` property
   - `availability: AvailabilityStatus` property
   - `isAvailable: Bool` convenience property

2. **Generation System**
   - `GenerationOptions`: Configuration with SamplingMode (greedy, random top-k, random top-p)
   - `GenerationSchema`: Type descriptions with Property and SchemaError
   - `GenerationGuide`: Constraints for guided generation (ranges, patterns, enums)
   - `DynamicGenerationSchema`: Runtime schema construction
   - `GeneratedContent`: Structured content representation

3. **LanguageModelSession** (Apple Official API)
   - Transcript-based conversation management
   - Initializers: `init(model:tools:instructions:)`, `init(model:tools:transcript:)`  
   - Closure-based prompts: `prompt: () throws -> Prompt`
   - Generic responses: `Response<Content>` where `Content: Generable`
   - Streaming: `ResponseStream<Content>` with AsyncSequence
   - Response methods:
     - `respond(to:options:) async throws -> Response<String>`
     - `respond<Content>(to:generating:includeSchemaInPrompt:options:) async throws -> Response<Content>`
     - `respond(to:schema:includeSchemaInPrompt:options:) async throws -> Response<GeneratedContent>`
     - `streamResponse(to:options:) -> ResponseStream<String>`
     - `streamResponse<Content>(to:generating:includeSchemaInPrompt:options:) -> ResponseStream<Content>`
   - Transcript management: automatic entry creation and tracking
   - `prewarm(promptPrefix:)`: Preload model resources

4. **Protocols**
   - `Generable`: Types that can be generated by the model
   - `Tool`: Function-calling protocol with ToolDefinition in Transcript.Instructions
   - `LanguageModel`: Transcript-based generation interface
     - `generate(transcript:options:) async throws -> String`
     - `stream(transcript:options:) -> AsyncStream<String>`
     - `isAvailable: Bool`
     - `supports(locale:) -> Bool`

5. **Error Handling**
   - `LanguageModelSession.GenerationError`: Apple-compliant error enum
   - `LanguageModelSession.ToolCallError`: Tool execution errors
   - `GenerationOptions`: Generation configuration
   - `GenerationSchema`: Structured generation schemas

### Directory Structure
```
Sources/
├── OpenFoundationModels/           # Main module
│   ├── Core/                      # Main API components
│   │   ├── LanguageModelSession.swift
│   │   ├── SystemLanguageModel.swift
│   │   ├── Response.swift
│   │   └── ResponseStream.swift
│   ├── Types/                     # Type definitions
│   ├── Tools/                     # Tool calling system
│   ├── Extensions/                # Protocol extensions
│   └── Errors/                    # Error handling
├── OpenFoundationModelsCore/      # Core types and protocols
│   ├── Protocols/                 # Core protocol definitions
│   ├── Types/                     # Core type definitions
│   │   ├── GenerationSchema.swift
│   │   ├── GeneratedContent.swift
│   │   ├── DynamicGenerationSchema.swift
│   │   ├── Instructions.swift
│   │   └── Prompt.swift
│   └── Builders/                  # Result builders
└── OpenFoundationModelsMacros/    # Macro implementations
```

### Implementation Guidelines
- **Apple β SDK Compliance**: All APIs match Apple's official specification
- **Swift 6.1+ Features**: isolated/sending keywords, modern concurrency
- **Generic Type System**: Response<Content> and ResponseStream<Content>
- **Closure-based Prompts**: `prompt: () throws -> Prompt` pattern
- **Thread Safety**: Sendable conformance throughout
- **Error Handling**: Apple-compliant error types
- **Streaming Support**: AsyncSequence-based streaming

### Testing Strategy
Comprehensive testing strategy focused on Generable functionality and Apple Foundation Models compatibility.

**📋 Complete Testing Documentation**: See [TESTING.md](./TESTING.md) for detailed testing strategy, structure, and implementation guidelines.

#### Quick Test Commands
```bash
# All tests
swift test

# Priority 1: Core Generable functionality
swift test --filter tag:generable

# System components  
swift test --filter tag:core
swift test --filter tag:foundation

# Test types
swift test --filter tag:macros
swift test --filter tag:integration
swift test --filter tag:performance
```

#### Test Priorities
1. **🎯 Generable Core** (Highest Priority): @Generable macros, guided generation, constraints
2. **🔧 System Core**: SystemLanguageModel, LanguageModelSession, Response handling
3. **🔗 Integration**: End-to-end workflows, streaming, tool calling
4. **⚡ Performance**: Large schemas, concurrent generation, memory efficiency

#### Test Implementation Methodology
**🔄 Incremental Test-Driven Development**

**📖 DOCUMENTATION-FIRST APPROACH:**
**⚠️ CRITICAL**: Before implementing ANY test, you MUST read the relevant Apple documentation using the Remark tool or official Apple documentation URLs provided below.

**One Test at a Time Approach:**
1. **📚 Read Documentation FIRST**: Always start by reading Apple's official documentation for the component being tested
2. **Write Single Test**: Implement one specific test case based on the documentation
3. **Run & Verify**: Execute `swift test` and ensure PASS
4. **Fix If Needed**: If test fails, fix implementation before proceeding
5. **Next Test**: Only after success, write the next test case
6. **Continuous Validation**: Each new test must not break existing tests

**Implementation Order:**
```bash
# Step 1: Foundation - READ DOCS FIRST!
# 📚 Before implementing: Read https://developer.apple.com/documentation/foundationmodels
swift test --filter "CustomTagsTests"           # Tags definition test
swift test                                      # Verify base setup

# Step 2: Generable Core (One by one) - READ DOCS FIRST!
# 📚 Before implementing: Read https://developer.apple.com/documentation/foundationmodels/generable
swift test --filter "GenerableMacroTests"       # First: @Generable macro
swift test --filter "GuideMacroTests"          # Second: @Guide macro  
swift test --filter "GenerationSchemaTests"     # Third: Schema generation

# Step 3: Core System (One by one) - READ DOCS FIRST!
# 📚 Before implementing: Read https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel
swift test --filter "SystemLanguageModelTests" # Fourth: Model tests
# 📚 Before implementing: Read https://developer.apple.com/documentation/foundationmodels/languagemodelsession
swift test --filter "LanguageModelSessionTests" # Fifth: Session tests
```

**Quality Gates:**
- ✅ **Documentation Check**: Read Apple documentation BEFORE writing any test
- ✅ Each test file must pass individually before next implementation
- ✅ All existing tests must continue passing when new tests added
- ✅ No skipped or ignored tests allowed in main branch
- ✅ Fix broken implementation immediately, don't accumulate test debt

**Development Workflow:**
1. **📚 READ APPLE DOCUMENTATION FIRST** for the component you're testing
2. Implement smallest possible test case for specific functionality based on documentation
3. Run `swift test --filter SpecificTest` to verify single test
4. Run `swift test` to verify no regressions in existing tests
5. Commit successful test + implementation before next test
6. Repeat cycle for next test case

This methodical approach ensures rock-solid test coverage and prevents accumulation of broken tests.

## Key APIs (Apple Official)

1. **LanguageModelSession Initializers**
```swift
// Apple official convenience initializers
convenience init(
    model: SystemLanguageModel = SystemLanguageModel.default,
    tools: [any Tool] = [],
    @InstructionsBuilder instructions: () throws -> Instructions
) rethrows

convenience init(
    model: SystemLanguageModel = SystemLanguageModel.default,
    tools: [any Tool] = [],
    transcript: Transcript
)
```

2. **Response Methods**
```swift
// String response
func respond(
    options: GenerationOptions = .default,
    isolation: isolated (any Actor)? = nil,
    prompt: () throws -> Prompt
) async throws -> Response<String>

// Generic content response
func respond<Content: Generable>(
    generating: Content.Type,
    options: GenerationOptions = .default,
    includeSchemaInPrompt: Bool = true,
    isolation: isolated (any Actor)? = nil,
    prompt: () throws -> Prompt
) async throws -> Response<Content>
```

3. **Streaming Methods**
```swift
// String streaming
func streamResponse(
    options: GenerationOptions = .default,
    prompt: () throws -> Prompt
) rethrows -> ResponseStream<String>

// Generic content streaming
func streamResponse<Content: Generable>(
    generating: Content.Type,
    options: GenerationOptions = .default,
    includeSchemaInPrompt: Bool = true,
    prompt: () throws -> Prompt
) rethrows -> ResponseStream<Content>
```

4. **Response Types**
```swift
public struct Response<Content: Sendable>: Sendable {
    public let userPrompt: String
    public let content: Content
    public let duration: TimeInterval
    
    public struct Partial: Sendable {
        public let content: Content
        public let isComplete: Bool
    }
}

public struct ResponseStream<Content: Sendable>: AsyncSequence, Sendable {
    public typealias Element = Response<Content>.Partial
}
```

5. **Error Handling**
```swift
public enum GenerationError: Error, Sendable {
    case exceededContextWindowSize
    case guardrailViolation
    case toolError(ToolCallError)
    case modelUnavailable
    case invalidPrompt
    case invalidSchema
    case generationFailed
}
```

## Dependencies
- swift-syntax (for macro implementation)
- swift-async-algorithms (for streaming)
- Foundation (for core types)

## Remark Tool Usage
For fetching Apple documentation during development, use the Remark tool:

### Installation
```bash
# Clone and install Remark tool
git clone https://github.com/1amageek/Remark.git
cd Remark
make install
```

### Command-Line Usage
```bash
# Basic Apple documentation fetch
remark https://developer.apple.com/documentation/foundationmodels/languagemodelsession

# Include front matter for structured output
remark --include-front-matter https://developer.apple.com/documentation/foundationmodels/response

# Plain text output
remark --plain-text https://developer.apple.com/documentation/foundationmodels/responsestream
```

### Key Apple Documentation URLs
- LanguageModelSession: `https://developer.apple.com/documentation/foundationmodels/languagemodelsession`
- Response: `https://developer.apple.com/documentation/foundationmodels/response`
- ResponseStream: `https://developer.apple.com/documentation/foundationmodels/responsestream`
- SystemLanguageModel: `https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel`
- GenerationOptions: `https://developer.apple.com/documentation/foundationmodels/generationoptions`
- GenerationGuide: `https://developer.apple.com/documentation/foundationmodels/generationguide`
- DynamicGenerationSchema: `https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema`
- Generable: `https://developer.apple.com/documentation/foundationmodels/generable`
- GenerationSchema: `https://developer.apple.com/documentation/foundationmodels/generationschema`
- GeneratedContent: `https://developer.apple.com/documentation/foundationmodels/generatedcontent`

### Swift Package Manager Integration
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/1amageek/Remark.git", branch: "main")
]
```

### Library Usage
```swift
import Remark

let htmlContent = """<html>...</html>"""
do {
    let remark = try Remark(htmlContent)
    print("Title:", remark.title)
    print("Description:", remark.description)
    print("Markdown:", remark.page)
} catch {
    print("Error:", error)
}
```

### Features
- HTML to Markdown conversion
- Open Graph metadata extraction
- Front matter generation
- Intelligent URL and link handling
- Command-line interface
- Swift library integration

## SendableMetatype Protocol

### 概要
SendableMetatypeは、Swift 標準ライブラリのプロトコルで、型のメタタイプが並行コンテキスト間で安全に共有できることを示します。ジェネリック型`T`が`SendableMetatype`に準拠すると、そのメタタイプ`T.Type`が`Sendable`に準拠します。

### 重要な特徴
- **目的**: メタタイプ（T.Type）をTask間で安全に共有
- **自動準拠**: すべての具象型は暗黙的にSendableMetatypeに準拠
- **主な用途**: ジェネリックコードでisolated conformancesの使用を防ぐ

### プロトコル定義
```swift
protocol SendableMetatype : ~Copyable, ~Escapable
```

### 使用例
```swift
// 問題のあるコード（SendableMetatypeなし）
func useFromAnotherTask<T: P>(_: T.Type) {
    Task { @concurrent in
        T.f() // エラー: non-Sendable type `T.Type` をキャプチャ
    }
}

// 修正版（SendableMetatype追加）
func useFromAnotherTask<T: P & SendableMetatype>(_: T.Type) {
    Task { @concurrent in
        T.f() // OK: T.Type は Sendable
    }
}
```

### プロトコル継承関係
- `Sendable`プロトコルは`SendableMetatype`を継承
- `T: Sendable`の要件がある場合、`T: SendableMetatype`も暗黙的に要求される

### Foundation Models での使用
Apple Foundation Modelsでは、以下の型がSendableMetatypeに準拠：
- GenerationSchema
- GenerationOptions
- Tool（プロトコル）
- LanguageModelFeedback およびネスト型（Sentiment, Issue, Issue.Category）
- Transcript およびすべてのネスト型

## API Implementation Status

### ✅ Verified Against Apple Documentation
- **SystemLanguageModel**: Complete with UseCase struct
- **SystemLanguageModel.UseCase**: Verified with `general` and `contentTagging` static properties
- **Tool Protocol**: 100% accurate with SendableMetatype conformance
- **ToolOutput**: Verified struct with `init(_:)` method
- **Generable Protocol**: Complete with all required conformances
- **GenerationID**: Implemented with full Apple compliance
- **Transcript**: Complete with all nested types
- **Response/ResponseStream**: Generic types with Apple specifications
- **SendableMetatype準拠**: すべての必要な型で正しく実装
  - GenerationSchema, GenerationOptions
  - LanguageModelFeedback.Sentiment/Issue/Category
  - Transcript.Entry（Apple仕様通り）
  - Tool プロトコル
- **GenerationOptions**: Complete with SamplingMode (greedy, random top-k, random top-p)
- **GenerationSchema**: Full implementation with Property, SchemaError, and dynamic support
- **GenerationGuide**: All static methods for constraints (ranges, patterns, enums, arrays)
- **DynamicGenerationSchema**: Runtime schema construction with Property type
- **GeneratedContent**: All data access methods and protocol conformances

### 🔧 Build Status
- ✅ **Build Success**: All modules compile without errors
- ✅ **Core API**: 100% Apple compliant structure
- ✅ **Generate System**: Fully implemented and verified
- ⚠️ **Minor Warnings**: Some unused parameters in DynamicGenerationSchema conversion (non-critical)

## Status
✅ **Implementation Complete**: 100% Apple Foundation Models β SDK compatibility achieved
✅ **API Verification**: All major APIs verified against Apple documentation
✅ **Clean Architecture**: Organized directory structure
✅ **Thread Safety**: Full Sendable compliance
✅ **Modern Swift**: Swift 6.1+ concurrency features