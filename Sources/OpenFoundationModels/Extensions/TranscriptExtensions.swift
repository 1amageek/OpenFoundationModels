// TranscriptExtensions.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Extensions for Transcript and related types

import Foundation
import OpenFoundationModelsCore

// MARK: - Transcript Codable Extension

extension Transcript: Codable {
    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let entries = try container.decode([Entry].self, forKey: .entries)
        self.init(entries: entries)
    }
    
    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entries, forKey: .entries)
    }
    
    private enum CodingKeys: String, CodingKey {
        case entries
    }
}

// MARK: - Transcript.Entry Extensions

// CustomStringConvertible is now implemented directly in Transcript.swift

// MARK: - Transcript.Segment Extensions

extension Transcript.Segment: CustomStringConvertible {
    public var description: String {
        switch self {
        case .text(let textSegment):
            return textSegment.description
        case .structure(let structuredSegment):
            return structuredSegment.description
        }
    }
}

// MARK: - Transcript.TextSegment Extensions

extension Transcript.TextSegment: CustomStringConvertible {
    public var description: String {
        return content
    }
}

// MARK: - Transcript.StructuredSegment Extensions

extension Transcript.StructuredSegment: CustomStringConvertible {
    public var description: String {
        return "StructuredSegment(source: \(source), content: \(content.text.prefix(50))...)"
    }
}

// MARK: - Transcript.Instructions Extensions

extension Transcript.Instructions: CustomStringConvertible {
    public var description: String {
        let segmentDescriptions = segments.map { $0.description }.joined(separator: "\n")
        return "Instructions(id: \(id)): \(segmentDescriptions)"
    }
}

// MARK: - Transcript.Prompt Extensions

extension Transcript.Prompt: CustomStringConvertible {
    public var description: String {
        let segmentDescriptions = segments.map { $0.description }.joined(separator: "\n")
        return "Prompt(id: \(id)): \(segmentDescriptions)"
    }
}

// MARK: - Transcript.ResponseFormat Extensions

extension Transcript.ResponseFormat: CustomStringConvertible {
    public var description: String {
        return "ResponseFormat(name: \(name))"
    }
}

// MARK: - Transcript.ToolCalls Extensions

extension Transcript.ToolCalls: CustomStringConvertible {
    public var description: String {
        let callDescriptions = toolCalls.map { $0.description }.joined(separator: ", ")
        return "ToolCalls(id: \(id)): [\(callDescriptions)]"
    }
}

// MARK: - Transcript.ToolCall Extensions

extension Transcript.ToolCall: CustomStringConvertible {
    public var description: String {
        return "ToolCall(id: \(id), toolName: \(toolName), arguments: \(arguments.text))"
    }
}

// MARK: - Transcript.ToolOutput Extensions

extension Transcript.ToolOutput: CustomStringConvertible {
    public var description: String {
        return "ToolOutput(id: \(id), toolName: \(toolName), segments: \(segments.count))"
    }
}

// MARK: - Transcript.Response Extensions

extension Transcript.Response: CustomStringConvertible {
    public var description: String {
        let segmentDescriptions = segments.map { $0.description }.joined(separator: "\n")
        return "Response(id: \(id), assetIDs: \(assetIDs.count)): \(segmentDescriptions)"
    }
}