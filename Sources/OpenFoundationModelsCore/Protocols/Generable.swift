import Foundation

public protocol Generable: ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent {
    
    /// A representation of partially generated content
    associatedtype PartiallyGenerated: ConvertibleFromGeneratedContent = Self
    
    /// An instance of the generation schema.
    static var generationSchema: GenerationSchema { get }
}

extension Generable {
    
    /// The partially generated type of this struct.
    public func asPartiallyGenerated() -> Self.PartiallyGenerated {
        // Default implementation - works when PartiallyGenerated == Self
        return self as! Self.PartiallyGenerated
    }
}

extension Generable {
    
    /// A representation of partially generated content
    public typealias PartiallyGenerated = Self
}

