import Testing
@testable import OpenFoundationModels

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

@Suite("Simple Enum Tests", .tags(.generable, .macros))
struct SimpleEnumTests {
    
    @Test("Basic enum compilation")
    func basicEnumCompilation() {
        enum BasicStatus {
            case active
            case inactive
        }
        
        let status = BasicStatus.active
        #expect(status == .active)
    }
    
    @Test("Enum with @Generable")
    func enumWithGenerable() throws {
        
        let status = TestStatus.active
        #expect(status == .active)
        
        let statusFromContent = try TestStatus(GeneratedContent("active"))
        #expect(statusFromContent == .active)
        
        let activeContent = TestStatus.active.generatedContent
        #expect(activeContent.text == "active")
        
        let inactiveContent = TestStatus.inactive.generatedContent
        #expect(inactiveContent.text == "inactive")
    }
    
    @Test("Enum error handling with invalid case")
    func enumErrorHandlingInvalidCase() {
        #expect(throws: GenerationError.self) {
            _ = try TestStatusWithPending(GeneratedContent("invalid"))
        }
    }
}