import Testing
@testable import OpenFoundationModels

/// Simple tests for @Generable macro with enums
@Suite("Simple Enum Tests", .tags(.generable, .macros))
struct SimpleEnumTests {
    
    @Test("Basic enum compilation")
    func basicEnumCompilation() {
        // Just test that a basic enum can be declared
        enum BasicStatus {
            case active
            case inactive
        }
        
        // Verify it compiles
        let status = BasicStatus.active
        #expect(status == .active)
    }
    
    @Test("Enum with @Generable")
    func enumWithGenerable() throws {
        // Test enum with @Generable macro
        @Generable
        enum Status {
            case active
            case inactive
        }
        
        // Basic test - just verify compilation
        let status = Status.active
        #expect(status == .active)
        
        // Test conversion from GeneratedContent
        let statusFromContent = try Status(GeneratedContent("active"))
        #expect(statusFromContent == .active)
        
        // Test conversion to GeneratedContent
        let activeContent = Status.active.generatedContent
        #expect(activeContent.stringValue == "active")
        
        let inactiveContent = Status.inactive.generatedContent
        #expect(inactiveContent.stringValue == "inactive")
    }
    
    @Test("Enum error handling with invalid case")
    func enumErrorHandlingInvalidCase() {
        @Generable
        enum Status {
            case active
            case pending
        }
        
        // Test invalid case throws proper error
        #expect(throws: GenerationError.self) {
            _ = try Status(GeneratedContent("invalid"))
        }
    }
}