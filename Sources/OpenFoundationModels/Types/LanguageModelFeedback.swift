// LanguageModelFeedback.swift
// OpenFoundationModels
//
// ✅ APPLE OFFICIAL: Based on Apple Foundation Models API specification

import Foundation

/// Feedback appropriate for attaching to Feedback Assistant.
/// 
/// **Apple Foundation Models Documentation:**
/// Feedback appropriate for attaching to Feedback Assistant.
/// 
/// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback
/// 
/// **Apple Official API:** `struct LanguageModelFeedback`
/// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
/// - Beta Software: Contains preliminary API information
/// 
/// **Conformances:**
/// - Sendable
/// - SendableMetatype
public struct LanguageModelFeedback: Sendable, SendableMetatype {
    
    // MARK: - Nested Types
    
    /// A sentiment regarding the model's response.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// A sentiment regarding the model's response.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment
    /// 
    /// **Apple Official API:** `enum Sentiment`
    /// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
    /// - Beta Software: Contains preliminary API information
    /// 
    /// **Conformances:**
    /// - CaseIterable
    /// - Copyable  
    /// - Equatable
    /// - Hashable
    /// - Sendable
    /// - SendableMetatype
    public enum Sentiment: CaseIterable, Equatable, Hashable, Sendable, SendableMetatype {
        /// A positive sentiment
        /// ✅ APPLE SPEC: case positive
        case positive
        
        /// A neutral sentiment
        /// ✅ APPLE SPEC: case neutral
        case neutral
        
        /// A negative sentiment
        /// ✅ APPLE SPEC: case negative
        case negative
    }
    
    /// An issue with the model's response.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An issue with the model's response.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue
    /// 
    /// **Apple Official API:** `struct Issue`
    /// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
    /// - Beta Software: Contains preliminary API information
    /// 
    /// **Conformances:**
    /// - Sendable
    /// - SendableMetatype
    public struct Issue: Sendable, SendableMetatype {
        
        /// Categories for model response issues.
        /// 
        /// **Apple Foundation Models Documentation:**
        /// Categories for model response issues.
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/category
        /// 
        /// **Apple Official API:** `enum Category`
        /// - iOS 26.0+, iPadOS 26.0+, macOS 26.0+, visionOS 26.0+
        /// - Beta Software: Contains preliminary API information
        /// 
        /// **Conformances:**
        /// - CaseIterable
        /// - Copyable
        /// - Equatable
        /// - Hashable
        /// - Sendable
        /// - SendableMetatype
        public enum Category: CaseIterable, Equatable, Hashable, Sendable, SendableMetatype {
            /// The model provided an incorrect response.
            /// ✅ APPLE SPEC: case incorrect
            case incorrect
            
            /// The response was not unhelpful.
            /// ✅ APPLE SPEC: case unhelpful
            case unhelpful
            
            /// The model did not follow instructions correctly.
            /// ✅ APPLE SPEC: case didNotFollowInstructions
            case didNotFollowInstructions
            
            /// The response was too verbose.
            /// ✅ APPLE SPEC: case tooVerbose
            case tooVerbose
            
            /// The model exhibited bias or perpetuated a stereotype.
            /// ✅ APPLE SPEC: case stereotypeOrBias
            case stereotypeOrBias
            
            /// The model produces vulgar or offensive material.
            /// ✅ APPLE SPEC: case vulgarOrOffensive
            case vulgarOrOffensive
            
            /// The model produces suggestive or sexual material.
            /// ✅ APPLE SPEC: case suggestiveOrSexual
            case suggestiveOrSexual
            
            /// The model throws a guardrail violation when it shouldn't.
            /// ✅ APPLE SPEC: case triggeredGuardrailUnexpectedly
            case triggeredGuardrailUnexpectedly
        }
        
        /// The category of the issue
        /// ✅ APPLE SPEC: category property
        public let category: Category
        
        /// An optional explanation of the issue
        /// ✅ APPLE SPEC: explanation property
        public let explanation: String?
        
        /// Creates a new issue
        /// 
        /// **Apple Foundation Models Documentation:**
        /// Creates a new issue
        /// 
        /// **Source:** https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue/init(category:explanation:)
        /// 
        /// - Parameters:
        ///   - category: The category of the issue
        ///   - explanation: An optional explanation of the issue
        public init(category: Category, explanation: String? = nil) {
            self.category = category
            self.explanation = explanation
        }
    }
    
    // MARK: - Properties
    
    // Internal properties for feedback data (Apple doesn't document public properties)
    // The actual implementation details are internal to Apple's framework
    internal let _data: Data?
    
    // MARK: - Initializers
    
    /// Creates a new feedback instance
    /// 
    /// **Implementation Note:**
    /// Apple's documentation doesn't specify public initializers or properties.
    /// This is likely an opaque type created by the framework internally.
    internal init(data: Data? = nil) {
        self._data = data
    }
}