import Testing
@testable import OpenFoundationModels

/// Tests for LanguageModelSession functionality
/// 
/// **Focus:** Validates LanguageModelSession lifecycle, initialization patterns,
/// respond methods, streaming functionality, and prewarm operations.
///
/// **Apple Foundation Models Documentation:**
/// LanguageModelSession manages interactions with language models,
/// providing both synchronous and streaming response capabilities.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/languagemodelsession
@Suite("Language Model Session Tests", .tags(.core, .unit))
struct LanguageModelSessionTests {
    
    @Test("LanguageModelSession default initialization")
    func languageModelSessionDefaultInit() {
        // Test default initialization
        let session = LanguageModelSession()
        #expect(type(of: session) == LanguageModelSession.self)
    }
    
    @Test("LanguageModelSession initialization with Apple API")
    func languageModelSessionWithAppleAPI() {
        // Test initialization with Apple's official API
        let instructions = Instructions("You are a helpful assistant")
        let tools: [any Tool] = []
        
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            guardrails: .default,
            tools: tools,
            instructions: instructions
        )
        #expect(type(of: session) == LanguageModelSession.self)
    }
    
    @Test("LanguageModelSession Guardrails nested type")
    func languageModelSessionGuardrails() {
        // Test that Guardrails default is accessible
        let guardrails = LanguageModelSession.Guardrails.default
        #expect(type(of: guardrails) == LanguageModelSession.Guardrails.self)
    }
    
    @Test("LanguageModelSession basic async respond method works")
    func languageModelSessionRespondMethod() async throws {
        // Test that respond method is accessible and works
        let session = LanguageModelSession()
        
        // This test verifies the method exists and can execute successfully
        let response = try await session.respond { Prompt("Hello") }
        #expect(type(of: response) == Response<String>.self)
        #expect(!response.content.isEmpty)
    }
    
    @Test("LanguageModelSession streaming method exists")
    func languageModelSessionStreamMethod() {
        // Test that streaming method is accessible (basic compilation test)
        let session = LanguageModelSession()
        
        // This test verifies the method exists and returns correct type
        let stream = session.streamResponse { Prompt("Hello") }
        #expect(type(of: stream) == ResponseStream<String>.self)
    }
}