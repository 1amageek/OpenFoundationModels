import Foundation
import OpenFoundationModelsCore

public protocol Tool<Arguments, Output>: Sendable {
    associatedtype Output: PromptRepresentable
    
    associatedtype Arguments: ConvertibleFromGeneratedContent
    
    var name: String { get }
    
    var description: String { get }
    
    var includesSchemaInInstructions: Bool { get }
    
    var parameters: GenerationSchema { get }
    
    func call(arguments: Arguments) async throws -> Output
}

extension Tool {
    public var name: String {
        return String(describing: type(of: self))
    }
    
    public var includesSchemaInInstructions: Bool {
        return true
    }
}

extension Tool where Self.Arguments: Generable {
    public var parameters: GenerationSchema {
        return Arguments.generationSchema
    }
}
