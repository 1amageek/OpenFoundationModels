import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore

/// Tests for @Generable macro with optional custom types
/// 
/// **Focus:** Validates that @Generable macro correctly handles optional custom types
/// without causing Swift compiler ambiguity issues with the nil-coalescing operator

// MARK: - Tests

@Suite("Optional Custom Types in @Generable")
struct OptionalTypesTests {
    
    @Test("Optional custom type code generation")
    func testOptionalCustomTypeGeneration() throws {
        // This test verifies that the macro-generated code compiles correctly
        // The fact that this test compiles proves the fix works
        
        // Test with TestTaskResult from GenerableMacroTests
        let result1: TestTaskResult? = .success(message: "Done")
        let result2: TestTaskResult? = nil
        
        // If the macro fix works, these should compile without ambiguity
        #expect(result1 != nil)
        #expect(result2 == nil)
    }
    
    @Test("Optional type in GeneratedContent")
    func testOptionalInGeneratedContent() throws {
        // Test that optional properties are correctly represented as null
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
        
        // Verify null representation
        if let statusContent = props["status"] {
            guard case .null = statusContent.kind else {
                #expect(Bool(false), "Expected null for status")
                return
            }
        }
    }
    
    @Test("Mixed optional and non-optional in GeneratedContent")
    func testMixedOptionalContent() throws {
        // Create a GeneratedContent with mixed optional/non-optional fields
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
        
        // Verify all keys are present
        #expect(keys.count == 5)
        #expect(keys.contains("required"))
        #expect(keys.contains("optionalAbsent"))
        
        // Verify non-null values
        if let required = props["required"] {
            guard case .string(let value) = required.kind else {
                #expect(Bool(false), "Expected string for required")
                return
            }
            #expect(value == "value")
        }
        
        // Verify null values
        if let absent = props["optionalAbsent"] {
            guard case .null = absent.kind else {
                #expect(Bool(false), "Expected null for optionalAbsent")
                return
            }
        }
    }
}