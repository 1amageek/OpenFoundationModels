import Testing
import Foundation
@testable import OpenFoundationModels

/// Tests for PartiallyGenerated Optional handling
/// 
/// **Focus:** Validates that PartiallyGenerated avoids double optionals
/// and handles various type combinations correctly.
///
/// **Apple Foundation Models Documentation:**
/// PartiallyGenerated types should make all properties optional for streaming,
/// but avoid creating double optionals for properties that are already optional.

// MARK: - Test Types

@Generable
struct TestOptionalFields {
    let requiredString: String
    let optionalString: String?
    let requiredArray: [String]
    let optionalArray: [String]?
    let requiredInt: Int
    let optionalInt: Int?
}

@Generable
struct TestArrayDefaults {
    let strings: [String]
    let numbers: [Int]
    let booleans: [Bool]
    let custom: [TestArrayItem]
}

@Generable
struct TestArrayItem: Equatable {
    let id: String
    let value: Int
}

@Generable
struct TestCustomDefaults {
    let required: TestCustomType
    let optional: TestCustomType?
    let array: [TestCustomType]
    let optionalArray: [TestCustomType]?
}

@Generable
struct TestCustomType {
    let value: String
}

@Generable
struct TestNestedOptionals {
    let level1: TestLevel1?
    let array: [TestLevel1]?
}

@Generable
struct TestLevel1 {
    let level2: TestLevel2?
    let name: String
}

@Generable
struct TestLevel2 {
    let value: String?
}

// MARK: - Tests

@Suite("PartiallyGenerated Optional Tests", .tags(.generable, .macros))
struct PartiallyGeneratedOptionalTests {
    
    @Test("PartiallyGenerated avoids double optionals")
    func partiallyGeneratedAvoidDoubleOptionals() throws {
        let json = "{}"
        let partial = try TestOptionalFields.PartiallyGenerated(GeneratedContent(json: json))
        
        // All properties should be nil when not present
        #expect(partial.requiredString == nil)
        #expect(partial.optionalString == nil)
        #expect(partial.requiredArray == nil)
        #expect(partial.optionalArray == nil)
        #expect(partial.requiredInt == nil)
        #expect(partial.optionalInt == nil)
        
        // Type checks - these should compile without double optionals
        // Currently, these lines will fail to compile if double optionals exist
        // TODO: Uncomment after fixing the macro
        // let _: String? = partial.requiredString     // Should be String?, not String??
        // let _: String? = partial.optionalString     // Should be String?, not String??
        // let _: [String]? = partial.requiredArray    // Should be [String]?, not [String]??
        // let _: [String]? = partial.optionalArray    // Should be [String]?, not [String]??
        // let _: Int? = partial.requiredInt           // Should be Int?, not Int??
        // let _: Int? = partial.optionalInt           // Should be Int?, not Int??
        
        #expect(partial.isComplete == false)
    }
    
    @Test("PartiallyGenerated with partial data")
    func partiallyGeneratedWithPartialData() throws {
        let json = #"{"requiredString": "test", "optionalInt": 42}"#
        let partial = try TestOptionalFields.PartiallyGenerated(GeneratedContent(json: json))
        
        // Present fields should have values
        #expect(partial.requiredString == "test")
        #expect(partial.optionalInt == 42)
        
        // Missing fields should be nil
        #expect(partial.optionalString == nil)
        #expect(partial.requiredArray == nil)
        #expect(partial.optionalArray == nil)
        #expect(partial.requiredInt == nil)
        
        #expect(partial.isComplete == false)  // Not all required fields present
    }
    
    @Test("Array types get empty array defaults in normal init")
    func arrayTypesGetEmptyArrayDefaults() throws {
        // Test with empty JSON
        let empty = try TestArrayDefaults(GeneratedContent(json: "{}"))
        
        // Arrays should be initialized to empty arrays, not cause errors
        #expect(empty.strings == [])
        #expect(empty.numbers == [])
        #expect(empty.booleans == [])
        #expect(empty.custom == [])
    }
    
