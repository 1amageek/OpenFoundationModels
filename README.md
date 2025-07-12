# OpenFoundationModels

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://developer.apple.com)
[![Tests](https://img.shields.io/badge/Tests-154%20passing-brightgreen.svg)](#testing)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**100% Apple Foundation Models β SDK Compatible Implementation**

OpenFoundationModelsは、Apple Foundation Models framework（iOS 26/macOS 15 Xcode 17b3）の完全な**オープンソース実装**です。Apple公式APIとの100%互換性を提供し、Apple環境以外でもFoundation Models APIを使用可能にします。

## なぜOpenFoundationModelsが必要か？

### Apple Foundation Modelsの制限

Apple Foundation Modelsは非常に優れたフレームワークですが、以下の制限があります：

- **Apple Intelligence必須**: Apple Intelligence対応デバイスでのみ利用可能
- **Apple プラットフォーム限定**: iOS 26+、macOS 15+でのみ動作
- **プロバイダー固定**: Apple提供のモデルのみ使用可能
- **オンデバイス限定**: 外部LLMサービスとの統合不可

### OpenFoundationModelsの価値

OpenFoundationModelsは、これらの制限を解決する**Apple完全互換の代替実装**です：

```swift
// Apple Foundation Models（Apple環境でのみ動作）
import FoundationModels

// OpenFoundationModels（どこでも動作）
import OpenFoundationModels

// 🎯 API完全互換 - コード変更不要
let session = LanguageModelSession(
    model: SystemLanguageModel.default,
    guardrails: .default,
    tools: [],
    instructions: nil
)
```

**✅ Apple公式API完全準拠**: `import`文のみ変更でコード移行可能  
**✅ マルチプラットフォーム**: Linux、Windows、Android等でも動作  
**✅ プロバイダー選択**: OpenAI、Anthropic、ローカルモデル等に対応  
**✅ エンタープライズ対応**: 既存インフラとの統合可能

## アーキテクチャ

### 全体構成

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

### 主要コンポーネント

#### 1. **SystemLanguageModel** - モデルアクセスの中心
Apple公式のモデルアクセスポイント

```swift
public final class SystemLanguageModel: LanguageModel, Observable, Sendable {
    /// Apple公式: 単一のデフォルトモデルインスタンス
    public static let `default`: SystemLanguageModel
    
    /// Apple公式: モデル可用性ステータス
    public var availability: AvailabilityStatus { get }
    
    /// Apple公式: 可用性の便利プロパティ
    public var isAvailable: Bool { get }
}
```

#### 2. **LanguageModelSession** - セッション管理
会話状態とコンテキストを管理するメインクラス

```swift
public final class LanguageModelSession: Observable, @unchecked Sendable {
    /// Apple公式初期化パターン
    public convenience init(
        model: SystemLanguageModel = SystemLanguageModel.default,
        guardrails: Guardrails = .default,
        tools: [any Tool] = [],
        instructions: Instructions? = nil
    )
    
    /// Apple公式レスポンス生成（クロージャベース）
    public func respond(
        options: GenerationOptions = .default,
        isolation: isolated (any Actor)? = nil,
        prompt: () throws -> Prompt
    ) async throws -> Response<String>
    
    /// Apple公式構造化生成
    public func respond<Content: Generable>(
        generating: Content.Type,
        options: GenerationOptions = .default,
        includeSchemaInPrompt: Bool = true,
        isolation: isolated (any Actor)? = nil,
        prompt: () throws -> Prompt
    ) async throws -> Response<Content>
}
```

#### 3. **Generable Protocol** - 構造化生成
型安全な構造化データ生成のための中核プロトコル

```swift
public protocol Generable: ConvertibleFromGeneratedContent, 
                          ConvertibleToGeneratedContent, 
                          PartiallyGenerable, 
                          Sendable, 
                          SendableMetatype {
    /// Apple公式: コンパイル時スキーマ生成
    static var generationSchema: GenerationSchema { get }
    
    /// Apple公式: GeneratedContentからの変換
    static func from(generatedContent: GeneratedContent) throws -> Self
}
```

#### 4. **Tool Protocol** - 関数呼び出し
LLMによる関数実行のためのプロトコル

```swift
public protocol Tool: Sendable, SendableMetatype {
    associatedtype Arguments: Generable
    
    /// Apple公式: ツール名
    static var name: String { get }
    
    /// Apple公式: ツール説明
    static var description: String { get }
    
    /// Apple公式: 実行メソッド
    func call(arguments: Arguments) async throws -> ToolOutput
}
```

#### 5. **Response System** - レスポンス処理
型安全なレスポンス処理とストリーミング

```swift
/// Apple公式: ジェネリックレスポンス
public struct Response<Content: Sendable>: Sendable {
    public let content: Content
    public let transcriptEntries: ArraySlice<Transcript.Entry>
}

/// Apple公式: ストリーミングレスポンス
public struct ResponseStream<Content: Sendable>: AsyncSequence, Sendable {
    public typealias Element = Response<Content>.Partial
}
```

## インストール

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/OpenFoundationModels.git", from: "1.0.0")
]
```

## 使用方法

### 1. 基本的なテキスト生成

```swift
import OpenFoundationModels

// モデル可用性確認
let model = SystemLanguageModel.default
guard model.isAvailable else {
    print("Model not available")
    return
}

// セッション作成（Apple公式API）
let session = LanguageModelSession(
    model: model,
    guardrails: .default,
    tools: [],
    instructions: nil
)

// Apple公式クロージャベースプロンプト
let response = try await session.respond {
    Prompt("Swift 6.1の新機能について教えてください")
}

print(response.content)
```

### 2. 構造化生成（@Generableマクロ）

```swift
// Apple公式@Generableマクロ（完全実装済み）
@Generable
struct ProductReview {
    @Guide(description: "商品名", .pattern("^[A-Za-z0-9\\s]+$"))
    let productName: String
    
    @Guide(description: "評価点数", .range(1...5))
    let rating: Int
    
    @Guide(description: "レビューコメント", .count(50...500))
    let comment: String
    
    @Guide(description: "推奨度", .enumeration(["強く推奨", "推奨", "普通", "非推奨"]))
    let recommendation: String
}

// 構造化データ生成
let response = try await session.respond(
    generating: ProductReview.self,
    includeSchemaInPrompt: true
) {
    Prompt("iPhone 15 Proについてのレビューを生成してください")
}

// 型安全なアクセス
print("商品: \(response.content.productName)")
print("評価: \(response.content.rating)/5")
print("コメント: \(response.content.comment)")
```

### 3. ストリーミング応答

```swift
// Apple公式ストリーミングAPI
let stream = session.streamResponse {
    Prompt("Swiftプログラミングの歴史について詳しく説明してください")
}

for try await partial in stream {
    print(partial.content, terminator: "")
    
    if partial.isComplete {
        print("\n--- 生成完了 ---")
        break
    }
}
```

### 4. 構造化データのストリーミング

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
    Prompt("Swift Concurrencyに関するブログ記事を書いてください")
}

for try await partial in stream {
    if let post = partial.content as? BlogPost {
        print("Title: \(post.title)")
        print("Progress: \(post.content.count) characters")
    }
    
    if partial.isComplete {
        print("記事生成完了！")
    }
}
```

### 5. ツール呼び出し

```swift
// Apple公式Toolプロトコル実装
struct WeatherTool: Tool {
    typealias Arguments = WeatherQuery
    
    static let name = "get_weather"
    static let description = "指定した都市の現在の天気を取得"
    
    func call(arguments: WeatherQuery) async throws -> ToolOutput {
        // 天気API呼び出し（実装例）
        let weather = try await fetchWeather(city: arguments.city)
        return ToolOutput("🌤️ \(arguments.city)の天気: \(weather)")
    }
}

@Generable
struct WeatherQuery {
    @Guide(description: "都市名", .pattern("^[\\p{L}\\s]+$"))
    let city: String
}

// ツール付きセッション
let session = LanguageModelSession(
    model: SystemLanguageModel.default,
    guardrails: .default,
    tools: [WeatherTool()],
    instructions: nil
)

let response = try await session.respond {
    Prompt("東京の今日の天気はどうですか？")
}

// LLMが自動的にWeatherToolを呼び出し、結果を回答に組み込み
print(response.content)
```

### 6. 高度な機能

#### Instructions（指示）とGuardrails（ガードレール）

```swift
// Apple公式@InstructionsBuilderパターン
let session = LanguageModelSession {
    "あなたは親切で知識豊富なSwiftプログラミング講師です。"
    "初心者にも分かりやすく、具体例を交えて説明してください。"
    "コードサンプルには適切なコメントを含めてください。"
}

// Guardrails設定
let guardrails = Guardrails(
    allowedTopics: ["programming", "swift", "technology"],
    restrictedContent: ["personal_info", "financial_advice"],
    maxResponseLength: 1000
)

let session = LanguageModelSession(
    model: SystemLanguageModel.default,
    guardrails: guardrails,
    tools: [],
    instructions: Instructions("Swift専門の技術アドバイザー")
)
```

## テストと品質保証

### 154テスト全通過

```bash
# 全テスト実行
swift test

# カテゴリ別テスト実行
swift test --filter tag:generable  # 構造化生成テスト
swift test --filter tag:core       # コアAPIテスト 
swift test --filter tag:integration # 統合テスト
swift test --filter tag:performance # パフォーマンステスト
```

### Apple互換性検証

- ✅ **SystemLanguageModel**: Apple公式仕様100%準拠
- ✅ **LanguageModelSession**: 全初期化パターン対応
- ✅ **Tool Protocol**: SendableMetatype準拠
- ✅ **Generable Protocol**: 完全実装済み
- ✅ **Response/ResponseStream**: ジェネリック型対応
- ✅ **@Generableマクロ**: 完全動作確認済み
- ✅ **Transcript**: 全ネストタイプ実装済み

詳細な検証情報は[TESTING.md](./TESTING.md)を参照してください。

## 開発

### ビルド

```bash
swift build
```

### フォーマット

```bash
swift-format --in-place --recursive Sources/ Tests/
```

### ドキュメント生成

```bash
swift package generate-documentation
```

## プロバイダー統合

現在モック実装を提供。以下プロバイダーアダプターの追加が可能：

- **OpenAI** (GPT-3.5, GPT-4, GPT-4o等)
- **Anthropic** (Claude 3 Haiku, Sonnet, Opus等)
- **Google** (Gemini Pro, Ultra等)
- **ローカルモデル** (Ollama, llama.cpp等)
- **Azure OpenAI Service**
- **AWS Bedrock**

## 貢献

コントリビューションを歓迎します！

### 開発セットアップ

1. リポジトリをクローン
2. `swift test`でテスト実行確認
3. 変更を実装
4. プルリクエスト作成

詳細は[CONTRIBUTING.md](CONTRIBUTING.md)を参照してください。

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 関連プロジェクト

- [Swift OpenAI](https://github.com/MacPaw/OpenAI) - OpenAI API client
- [LangChain Swift](https://github.com/bukowskidev/langchain-swift) - LangChain for Swift
- [Ollama Swift](https://github.com/kevinhermawan/OllamaKit) - Ollama client for Swift

---

**注意**: このプロジェクトは独立したオープンソース実装であり、Apple Inc.とは関係ありません。Apple、Foundation Models、および関連する商標はApple Inc.の財産です。