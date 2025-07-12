import Testing
@testable import OpenFoundationModels

/// Tests for SystemLanguageModel functionality
/// 
/// **Focus:** Validates SystemLanguageModel core functionality including
/// availability status, UseCase initialization, and supported languages.
///
/// **Apple Foundation Models Documentation:**
/// SystemLanguageModel provides access to on-device language models
/// with availability checking and use case specification.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel
@Suite("System Language Model Tests", .tags(.core, .unit))
struct SystemLanguageModelTests {
    
    @Test("SystemLanguageModel default instance exists")
    func systemLanguageModelDefaultInstance() {
        // Test that default instance is accessible
        let model = SystemLanguageModel.default
        // Basic verification that the instance exists
        #expect(type(of: model) == SystemLanguageModel.self)
    }
    
    @Test("SystemLanguageModel availability property")
    func systemLanguageModelAvailability() {
        // Test availability property access
        let model = SystemLanguageModel.default
        let availability = model.availability
        
        // Should be either available or unavailable with reason
        switch availability {
        case .available:
            #expect(Bool(true)) // Available is valid
        case .unavailable(let reason):
            // Verify reason is one of the documented cases
            switch reason {
            case .appleIntelligenceNotEnabled, .deviceNotEligible, .modelNotReady:
                #expect(Bool(true)) // Valid reason
            }
        }
    }
    
    @Test("SystemLanguageModel isAvailable convenience property")
    func systemLanguageModelIsAvailable() {
        // Test convenience property
        let model = SystemLanguageModel.default
        let isAvailable = model.isAvailable
        
        // Should be either true or false
        #expect(isAvailable == true || isAvailable == false)
        
        // Should match availability status
        switch model.availability {
        case .available:
            #expect(isAvailable == true)
        case .unavailable:
            #expect(isAvailable == false)
        }
    }
    
    @Test("SystemLanguageModel UseCase initialization")
    func systemLanguageModelUseCase() {
        // Test UseCase creation
        let generalUseCase = SystemLanguageModel.UseCase.general
        let contentTaggingUseCase = SystemLanguageModel.UseCase.contentTagging
        
        // Verify they are different use cases
        #expect(generalUseCase != contentTaggingUseCase)
        
        // Verify they are equal to themselves (Equatable conformance)
        #expect(generalUseCase == SystemLanguageModel.UseCase.general)
        #expect(contentTaggingUseCase == SystemLanguageModel.UseCase.contentTagging)
    }
    
    @Test("SystemLanguageModel Availability enum cases")
    func systemLanguageModelAvailabilityEnum() {
        // Test that we can create availability states
        let available = SystemLanguageModel.Availability.available
        let unavailable = SystemLanguageModel.Availability.unavailable(.modelNotReady)
        
        // Test isAvailable convenience property
        #expect(available.isAvailable == true)
        #expect(unavailable.isAvailable == false)
        
        // Test other unavailable reasons
        let notEnabled = SystemLanguageModel.Availability.unavailable(.appleIntelligenceNotEnabled)
        #expect(notEnabled.isAvailable == false)
        
        let notEligible = SystemLanguageModel.Availability.unavailable(.deviceNotEligible)
        #expect(notEligible.isAvailable == false)
    }
}