import OpenFoundationModels
import OpenFoundationModelsCore

extension Transcript {

    /// Extracts text from an array of segments.
    /// Image segments are represented as `[Image #N]` placeholders.
    public static func extractText(from segments: [Segment]) -> String {
        var parts: [String] = []
        var imageIndex = 1
        for segment in segments {
            switch segment {
            case .text(let t):
                parts.append(t.content)
            case .structure(let s):
                parts.append(s.content.jsonString)
            case .image:
                parts.append("[Image #\(imageIndex)]")
                imageIndex += 1
            }
        }
        return parts.joined(separator: " ")
    }

    /// Extracts GenerationOptions from the most recent prompt entry.
    public static func extractOptions(from transcript: Transcript) -> GenerationOptions? {
        for entry in transcript.reversed() {
            if case .prompt(let prompt) = entry {
                return prompt.options
            }
        }
        return nil
    }

    /// Extracts tool definitions from the most recent instructions entry.
    /// Returns nil if no instructions with tools are found.
    public static func extractToolDefinitions(from transcript: Transcript) -> [Transcript.ToolDefinition]? {
        for entry in transcript.reversed() {
            if case .instructions(let instructions) = entry,
               !instructions.toolDefinitions.isEmpty {
                return instructions.toolDefinitions
            }
        }
        return nil
    }

    /// Extracts the response schema from the most recent prompt entry.
    public static func extractResponseSchema(from transcript: Transcript) -> GenerationSchema? {
        for entry in transcript.reversed() {
            if case .prompt(let prompt) = entry {
                return prompt.responseFormat?._schema
            }
        }
        return nil
    }
}
