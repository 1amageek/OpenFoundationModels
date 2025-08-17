import Foundation
import OpenFoundationModelsCore

extension Generable {
    public func asPartiallyGenerated() -> Self.PartiallyGenerated {
        if Self.PartiallyGenerated.self == Self.self {
            return self as! Self.PartiallyGenerated
        } else {
            do {
                return try Self.PartiallyGenerated(self.generatedContent)
            } catch {
                fatalError("Failed to create PartiallyGenerated from generatedContent: \(error)")
            }
        }
    }
}

