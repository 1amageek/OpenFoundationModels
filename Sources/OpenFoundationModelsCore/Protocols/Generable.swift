import Foundation

public protocol Generable: ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent {
    static var generationSchema: GenerationSchema { get }
    
    associatedtype PartiallyGenerated: ConvertibleFromGeneratedContent = Self
    
    func asPartiallyGenerated() -> Self.PartiallyGenerated
}

extension Generable {
    public func asPartiallyGenerated() -> Self.PartiallyGenerated {
        return self as! Self.PartiallyGenerated
    }
}

extension Generable where PartiallyGenerated == Self {
    public func asPartiallyGenerated() -> Self {
        return self
    }
}

