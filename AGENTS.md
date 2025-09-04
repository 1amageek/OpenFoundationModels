# Repository Guidelines

## Project Structure & Modules
- Sources: Swift packages under `Sources/`
  - `OpenFoundationModelsCore`: core types, protocols, utilities
  - `OpenFoundationModels`: public API, sessions, transcript, tools
  - `OpenFoundationModelsMacros` and `...MacrosImpl`: user macros and implementation (SwiftSyntax)
- Tests: `Tests/OpenFoundationModelsTests/` grouped by domain (e.g., `Core/`, `Foundation/`, `Generable/`, `Tools/`, `Integration/`, `Performance/`). Test files end with `Tests.swift`.
- Package files: `Package.swift`, `Package.resolved`. Build artifacts in `.build/`.

## Build, Test, and Dev Commands
- Build: `swift build` — compile all targets.
- Test (all): `swift test` — run the full suite (Swift Testing).
- Test (filter): `swift test --filter Generable` or `swift test --filter Generable/EnumGenerableTests`.
- Format: `swift-format --in-place --recursive Sources/ Tests/`.
- Docs: `swift package generate-documentation`.

## Coding Style & Naming
- Language: Swift 6.2+ (`swift-tools-version: 6.2`).
- Indentation: 4 spaces; line length keep readable (~120). Use `swift-format` before pushing.
- Types/Protocols/Enums: UpperCamelCase (e.g., `LanguageModelSession`).
- Methods/vars/cases: lowerCamelCase; test types end with `Tests`.
- Files: Prefer one primary type per file named to match the type.

## Testing Guidelines
- Framework: Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`).
- Structure: Mirror source areas; place new tests under the closest domain folder.
- Naming: Use descriptive `@Test("…")` names; tag with `.tags(...)` when helpful.
- Coverage: Add tests with each feature/bugfix; prefer focused unit tests plus targeted integration cases.

## Commit & Pull Requests
- Commits: Imperative, present tense; keep concise and scoped (e.g., "Add tool schema instructions", "Refactor Transcript Codable").
- Branches: `feature/<summary>` or `fix/<issue-id>-<summary>`.
- PRs must include:
  - Clear description and rationale; link related issues
  - Tests for new behavior and breaking-change notes (if any)
  - Screenshots/log snippets when relevant (failing test output is great)
  - Ran: `swift build`, `swift test`, `swift-format`

## Security & Configuration
- Do not commit secrets. Provider-specific keys and configuration must use environment variables or local config ignored by Git.
- Minimum platforms: macOS 15, iOS 18, macCatalyst 18, visionOS 2 (see `Package.swift`). Ensure changes respect these.

