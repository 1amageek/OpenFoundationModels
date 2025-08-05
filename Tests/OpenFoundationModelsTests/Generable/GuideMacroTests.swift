import Testing
@testable import OpenFoundationModels

/// Tests for @Guide macro functionality
/// 
/// **Focus:** Validates that @Guide macro correctly provides generation guidance
/// for properties in Generable types.
///
/// **Apple Foundation Models Documentation:**
/// The @Guide macro provides natural language descriptions and programmatic
/// constraints for properties to guide model generation.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation

// MARK: - Test Types (moved from local scope to top level)

@Generable
struct TestGuidePerson {
    @Guide(description: "The person's full name")
    let name: String
    
    @Guide(description: "Age in years")  
    let age: Int
}

@Generable
struct TestGuideUser {
    @Guide(description: "Username with letters and numbers only", .pattern("[a-zA-Z0-9]+"))
    let username: String
}

@Suite("Guide Macro Tests", .tags(.guide, .macros))
struct GuideMacroTests {
    
    @Test("@Guide macro compiles without errors")
    func guideMacroCompilation() throws {
        // Test that the @Guide macro works with @Generable
        // Create instance to verify the type works properly
        let content = GeneratedContent("{\"name\": \"John\", \"age\": 30}")
        let person = try TestGuidePerson(content)
        
        // Verify the instance can be converted back to GeneratedContent
        let generated = person.generatedContent
        #expect(generated.text != "")
        
        // Verify generationSchema exists
        let schema = TestGuidePerson.generationSchema
        #expect(schema.type == "object")
    }
    
    @Test("@Guide macro with pattern constraint compiles")
    func guideMacroWithPattern() {
        // Test @Guide with pattern constraint
        // Verify the type compiles and has schema
        let schema = TestGuideUser.generationSchema
        #expect(schema.type == "object")
    }
}