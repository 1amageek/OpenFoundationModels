import Foundation
@_spi(Internal) import OpenFoundationModelsCore

extension Instructions {
    /// Converts the instructions' components to transcript segments.
    ///
    /// Text components become ``Transcript/Segment/text(_:)`` segments,
    /// image components become ``Transcript/Segment/image(_:)`` segments,
    /// preserving the order of mixed-modality instructions.
    package var segments: [Transcript.Segment] {
        components.map { component in
            switch component {
            case .text(let text):
                return .text(Transcript.TextSegment(id: UUID().uuidString, content: text.value))
            case .image(let image):
                let source: Transcript.ImageSegment.ImageSource
                switch image.source {
                case .base64(let data, let mediaType):
                    source = .base64(data: data, mediaType: mediaType)
                case .url(let url):
                    source = .url(url)
                }
                return .image(Transcript.ImageSegment(id: UUID().uuidString, source: source))
            }
        }
    }
}
