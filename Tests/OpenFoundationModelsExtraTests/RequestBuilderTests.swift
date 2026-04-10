import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsExtra

private struct TestRequestBuilder: RequestBuilder {
    struct BuildResult: Sendable {}
    func build(transcript: Transcript, options: GenerationOptions?, stream: Bool) throws -> BuildResult {
        BuildResult()
    }
}

@Suite("RequestBuilder Tests")
struct RequestBuilderTests {

    private let builder = TestRequestBuilder()

    // MARK: - Empty

    @Test("empty segments produce empty string")
    func emptySegments() {
        #expect(builder.segmentsToText([]) == "")
    }

    // MARK: - Text segments

    @Test("single text segment returns its content")
    func singleTextSegment() {
        let segments: [Transcript.Segment] = [.text(.init(content: "Hello"))]
        #expect(builder.segmentsToText(segments) == "Hello")
    }

    @Test("multiple text segments are joined with a space")
    func multipleTextSegments() {
        let segments: [Transcript.Segment] = [
            .text(.init(content: "Hello")),
            .text(.init(content: "World")),
        ]
        #expect(builder.segmentsToText(segments) == "Hello World")
    }

    @Test("reasoning segments are excluded from plain text conversion")
    func reasoningSegmentsIgnored() {
        let segments: [Transcript.Segment] = [
            .text(.init(content: "Visible")),
            .reasoning(.init(content: "Hidden")),
            .text(.init(content: "Answer")),
        ]
        #expect(builder.segmentsToText(segments) == "Visible Answer")
    }

    // MARK: - Structure segments

    @Test("structure segment is serialised via jsonString")
    func structureSegmentString() {
        let content = GeneratedContent(kind: .string("hello"))
        let seg = Transcript.StructuredSegment(id: "s1", source: "test", content: content)
        let result = builder.segmentsToText([.structure(seg)])
        #expect(result == content.jsonString)
    }

    @Test("structure segment with number content serialises correctly")
    func structureSegmentNumber() {
        let content = GeneratedContent(kind: .number(42.0))
        let seg = Transcript.StructuredSegment(id: "s2", source: "test", content: content)
        let result = builder.segmentsToText([.structure(seg)])
        #expect(result == content.jsonString)
    }

    @Test("structure segment with object content serialises correctly")
    func structureSegmentObject() {
        let content = GeneratedContent(kind: .structure(
            properties: ["key": GeneratedContent(kind: .string("value"))],
            orderedKeys: ["key"]
        ))
        let seg = Transcript.StructuredSegment(id: "s3", source: "test", content: content)
        let result = builder.segmentsToText([.structure(seg)])
        #expect(result == content.jsonString)
    }

    // MARK: - Image segments

    @Test("base64 image segment produces [Image #1] placeholder")
    func imageSegmentBase64() {
        let seg = Transcript.ImageSegment(source: .base64(data: "abc==", mediaType: "image/png"))
        #expect(builder.segmentsToText([.image(seg)]) == "[Image #1]")
    }

    @Test("URL image segment produces [Image #1] placeholder")
    func imageSegmentURL() {
        let url = URL(string: "https://example.com/photo.jpg")!
        let seg = Transcript.ImageSegment(source: .url(url))
        #expect(builder.segmentsToText([.image(seg)]) == "[Image #1]")
    }

    @Test("multiple image segments use consecutive indices")
    func multipleImageSegments() {
        let seg1 = Transcript.ImageSegment(source: .base64(data: "a", mediaType: "image/png"))
        let seg2 = Transcript.ImageSegment(source: .base64(data: "b", mediaType: "image/jpeg"))
        let seg3 = Transcript.ImageSegment(source: .base64(data: "c", mediaType: "image/png"))
        let result = builder.segmentsToText([.image(seg1), .image(seg2), .image(seg3)])
        #expect(result == "[Image #1] [Image #2] [Image #3]")
    }

    @Test("image index resets to 1 on each call")
    func imageIndexResetsPerCall() {
        let seg = Transcript.ImageSegment(source: .base64(data: "x", mediaType: "image/png"))
        let segments: [Transcript.Segment] = [.image(seg)]
        #expect(builder.segmentsToText(segments) == "[Image #1]")
        #expect(builder.segmentsToText(segments) == "[Image #1]")
    }

    // MARK: - Mixed segments

    @Test("mixed segments are joined in original order")
    func mixedSegments() {
        let imgSeg = Transcript.ImageSegment(source: .base64(data: "x", mediaType: "image/png"))
        let structContent = GeneratedContent(kind: .string("data"))
        let structSeg = Transcript.StructuredSegment(id: "s1", source: "src", content: structContent)

        let segments: [Transcript.Segment] = [
            .text(.init(content: "Before")),
            .image(imgSeg),
            .structure(structSeg),
            .text(.init(content: "After")),
        ]

        let expected = "Before [Image #1] \(structContent.jsonString) After"
        #expect(builder.segmentsToText(segments) == expected)
    }

    @Test("two images interspersed with text increment independently")
    func twoImagesWithText() {
        let img1 = Transcript.ImageSegment(source: .base64(data: "a", mediaType: "image/png"))
        let img2 = Transcript.ImageSegment(source: .url(URL(string: "https://example.com/b.png")!))

        let segments: [Transcript.Segment] = [
            .text(.init(content: "First:")),
            .image(img1),
            .text(.init(content: "Second:")),
            .image(img2),
        ]

        #expect(builder.segmentsToText(segments) == "First: [Image #1] Second: [Image #2]")
    }
}
