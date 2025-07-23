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
    
    @Test("@Generable macro works with enum with associated values")
    func generableMacroEnumWithAssociatedValues() throws {
        @Generable(description: "Task result")
        enum TaskResult {
            case success(message: String)
            case failure(error: String, code: Int)
            case pending
        }
        
        // Verify enum compiles
        #expect(TaskResult.self is TaskResult.Type)
        
        // Verify schema is object type for discriminated union
        let schema = TaskResult.generationSchema
        #expect(schema.type == "object")
        
        // Test simple case - no associated values
        let pendingResult = TaskResult.pending
        let pendingContent = pendingResult.generatedContent
        let pendingProps = try pendingContent.properties()
        #expect(pendingProps["case"]?.stringValue == "pending")
        
        // Test labeled associated value case (treated as multiple values)
        let successResult = TaskResult.success(message: "Operation completed")
        let successContent = successResult.generatedContent
        let successProps = try successContent.properties()
        #expect(successProps["case"]?.stringValue == "success")
        
        // For labeled parameters, value is an object with properties
        let valueProps = try successProps["value"]?.properties()
        #expect(valueProps?["message"]?.stringValue == "Operation completed")
        
        // Test multiple associated values case
        let failureResult = TaskResult.failure(error: "Network error", code: 500)
        let failureContent = failureResult.generatedContent
        let failureProps = try failureContent.properties()
        #expect(failureProps["case"]?.stringValue == "failure")
        let failureValueProps = try failureProps["value"]?.properties()
        #expect(failureValueProps?["error"]?.stringValue == "Network error")
        #expect(failureValueProps?["code"]?.stringValue == "500")
    }
    
    @Test("@Generable macro generates init from GeneratedContent for enum with associated values")
    func generableMacroEnumInitFromGeneratedContent() throws {
        @Generable
        enum TaskResult {
            case success(message: String)
            case failure(error: String, code: Int)
            case pending
        }
        
        // Test simple case initialization
        let pendingJson = """
        {"case": "pending", "value": ""}
        """
        let pendingContent = GeneratedContent(pendingJson)
        let pendingResult = try TaskResult(pendingContent)
        if case .pending = pendingResult {
            // Test passes - correct case parsed
        } else {
            #expect(Bool(false), "Expected pending case")
        }
        
        // Test labeled associated value initialization (single labeled parameter)
        let successJson = """
        {"case": "success", "value": {"message": "Operation completed"}}
        """
        let successContent = GeneratedContent(successJson)
        let successResult = try TaskResult(successContent)
        if case .success(let message) = successResult {
            #expect(message == "Operation completed")
        } else {
            #expect(Bool(false), "Expected success case")
        }
        
        // Test multiple associated values initialization
        let failureJson = """
        {"case": "failure", "value": {"error": "Network error", "code": "500"}}
        """
        let failureContent = GeneratedContent(failureJson)
        let failureResult = try TaskResult(failureContent)
        if case .failure(let error, let code) = failureResult {
            #expect(error == "Network error")
            #expect(code == 500)
        } else {
            #expect(Bool(false), "Expected failure case")
        }
    }
    
    // TODO: Add test for truly unlabeled single associated value
    // Currently causes compiler crash - needs investigation
    // @Test("@Generable macro works with truly unlabeled single associated value")
    // func generableMacroEnumWithUnlabeledSingleValue() throws { ... }
    
    @Test("@Generable macro generates init from GeneratedContent for simple enum")
    func generableMacroEnumInitFromGeneratedContentSimple() throws {
        @Generable
        enum Color: Equatable {
            case red
            case green
            case blue
        }
        
        // Test initialization from GeneratedContent
        let redContent = GeneratedContent("red")
        let redColor = try Color(redContent)
        #expect(redColor == .red)
        
        let blueContent = GeneratedContent("blue")
        let blueColor = try Color(blueContent)
        #expect(blueColor == .blue)
        
        // Test invalid case
        let invalidContent = GeneratedContent("yellow")
        #expect(throws: Error.self) {
            _ = try Color(invalidContent)
        }
    }
}