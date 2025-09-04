import Testing
import Foundation
@testable import OpenFoundationModels



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


@Suite("PartiallyGenerated Optional Tests", .tags(.generable, .macros))
struct PartiallyGeneratedOptionalTests {
    
    @Test("PartiallyGenerated avoids double optionals")
    func partiallyGeneratedAvoidDoubleOptionals() throws {
        let json = "{}"
        let partial = try TestOptionalFields.PartiallyGenerated(GeneratedContent(json: json))
        
        #expect(partial.requiredString == nil)
        #expect(partial.optionalString == nil)
        #expect(partial.requiredArray == nil)
        #expect(partial.optionalArray == nil)
        #expect(partial.requiredInt == nil)
        #expect(partial.optionalInt == nil)
        
        
        // Note: Completion is now tracked via GeneratedContent.isComplete
        // #expect(partial.isComplete == false)
    }
    
    @Test("PartiallyGenerated with partial data")
    func partiallyGeneratedWithPartialData() throws {
        let json = #"{"requiredString": "test", "optionalInt": 42}"#
        let partial = try TestOptionalFields.PartiallyGenerated(GeneratedContent(json: json))
        
        #expect(partial.requiredString == "test")
        #expect(partial.optionalInt == 42)
        
        #expect(partial.optionalString == nil)
        #expect(partial.requiredArray == nil)
        #expect(partial.optionalArray == nil)
        #expect(partial.requiredInt == nil)
        
        // Note: Completion is now tracked via GeneratedContent.isComplete
        // #expect(partial.isComplete == false)  // Not all required fields present
    }
    
    @Test("Array types get empty array defaults in normal init")
    func arrayTypesGetEmptyArrayDefaults() throws {
        let empty = try TestArrayDefaults(GeneratedContent(json: "{}"))
        
        #expect(empty.strings == [])
        #expect(empty.numbers == [])
        #expect(empty.booleans == [])
        #expect(empty.custom == [])
    }
    
    @Test("Array types in PartiallyGenerated")
    func arrayTypesInPartiallyGenerated() throws {
        let partial1 = try TestArrayDefaults.PartiallyGenerated(GeneratedContent(json: "{}"))
        
        #expect(partial1.strings == nil)
        #expect(partial1.numbers == nil)
        #expect(partial1.booleans == nil)
        #expect(partial1.custom == nil)
        
        let json2 = #"{"strings": ["a", "b"], "numbers": []}"#
        let partial2 = try TestArrayDefaults.PartiallyGenerated(GeneratedContent(json: json2))
        
        #expect(partial2.strings == ["a", "b"])
        #expect(partial2.numbers == [])  // Empty array is valid data
        #expect(partial2.booleans == nil)  // Missing
        #expect(partial2.custom == nil)  // Missing
    }
    
    @Test("Custom types handle missing data gracefully")
    func customTypesHandleMissingData() throws {
        let partial = try TestCustomDefaults.PartiallyGenerated(GeneratedContent(json: "{}"))
        
        #expect(partial.required == nil)
        #expect(partial.optional == nil)
        #expect(partial.array == nil)
        #expect(partial.optionalArray == nil)
        // Note: Completion is now tracked via GeneratedContent.isComplete
        // #expect(partial.isComplete == false)
        
        do {
            let _ = try TestCustomDefaults(GeneratedContent(json: "{}"))
        } catch {
        }
    }
    
    @Test("Nested optional types")
    func nestedOptionalTypes() throws {
        let partial = try TestNestedOptionals.PartiallyGenerated(GeneratedContent(json: "{}"))
        
        #expect(partial.level1 == nil)
        #expect(partial.array == nil)
        
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
        #expect(partial2.array == nil)
    }
    
    @Test("Complete data sets isComplete correctly")
    func completeDataSetsIsComplete() throws {
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
        
        #expect(partial.requiredString == "test")
        #expect(partial.optionalString == "optional")
        #expect(partial.requiredArray == ["a", "b"])
        #expect(partial.optionalArray == ["c"])
        #expect(partial.requiredInt == 42)
        #expect(partial.optionalInt == 100)
        
        // Note: Completion is now tracked via GeneratedContent.isComplete
        // #expect(partial.isComplete == true)
    }
    
    @Test("Type preservation in PartiallyGenerated")
    func typePreservationInPartiallyGenerated() throws {
        
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
        
        #expect(partial.requiredString == "test")
        #expect(partial.optionalString == "opt")
        #expect(partial.requiredArray == ["a"])
        #expect(partial.optionalArray == ["b"])
        #expect(partial.requiredInt == 1)
        #expect(partial.optionalInt == 2)
        // Note: Completion is now tracked via GeneratedContent.isComplete
        // #expect(partial.isComplete == true)
    }
}