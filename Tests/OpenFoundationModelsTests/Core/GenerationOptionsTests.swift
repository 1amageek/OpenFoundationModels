import Testing
import Foundation
@testable import OpenFoundationModels

/// Locks in the backwards-compatible extension semantics of `GenerationOptions`.
///
/// New backend-extensible fields (topP, topK, minP, repetitionPenalty, presencePenalty,
/// frequencyPenalty, repetitionContextSize) are all Optional with default `nil` so that
/// pre-existing call sites continue to compile and behave identically. These tests pin
/// down: (1) construction defaults, (2) Apple-mirrored field independence, (3) Equatable
/// across the full field set, (4) Codable round-trip including the new fields, and
/// (5) decoding of legacy payloads that lack the new keys.
@Suite("GenerationOptions Backend-Extensible Fields", .tags(.core, .unit))
struct GenerationOptionsTests {

    // MARK: - Defaults

    @Test("Default-constructed GenerationOptions leaves every field nil")
    func defaultConstructionAllNil() {
        let opts = GenerationOptions()
        #expect(opts.sampling == nil)
        #expect(opts.temperature == nil)
        #expect(opts.maximumResponseTokens == nil)
        #expect(opts.topP == nil)
        #expect(opts.topK == nil)
        #expect(opts.minP == nil)
        #expect(opts.repetitionPenalty == nil)
        #expect(opts.presencePenalty == nil)
        #expect(opts.frequencyPenalty == nil)
        #expect(opts.repetitionContextSize == nil)
    }

    @Test("GenerationOptions.default equals a freshly constructed instance")
    func staticDefaultMatchesEmptyInit() {
        #expect(GenerationOptions.default == GenerationOptions())
    }

    // MARK: - Apple-mirrored field compatibility

    @Test("Existing Apple-mirrored initializer call site keeps working unchanged")
    func appleCompatibleInitializer() {
        let opts = GenerationOptions(
            sampling: .greedy,
            temperature: 0.7,
            maximumResponseTokens: 256
        )
        #expect(opts.sampling == .greedy)
        #expect(opts.temperature == 0.7)
        #expect(opts.maximumResponseTokens == 256)
        // New fields untouched
        #expect(opts.topP == nil)
        #expect(opts.repetitionPenalty == nil)
    }

    // MARK: - Backend-extensible fields

    @Test("Extended initializer with Extensions populates every backend-extensible field")
    func extendedInitPopulatesExtensions() {
        let opts = GenerationOptions(
            temperature: 0.7,
            extensions: GenerationOptions.Extensions(
                topP: 0.9,
                topK: 40,
                minP: 0.05,
                repetitionPenalty: 1.1,
                presencePenalty: 0.5,
                frequencyPenalty: 0.2,
                repetitionContextSize: 64
            )
        )
        #expect(opts.temperature == 0.7)
        #expect(opts.topP == 0.9)
        #expect(opts.topK == 40)
        #expect(opts.minP == 0.05)
        #expect(opts.repetitionPenalty == 1.1)
        #expect(opts.presencePenalty == 0.5)
        #expect(opts.frequencyPenalty == 0.2)
        #expect(opts.repetitionContextSize == 64)
    }

    @Test("Apple-compatible initializer leaves every extension field nil")
    func appleInitLeavesExtensionsNil() {
        let opts = GenerationOptions(temperature: 0.7, maximumResponseTokens: 256)
        #expect(opts.topP == nil)
        #expect(opts.topK == nil)
        #expect(opts.minP == nil)
        #expect(opts.repetitionPenalty == nil)
        #expect(opts.presencePenalty == nil)
        #expect(opts.frequencyPenalty == nil)
        #expect(opts.repetitionContextSize == nil)
    }

    @Test("Direct property mutation still works after Apple-compatible construction")
    func directMutationOfExtensionFields() {
        var opts = GenerationOptions(temperature: 0.7)
        opts.repetitionPenalty = 1.1
        opts.topK = 40
        #expect(opts.repetitionPenalty == 1.1)
        #expect(opts.topK == 40)
    }

    // MARK: - Equatable

    @Test("Equatable considers every field — differences in new fields break equality")
    func equatableSpansEveryField() {
        let base = GenerationOptions(temperature: 0.7)
        var withRepetition = base
        withRepetition.repetitionPenalty = 1.1
        #expect(base != withRepetition)

        var sameAsBase = GenerationOptions()
        sameAsBase.temperature = 0.7
        #expect(base == sameAsBase)
    }

    // MARK: - Codable round-trip

    @Test("Codable round-trips every backend-extensible field")
    func codableRoundTripIncludesNewFields() throws {
        let original = GenerationOptions(
            temperature: 0.6,
            maximumResponseTokens: 128,
            extensions: GenerationOptions.Extensions(
                topP: 0.9,
                topK: 40,
                minP: 0.05,
                repetitionPenalty: 1.15,
                presencePenalty: 0.3,
                frequencyPenalty: 0.1,
                repetitionContextSize: 64
            )
        )
        let prompt = Transcript.Prompt(
            id: "p-1",
            segments: [.text(Transcript.TextSegment(id: "s-1", content: "hi"))],
            options: original,
            responseFormat: nil
        )
        let transcript = Transcript(entries: [.prompt(prompt)])
        let data = try JSONEncoder().encode(transcript)
        let decoded = try JSONDecoder().decode(Transcript.self, from: data)
        guard case .prompt(let restored) = decoded.entries.first else {
            Issue.record("Expected prompt entry")
            return
        }
        #expect(restored.options == original)
    }

    @Test("A transcript encoded with only Apple-mirrored options decodes with new fields as nil")
    func legacyShapedEncodingDecodesWithNilNewFields() throws {
        // Build a transcript using only Apple-compatible fields; with JSONEncoder's
        // default policy (nil → key omitted) this produces exactly the on-disk shape
        // older clients would have written before the backend-extensible fields existed.
        let appleOnly = GenerationOptions(
            temperature: 0.7,
            maximumResponseTokens: 256
        )
        let prompt = Transcript.Prompt(
            id: "p-1",
            segments: [.text(Transcript.TextSegment(id: "s-1", content: "hi"))],
            options: appleOnly,
            responseFormat: nil
        )
        let transcript = Transcript(entries: [.prompt(prompt)])

        let data = try JSONEncoder().encode(transcript)
        // Confirm the on-disk payload really omits the new keys (legacy shape).
        let raw = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let inner = try #require(raw["transcript"] as? [String: Any])
        let entries = try #require(inner["entries"] as? [[String: Any]])
        let optionsDict = try #require(entries.first?["options"] as? [String: Any])
        #expect(optionsDict["topP"] == nil)
        #expect(optionsDict["repetitionPenalty"] == nil)

        let decoded = try JSONDecoder().decode(Transcript.self, from: data)
        guard case .prompt(let restored) = decoded.entries.first else {
            Issue.record("Expected prompt entry")
            return
        }
        #expect(restored.options.temperature == 0.7)
        #expect(restored.options.maximumResponseTokens == 256)
        #expect(restored.options.topP == nil)
        #expect(restored.options.topK == nil)
        #expect(restored.options.repetitionPenalty == nil)
        #expect(restored.options.presencePenalty == nil)
        #expect(restored.options.repetitionContextSize == nil)
    }
}
