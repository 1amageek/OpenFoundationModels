import Foundation

/// A prompt from a person to the model
/// ✅ APPLE SPEC: LanguageModelSession.Prompt structure
/// Referenced in Apple Foundation Models documentation
public struct Prompt: Sendable {
    /// The segments that make up this prompt
    /// ✅ APPLE SPEC: segments property
    public let segments: [Segment]
    
    /// Initialize a prompt with segments
    /// ✅ APPLE SPEC: Standard initializer
    /// - Parameter segments: The segments that make up this prompt
    public init(segments: [Segment]) {
        self.segments = segments
    }
    
    /// Initialize a prompt with a single text segment
    /// ✅ APPLE SPEC: Convenience initializer for simple text prompts
    /// - Parameter text: The prompt text
    public init(_ text: String) {
        self.segments = [Segment(text: text)]
    }
    
    /// Get the text content of the prompt (convenience for single segment prompts)
    /// - Returns: The combined text of all segments
    public var text: String {
        return segments.map { $0.text }.joined(separator: "\n")
    }
}

// MARK: - Prompt.Segment

extension Prompt {
    /// A segment of a prompt
    /// ✅ APPLE SPEC: Prompt.Segment structure
    public struct Segment: Sendable {
        /// Unique identifier for this segment
        /// ✅ APPLE SPEC: id property
        public let id: String
        
        /// The text content of this segment
        /// ✅ APPLE SPEC: text content
        public let text: String
        
        /// Initialize a segment with text
        /// ✅ APPLE SPEC: Standard initializer
        /// - Parameters:
        ///   - text: The text content
        ///   - id: Optional unique identifier (generates UUID if not provided)
        public init(text: String, id: String = UUID().uuidString) {
            self.text = text
            self.id = id
        }
    }
}

// MARK: - ExpressibleByStringLiteral
extension Prompt: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