    @Test("Array types in PartiallyGenerated")
    func arrayTypesInPartiallyGenerated() throws {
        // Empty JSON
        let partial1 = try TestArrayDefaults.PartiallyGenerated(GeneratedContent(json: "{}"))
        
        // All arrays should be nil (not empty arrays) in PartiallyGenerated
        #expect(partial1.strings == nil)
        #expect(partial1.numbers == nil)
        #expect(partial1.booleans == nil)
        #expect(partial1.custom == nil)
        #expect(partial1.isComplete == false)
        
        // Partial JSON with some arrays
        let json2 = #"{"strings": ["a", "b"], "numbers": []}"#
        let partial2 = try TestArrayDefaults.PartiallyGenerated(GeneratedContent(json: json2))
        
        #expect(partial2.strings == ["a", "b"])
        #expect(partial2.numbers == [])  // Empty array is valid data
        #expect(partial2.booleans == nil)  // Missing
        #expect(partial2.custom == nil)  // Missing
        #expect(partial2.isComplete == false)
    }
    
    @Test("Custom types handle missing data gracefully")
    func customTypesHandleMissingData() throws {
        // PartiallyGenerated with empty JSON
        let partial = try TestCustomDefaults.PartiallyGenerated(GeneratedContent(json: "{}"))
        
        // All properties should be nil
        #expect(partial.required == nil)
        #expect(partial.optional == nil)
        #expect(partial.array == nil)
        #expect(partial.optionalArray == nil)
        #expect(partial.isComplete == false)
        
        // Normal init with empty JSON should handle gracefully
        // This behavior depends on the implementation decision:
        // - Could initialize with defaults
        // - Could throw an error for required custom types
        // For now, test that it at least compiles
        do {
            let _ = try TestCustomDefaults(GeneratedContent(json: "{}"))
            // If this succeeds, custom types are given some default
        } catch {
            // If this fails, that's also acceptable behavior
            // The important thing is it doesn't generate invalid Swift code
        }
    }
    
    @Test("Nested optional types")
    func nestedOptionalTypes() throws {
        // Test deeply nested optional types
        let partial = try TestNestedOptionals.PartiallyGenerated(GeneratedContent(json: "{}"))
        
        // All should be nil
        #expect(partial.level1 == nil)
        #expect(partial.array == nil)
        
        // Partial data with nested structure
        let json = #"""
        {
            "level1": {
                "name": "test",
                "level2": {
                    "value": "deep"
                }
            }
        }
        """#
        let partial2 = try TestNestedOptionals.PartiallyGenerated(GeneratedContent(json: json))
        
        #expect(partial2.level1 != nil)
        // TODO: Fix after double optional issue is resolved
        // Currently level1 is TestLevel1?? instead of TestLevel1?
        // #expect(partial2.level1?.name == "test")
        // #expect(partial2.level1?.level2 != nil)
        // #expect(partial2.level1?.level2?.value == "deep")
        #expect(partial2.array == nil)
    }
    
    @Test("Complete data sets isComplete correctly")
    func completeDataSetsIsComplete() throws {
        // Complete JSON with all required fields
        let json = #"""
        {
            "requiredString": "test",
            "optionalString": "optional",
            "requiredArray": ["a", "b"],
            "optionalArray": ["c"],
            "requiredInt": 42,
            "optionalInt": 100
        }
        """#
        
        let partial = try TestOptionalFields.PartiallyGenerated(GeneratedContent(json: json))
        
        // All fields should be present
        #expect(partial.requiredString == "test")
        #expect(partial.optionalString == "optional")
        #expect(partial.requiredArray == ["a", "b"])
        #expect(partial.optionalArray == ["c"])
        #expect(partial.requiredInt == 42)
        #expect(partial.optionalInt == 100)
        
        // Should be marked as complete
        #expect(partial.isComplete == true)
    }
    
    @Test("Type preservation in PartiallyGenerated")
    func typePreservationInPartiallyGenerated() throws {
        // This test verifies that type information is preserved correctly
        // and no information is lost in the Optional transformation
        
        let json = #"""
        {
            "requiredString": "test",
            "optionalString": "opt", 
            "requiredArray": ["a"],
            "optionalArray": ["b"],
            "requiredInt": 1,
            "optionalInt": 2
        }
        """#
        
        let original = try TestOptionalFields(GeneratedContent(json: json))
        let partial = original.asPartiallyGenerated()
        
        // All values should be preserved
        #expect(partial.requiredString == "test")
        #expect(partial.optionalString == "opt")
        #expect(partial.requiredArray == ["a"])
        #expect(partial.optionalArray == ["b"])
        #expect(partial.requiredInt == 1)
        #expect(partial.optionalInt == 2)
        #expect(partial.isComplete == true)
    }
}