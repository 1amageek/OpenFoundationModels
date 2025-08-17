import Foundation

public struct LanguageModelFeedback: Sendable {
    
    public enum Sentiment: CaseIterable, Equatable, Hashable, Sendable {
        case positive
        case neutral
        case negative
    }
    
    public struct Issue: Sendable {
        
        public enum Category: CaseIterable, Equatable, Hashable, Sendable {
            case incorrect
            case unhelpful
            case didNotFollowInstructions
            case tooVerbose
            case stereotypeOrBias
            case vulgarOrOffensive
            case suggestiveOrSexual
            case triggeredGuardrailUnexpectedly
        }
        
        public let category: Category
        public let explanation: String?
        
        public init(category: Category, explanation: String? = nil) {
            self.category = category
            self.explanation = explanation
        }
    }
    
    internal let _data: Data?
    
    internal init(data: Data? = nil) {
        self._data = data
    }
}