import Testing
@testable import OpenFoundationModels

// Test enums defined at top level to avoid local type macro restrictions
@Generable
enum TestStatus {
    case active
    case inactive
}

@Generable
enum TestStatusWithPending {
    case active
    case pending
}

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
        // Test enum with @Generable macro (using top-level TestStatus)
        
        // Basic test - just verify compilation
        let status = TestStatus.active
        #expect(status == .active)
        
        // Test conversion from GeneratedContent
        let statusFromContent = try TestStatus(GeneratedContent("active"))
        #expect(statusFromContent == .active)
        
        // Test conversion to GeneratedContent
        let activeContent = TestStatus.active.generatedContent
        #expect(activeContent.stringValue == "active")
        
        let inactiveContent = TestStatus.inactive.generatedContent
        #expect(inactiveContent.stringValue == "inactive")
    }
    
    @Test("Enum error handling with invalid case")
    func enumErrorHandlingInvalidCase() {
        // Test invalid case throws proper error (using top-level TestStatusWithPending)
        #expect(throws: GenerationError.self) {
            _ = try TestStatusWithPending(GeneratedContent("invalid"))
        }
    }
}