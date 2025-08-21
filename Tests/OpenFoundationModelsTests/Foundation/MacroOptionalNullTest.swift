import Testing
import Foundation
@testable import OpenFoundationModels

@Generable
struct SimpleOptionalTest {
    var optionalInt: Int?
}

@Suite("Macro Optional Null Handling")
struct MacroOptionalNullTest {
    
    @Test("Macro-generated init handles null for optional Int")
    func macroGeneratedInitHandlesNull() throws {
        // This is the failing case - null value for optional Int
        let nullJSON = """
        {
            "optionalInt": null
        }
        """
        
        let content = try GeneratedContent(json: nullJSON)
        
        // Check that content has null for optionalInt
        let props = try content.properties()
        let optionalIntContent = props["optionalInt"]
        
        switch optionalIntContent?.kind {
        case .null:
            #expect(true)
        default:
            Issue.record("Expected null kind")
        }
        
        // This is where it fails - the macro-generated init
        // doesn't properly handle null for optional Int
        let result = try SimpleOptionalTest(content)
        #expect(result.optionalInt == nil)
    }
    
    @Test("Empty object {} cannot convert to Int")
    func emptyObjectCannotConvertToInt() throws {
        let emptyObjectJSON = """
        {
            "optionalInt": {}
        }
        """
        
        let content = try GeneratedContent(json: emptyObjectJSON)
        
        // This should throw because {} cannot convert to Int
        #expect(throws: (any Error).self) {
            _ = try SimpleOptionalTest(content)
        }
    }
}