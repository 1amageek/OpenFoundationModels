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
    
    @Test("@Generable macro works with simple enum")
    func generableMacroSimpleEnum() throws {
        @Generable(description: "User activity status")
        enum Status {
            case active
            case inactive
            case pending
        }
        
        // Verify enum compiles with @Generable
        #expect(Status.self is Status.Type)
        
        // Verify generationSchema property exists
        let schema = Status.generationSchema
        #expect(schema.type == "string")
        // Note: anyOf is stored internally but not directly accessible in current implementation
        
        // Test enum case to GeneratedContent conversion
        let activeStatus = Status.active
        let content = activeStatus.generatedContent
        #expect(content.stringValue == "active")
        
        // Test GeneratedContent to enum conversion
        let statusFromContent = try Status(GeneratedContent("pending"))
        #expect(statusFromContent == .pending)
    }
    
    // TODO: Fix enum support - currently causing compiler crash
    // @Test("@Generable macro works with enum with raw values")
    // func generableMacroEnumWithRawValues() {
    //     @Generable(description: "Priority levels")
    //     enum Priority: String {
    //         case high = "HIGH"
    //         case medium = "MEDIUM"
    //         case low = "LOW"
    //     }
    //     
    //     // Verify enum compiles
    //     #expect(Priority.self is Priority.Type)
    //     
    //     // Test conversion
    //     let highPriority = Priority.high
    //     let content = highPriority.generatedContent
    //     #expect(content.stringValue == "high")
    // }
    // 
    // @Test("@Generable macro works with enum with associated values")
    // func generableMacroEnumWithAssociatedValues() {
    //     @Generable(description: "Task result")
    //     enum TaskResult {
    //         case success(message: String)
    //         case failure(error: String, code: Int)
    //         case pending
    //     }
    //     
    //     // Verify enum compiles
    //     #expect(TaskResult.self is TaskResult.Type)
    //     
    //     // Verify schema
    //     let schema = TaskResult.generationSchema
    //     #expect(schema.type == "string")
    //     
    //     // Test simple case
    //     let pendingResult = TaskResult.pending
    //     let pendingContent = pendingResult.generatedContent
    //     #expect(pendingContent.stringValue == "pending")
    //     
    //     // Test associated values case (currently TODO in implementation)
    //     let successResult = TaskResult.success(message: "Operation completed")
    //     let successContent = successResult.generatedContent
    //     #expect(successContent.stringValue.contains("success"))
    // }
    // 
    // @Test("@Generable macro generates init from GeneratedContent for enum")
    // func generableMacroEnumInitFromGeneratedContent() throws {
    //     @Generable
    //     enum Color {
    //         case red
    //         case green
    //         case blue
    //     }
    //     
    //     // Test initialization from GeneratedContent
    //     let redContent = GeneratedContent("red")
    //     let redColor = try Color(redContent)
    //     #expect(redColor == .red)
    //     
    //     let blueContent = GeneratedContent("blue")
    //     let blueColor = try Color(blueContent)
    //     #expect(blueColor == .blue)
    //     
    //     // Test invalid case
    //     let invalidContent = GeneratedContent("yellow")
    //     #expect(throws: Error.self) {
    //         _ = try Color(invalidContent)
    //     }
    // }
}