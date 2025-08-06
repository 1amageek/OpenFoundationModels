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

// MARK: - Test Types (moved from local scope to top level)

@Generable
struct TestSimpleStruct {
    let value: String
}

@Generable
struct TestGenerablePerson {
    let name: String
    let age: Int
}

@Generable(description: "User activity status")
enum TestGenerableStatus {
    case active
    case inactive
    case pending
}

@Generable(description: "Task result")
enum TestTaskResult {
    case success(message: String)
    case failure(error: String, code: Int)
    case pending
}

@Generable
enum TestTaskResultInit {
    case success(message: String)
    case failure(error: String, code: Int)
    case pending
}

@Generable
enum TestColor: Equatable {
    case red
    case green
    case blue
}

@Suite("Generable Macro Tests", .tags(.generable, .macros))
struct GenerableMacroTests {
    
    @Test("@Generable macro compiles without errors")
    func generableMacroCompilation() throws {
        // Test that the macro generates required functionality
        // Create instance from GeneratedContent to verify init(_:) was generated
        let content = GeneratedContent("{\"value\": \"test\"}")
        let instance = try TestSimpleStruct(content)
        
        // Verify generatedContent property was generated
        let generated = instance.generatedContent
        #expect(generated.text.contains("test") || generated.text.contains("{}"))
        
        // Verify generationSchema exists and is valid
        let schema = TestSimpleStruct.generationSchema
        // Schema type is internal, just verify schema was created
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
    
    @Test("@Generable macro generates required members")
    func generableMacroGeneratesMembers() {
        // Verify generationSchema property exists
        let schema = TestGenerablePerson.generationSchema
        // Schema type is internal, just verify schema was created
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
        
        // Test will pass if macro generates required members successfully
    }
    
    @Test("@Generable macro works with simple enum")
    func generableMacroSimpleEnum() throws {
        // Test that macro generates required functionality for enums
        // Create enum from GeneratedContent
        let activeFromContent = try TestGenerableStatus(GeneratedContent("active"))
        #expect(activeFromContent == .active)
        
        // Verify generationSchema property exists
        let schema = TestGenerableStatus.generationSchema
        // Schema type is internal, just verify schema was created
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
        // Note: anyOf is stored internally but not directly accessible in current implementation
        
        // Test enum case to GeneratedContent conversion
        let activeStatus = TestGenerableStatus.active
        let content = activeStatus.generatedContent
        #expect(content.stringValue == "active")
        
        // Test GeneratedContent to enum conversion
        let statusFromContent = try TestGenerableStatus(GeneratedContent("pending"))
        #expect(statusFromContent == .pending)
    }
    
    @Test("@Generable macro works with enum with associated values")
    func generableMacroEnumWithAssociatedValues() throws {
        // Test that macro generates functionality for enums with associated values
        // Create enum instance and convert to GeneratedContent
        let pending = TestTaskResult.pending
        let content = pending.generatedContent
        #expect(content.text != "")  // Should have content
        
        // Verify schema is object type for discriminated union
        let schema = TestTaskResult.generationSchema
        // Schema type is internal, just verify schema was created
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
        
        // Test simple case - no associated values
        let pendingResult = TestTaskResult.pending
        let pendingContent = pendingResult.generatedContent
        let pendingProps = try pendingContent.properties()
        #expect(pendingProps["case"]?.stringValue == "pending")
        
        // Test labeled associated value case (treated as multiple values)
        let successResult = TestTaskResult.success(message: "Operation completed")
        let successContent = successResult.generatedContent
        let successProps = try successContent.properties()
        #expect(successProps["case"]?.stringValue == "success")
        
        // For labeled parameters, value is an object with properties
        let valueProps = try successProps["value"]?.properties()
        #expect(valueProps?["message"]?.stringValue == "Operation completed")
        
        // Test multiple associated values case
        let failureResult = TestTaskResult.failure(error: "Network error", code: 500)
        let failureContent = failureResult.generatedContent
        let failureProps = try failureContent.properties()
        #expect(failureProps["case"]?.stringValue == "failure")
        let failureValueProps = try failureProps["value"]?.properties()
        #expect(failureValueProps?["error"]?.stringValue == "Network error")
        #expect(failureValueProps?["code"]?.stringValue == "500")
    }
    
    @Test("@Generable macro generates init from GeneratedContent for enum with associated values")
    func generableMacroEnumInitFromGeneratedContent() throws {
        // Test simple case initialization
        let pendingJson = """
        {"case": "pending", "value": ""}
        """
        let pendingContent = GeneratedContent(pendingJson)
        let pendingResult = try TestTaskResultInit(pendingContent)
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
        let successResult = try TestTaskResultInit(successContent)
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
        let failureResult = try TestTaskResultInit(failureContent)
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
        // Test initialization from GeneratedContent
        let redContent = GeneratedContent("red")
        let redColor = try TestColor(redContent)
        #expect(redColor == .red)
        
        let blueContent = GeneratedContent("blue")
        let blueColor = try TestColor(blueContent)
        #expect(blueColor == .blue)
        
        // Test invalid case
        let invalidContent = GeneratedContent("yellow")
        #expect(throws: Error.self) {
            _ = try TestColor(invalidContent)
        }
    }
}