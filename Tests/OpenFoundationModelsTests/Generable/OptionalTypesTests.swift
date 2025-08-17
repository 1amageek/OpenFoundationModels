import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore



@Suite("Optional Custom Types in @Generable")
struct OptionalTypesTests {
    
    @Test("Optional custom type code generation")
    func testOptionalCustomTypeGeneration() throws {
        
        let result1: TestTaskResult? = .success(message: "Done")
        let result2: TestTaskResult? = nil
        
        #expect(result1 != nil)
        #expect(result2 == nil)
    }
    
    @Test("Optional type in GeneratedContent")
    func testOptionalInGeneratedContent() throws {
        let content = GeneratedContent(
            kind: .structure(
                properties: [
                    "id": GeneratedContent(kind: .string(UUID().uuidString)),
                    "status": GeneratedContent(kind: .null),
                    "timestamp": GeneratedContent(kind: .null)
                ],
                orderedKeys: ["id", "status", "timestamp"]
            )
        )
        
        guard case .structure(let props, _) = content.kind else {
            #expect(Bool(false), "Expected structure")
            return
        }
        
        if let statusContent = props["status"] {
            guard case .null = statusContent.kind else {
                #expect(Bool(false), "Expected null for status")
                return
            }
        }
    }
    
    @Test("Mixed optional and non-optional in GeneratedContent")
    func testMixedOptionalContent() throws {
        let content = GeneratedContent(
            kind: .structure(
                properties: [
                    "required": GeneratedContent(kind: .string("value")),
                    "optionalPresent": GeneratedContent(kind: .string("present")),
                    "optionalAbsent": GeneratedContent(kind: .null),
                    "requiredNumber": GeneratedContent(kind: .number(42)),
                    "optionalNumber": GeneratedContent(kind: .null)
                ],
                orderedKeys: ["required", "optionalPresent", "optionalAbsent", "requiredNumber", "optionalNumber"]
            )
        )
        
        guard case .structure(let props, let keys) = content.kind else {
            #expect(Bool(false), "Expected structure")
            return
        }
        
        #expect(keys.count == 5)
        #expect(keys.contains("required"))
        #expect(keys.contains("optionalAbsent"))
        
        if let required = props["required"] {
            guard case .string(let value) = required.kind else {
                #expect(Bool(false), "Expected string for required")
                return
            }
            #expect(value == "value")
        }
        
        if let absent = props["optionalAbsent"] {
            guard case .null = absent.kind else {
                #expect(Bool(false), "Expected null for optionalAbsent")
                return
            }
        }
    }
}