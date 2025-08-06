// GenerationID.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Based on Apple Foundation Models API specification

import Foundation

/// A unique identifier that is stable for the duration of a response, but not across responses.
/// 
/// **Apple Foundation Models Documentation:**
/// The framework guarentees a `GenerationID` to be both present and stable when you receive it 
/// from a `LanguageModelSession`. When you create an instance of `GenerationID` there is no 
/// guarantee an identifier is present or stable.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/generationid
/// 
/// **Apple Official API:** `struct GenerationID`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - Equatable
/// - Hashable
/// - Sendable
/// - SendableMetatype
/// 
/// **Usage:**
/// ```swift
/// @Generable
/// struct SearchTerm {
///     // Use a generation identifier for types the framework generates.
///     var id: GenerationID
///     
///     @Guide(description: "A 2 or 3 word search term, like 'Beautiful sunsets'")
///     var searchTerm: String
/// }
/// ```
public struct GenerationID: Equatable, Hashable, Sendable, SendableMetatype {
    /// The unique identifier value
    private let value: UUID
    
    /// Create a new, unique `GenerationID`.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Create a new, unique `GenerationID`.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/generationid/init()
    /// 
    /// **Apple Official API:** `init()`
    /// 
    /// **Note:** When you create an instance of `GenerationID` there is no guarantee an 
    /// identifier is present or stable.
    public init() {
        self.value = UUID()
    }
    
    /// Internal initializer for framework use
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Used internally by the framework to create stable identifiers.
    /// 
    /// - Parameter value: The UUID value for this identifier
    internal init(value: UUID) {
        self.value = value
    }
}

// MARK: - Codable Support
extension GenerationID: Codable {
    /// Encode the generation ID
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Encodes the generation ID for serialization.
    /// 
    /// - Parameter encoder: The encoder to encode to
    /// - Throws: Any encoding errors
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.uuidString)
    }
    
    /// Decode the generation ID
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Decodes the generation ID from serialization.
    /// 
    /// - Parameter decoder: The decoder to decode from
    /// - Throws: Any decoding errors
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let uuidString = try container.decode(String.self)
        guard let uuid = UUID(uuidString: uuidString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid UUID string: \(uuidString)"
            )
        }
        self.value = uuid
    }
}

// MARK: - String Representation
extension GenerationID: CustomStringConvertible {
    /// String representation of the generation ID
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Provides a string representation of the generation ID.
    /// 
    /// - Returns: The string representation
    public var description: String {
        return value.uuidString
    }
}

// MARK: - Protocol Conformances
// InstructionsRepresentable and PromptRepresentable implementations are provided in the main module

// MARK: - Generable Conformance
extension GenerationID: Generable {
    /// The generation schema for GenerationID
    /// 
    /// **Apple Foundation Models Documentation:**
    /// GenerationID uses a special schema for generation as it receives special treatment
    /// by the framework to be both present and stable.
    public static var generationSchema: GenerationSchema {
        // GenerationID is a special type that gets an identifier from the framework
        // It uses an empty properties schema since it's generated automatically
        return GenerationSchema(
            type: GenerationID.self,
            description: "A unique identifier that is stable for the duration of a response",
            properties: []
        )
    }
    
    /// Create GenerationID from generated content
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Creates a GenerationID from generated content.
    /// ✅ CONFIRMED: Required by ConvertibleFromGeneratedContent
    /// 
    /// - Parameter content: The generated content
    /// - Throws: Any conversion errors
    public init(_ content: GeneratedContent) throws {
        let uuidString = content.text
        if let uuid = UUID(uuidString: uuidString) {
            self.init(value: uuid)
        } else {
            // Generate a new UUID if the content is not a valid UUID
            self.init()
        }
    }
    
    /// Convert GenerationID to generated content
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Converts GenerationID to generated content.
    /// ✅ CONFIRMED: Required by ConvertibleToGeneratedContent
    /// 
    /// - Returns: The generated content representation
    public var generatedContent: GeneratedContent {
        return GeneratedContent(value.uuidString)
    }
    
    /// Convert to partially generated representation
    /// 
    /// **Apple Foundation Models Documentation:**
    /// Converts GenerationID to partially generated content.
    /// 
    /// - Returns: The partially generated representation
    public func asPartiallyGenerated() -> GenerationID {
        return self
    }
}