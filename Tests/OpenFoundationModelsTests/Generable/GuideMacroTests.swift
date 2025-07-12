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
@Suite("Guide Macro Tests", .tags(.guide, .macros))
struct GuideMacroTests {
    
    @Test("@Guide macro compiles without errors")
    func guideMacroCompilation() {
        // Test that the @Guide macro can be applied and compiles
        @Generable
        struct Person {
            @Guide(description: "The person's full name")
            let name: String
            
            @Guide(description: "Age in years")  
            let age: Int
        }
        
        // Basic verification that the type exists and compiles
        #expect(Person.self is Person.Type)
    }
    
    @Test("@Guide macro with pattern constraint compiles")
    func guideMacroWithPattern() {
        // Test @Guide with pattern constraint
        @Generable
        struct User {
            @Guide(description: "Username with letters and numbers only", .pattern("[a-zA-Z0-9]+"))
            let username: String
        }
        
        // Verify the type compiles and has schema
        let schema = User.generationSchema
        #expect(schema.type == "object")
    }
}