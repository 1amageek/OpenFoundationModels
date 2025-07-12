import Testing
@testable import OpenFoundationModels

/// Tests for @Generable macro functionality
/// 
/// **Focus:** Validates that @Generable macro correctly generates required protocol conformances
/// and methods for types to be used in guided generation workflows.
///
/// **Apple Foundation Models Documentation:**
/// The @Generable macro automatically generates the necessary conformances and methods
/// for structured generation with Apple's Foundation Models.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation
@Suite("Generable Macro Tests", .tags(.generable, .macros))
struct GenerableMacroTests {
    
    @Test("@Generable macro compiles without errors")
    func generableMacroCompilation() {
        // Test that the macro can be applied and compiles
        @Generable
        struct SimpleStruct {
            let value: String
        }
        
        // Basic verification that the type exists
        #expect(SimpleStruct.self is SimpleStruct.Type)
    }
    
    @Test("@Generable macro generates required members")
    func generableMacroGeneratesMembers() {
        @Generable
        struct Person {
            let name: String
            let age: Int
        }
        
        // Verify generationSchema property exists
        let schema = Person.generationSchema
        #expect(schema.type == "object")
        
        // Test will pass if macro generates required members successfully
    }
}