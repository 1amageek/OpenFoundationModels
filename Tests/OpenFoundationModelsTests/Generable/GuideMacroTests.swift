import Testing
@testable import OpenFoundationModels



@Generable
struct TestGuidePerson {
    @Guide(description: "The person's full name")
    let name: String
    
    @Guide(description: "Age in years")  
    let age: Int
}

@Generable
struct TestGuideUser {
    @Guide(description: "Username with letters and numbers only", .pattern(/[a-zA-Z0-9]+/))
    let username: String
}

@Suite("Guide Macro Tests", .tags(.guide, .macros))
struct GuideMacroTests {
    
    @Test("@Guide macro compiles without errors")
    func guideMacroCompilation() throws {
        let content = try GeneratedContent(json: "{\"name\": \"John\", \"age\": 30}")
        let person = try TestGuidePerson(content)
        
        let generated = person.generatedContent
        #expect(generated.text != "")
        
        let schema = TestGuidePerson.generationSchema
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
    
    @Test("@Guide macro with pattern constraint compiles")
    func guideMacroWithPattern() {
        let schema = TestGuideUser.generationSchema
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
}