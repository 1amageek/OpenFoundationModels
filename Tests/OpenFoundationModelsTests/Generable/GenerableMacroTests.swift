import Testing
@testable import OpenFoundationModels



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
        let content = try GeneratedContent(json: "{\"value\": \"test\"}")
        let instance = try TestSimpleStruct(content)
        
        let generated = instance.generatedContent
        #expect(generated.text.contains("test") || generated.text.contains("{}"))
        
        let schema = TestSimpleStruct.generationSchema
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
    
    @Test("@Generable macro generates required members")
    func generableMacroGeneratesMembers() {
        let schema = TestGenerablePerson.generationSchema
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
        
    }
    
    @Test("@Generable macro works with simple enum")
    func generableMacroSimpleEnum() throws {
        let activeFromContent = try TestGenerableStatus(GeneratedContent("active"))
        #expect(activeFromContent == .active)
        
        let schema = TestGenerableStatus.generationSchema
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
        
        let activeStatus = TestGenerableStatus.active
        let content = activeStatus.generatedContent
        #expect(content.text == "active")
        
        let statusFromContent = try TestGenerableStatus(GeneratedContent("pending"))
        #expect(statusFromContent == .pending)
    }
    
    @Test("@Generable macro works with enum with associated values")
    func generableMacroEnumWithAssociatedValues() throws {
        let pending = TestTaskResult.pending
        let content = pending.generatedContent
        #expect(content.text != "")  // Should have content
        
        let schema = TestTaskResult.generationSchema
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
        
        let pendingResult = TestTaskResult.pending
        let pendingContent = pendingResult.generatedContent
        let pendingProps = try pendingContent.properties()
        #expect(pendingProps["case"]?.text == "pending")
        
        let successResult = TestTaskResult.success(message: "Operation completed")
        let successContent = successResult.generatedContent
        let successProps = try successContent.properties()
        #expect(successProps["case"]?.text == "success")
        
        let valueProps = try successProps["value"]?.properties()
        #expect(valueProps?["message"]?.text == "Operation completed")
        
        let failureResult = TestTaskResult.failure(error: "Network error", code: 500)
        let failureContent = failureResult.generatedContent
        let failureProps = try failureContent.properties()
        #expect(failureProps["case"]?.text == "failure")
        let failureValueProps = try failureProps["value"]?.properties()
        #expect(failureValueProps?["error"]?.text == "Network error")
        #expect(failureValueProps?["code"]?.text == "500")
    }
    
    @Test("@Generable macro generates init from GeneratedContent for enum with associated values")
    func generableMacroEnumInitFromGeneratedContent() throws {
        let pendingJson = """
        {"case": "pending", "value": ""}
        """
        let pendingContent = try GeneratedContent(json: pendingJson)
        let pendingResult = try TestTaskResultInit(pendingContent)
        if case .pending = pendingResult {
        } else {
            #expect(Bool(false), "Expected pending case")
        }
        
        let successJson = """
        {"case": "success", "value": {"message": "Operation completed"}}
        """
        let successContent = try GeneratedContent(json: successJson)
        let successResult = try TestTaskResultInit(successContent)
        if case .success(let message) = successResult {
            #expect(message == "Operation completed")
        } else {
            #expect(Bool(false), "Expected success case")
        }
        
        let failureJson = """
        {"case": "failure", "value": {"error": "Network error", "code": "500"}}
        """
        let failureContent = try GeneratedContent(json: failureJson)
        let failureResult = try TestTaskResultInit(failureContent)
        if case .failure(let error, let code) = failureResult {
            #expect(error == "Network error")
            #expect(code == 500)
        } else {
            #expect(Bool(false), "Expected failure case")
        }
    }
    
    
    @Test("@Generable macro generates init from GeneratedContent for simple enum")
    func generableMacroEnumInitFromGeneratedContentSimple() throws {
        let redContent = GeneratedContent("red")
        let redColor = try TestColor(redContent)
        #expect(redColor == .red)
        
        let blueContent = GeneratedContent("blue")
        let blueColor = try TestColor(blueContent)
        #expect(blueColor == .blue)
        
        let invalidContent = GeneratedContent("yellow")
        #expect(throws: Error.self) {
            _ = try TestColor(invalidContent)
        }
    }
}