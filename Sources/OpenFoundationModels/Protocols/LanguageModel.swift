import Foundation

public protocol LanguageModel: Sendable {
    func generate(transcript: Transcript, options: GenerationOptions?) async throws -> Transcript.Entry
    func stream(transcript: Transcript, options: GenerationOptions?) -> AsyncThrowingStream<Transcript.Entry, Error>
    var isAvailable: Bool { get }
    func supports(locale: Locale) -> Bool
}
