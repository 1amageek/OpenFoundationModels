import Foundation

public protocol LanguageModel: Sendable {
    func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry
    func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncStream<Transcript.Entry>
    var isAvailable: Bool { get }
    func supports(locale: Locale) -> Bool
}
