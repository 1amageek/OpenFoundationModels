import Foundation

public protocol LanguageModel: Sendable {
    func generate(transcript: Transcript, options: GenerationOptions?) async throws -> String
    func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncStream<String>
    var isAvailable: Bool { get }
    func supports(locale: Locale) -> Bool
}
