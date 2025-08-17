import Foundation

public protocol Generable: ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent, InstructionsRepresentable, PromptRepresentable {
    static var generationSchema: GenerationSchema { get }
    
    associatedtype PartiallyGenerated: ConvertibleFromGeneratedContent = Self
    
    func asPartiallyGenerated() -> Self.PartiallyGenerated
}

extension Generable where PartiallyGenerated == Self {
    public func asPartiallyGenerated() -> Self {
        return self
    }
}

