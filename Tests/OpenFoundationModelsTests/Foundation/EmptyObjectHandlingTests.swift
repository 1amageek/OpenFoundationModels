import Testing
import Foundation
@testable import OpenFoundationModels

@Generable
fileprivate struct TestArguments {
    var optionalString: String?
    var optionalInt: Int?
}

@Suite("Empty Object Handling Tests")
struct EmptyObjectHandlingTests {
    
    @Test("Empty object {} should be treated differently from null")
    func emptyObjectVsNull() throws {
        // Test empty object
        let emptyObjectJSON = "{}"
        let emptyObjectContent = try GeneratedContent(json: emptyObjectJSON)
        
        switch emptyObjectContent.kind {
        case .structure(let props, _):
            #expect(props.isEmpty)
        default:
            Issue.record("Expected structure for empty object")
        }
        
        // Test null
        let nullJSON = "null"
        let nullContent = try GeneratedContent(json: nullJSON)
        
        switch nullContent.kind {
        case .null:
            #expect(true)
        default:
            Issue.record("Expected null kind")
        }
        
        // They should not be equal
        #expect(emptyObjectContent != nullContent)
    }
    
    @Test("Tool arguments with empty object")
    func toolArgumentsEmptyObject() throws {
        // Simulate tool call with empty object arguments
        let toolCallJSON = """
        {
            "startedAfter": {},
            "startedBefore": {}
        }
        """
        
        let content = try GeneratedContent(json: toolCallJSON)
        
        // Check that empty objects are preserved as structure
        let props = try content.properties()
        
        let startedAfter = props["startedAfter"]
        #expect(startedAfter != nil)
        
        switch startedAfter?.kind {
        case .structure(let innerProps, _):
            #expect(innerProps.isEmpty)
        default:
            Issue.record("Expected empty structure for startedAfter")
        }
        
        let startedBefore = props["startedBefore"]
        #expect(startedBefore != nil)
        
        switch startedBefore?.kind {
        case .structure(let innerProps, _):
            #expect(innerProps.isEmpty)
        default:
            Issue.record("Expected empty structure for startedBefore")
        }
    }
    
    @Test("Optional Date tool argument handling")
    func optionalDateToolArgument() throws {
        // Test case 1: Properly formatted null values
        let properNullJSON = """
        {
            "startedAfter": null,
            "startedBefore": null
        }
        """
        
        let properContent = try GeneratedContent(json: properNullJSON)
        let properProps = try properContent.properties()
        
        // Null values should convert to nil for Optional<Date>
        let startedAfterNull = properProps["startedAfter"]
        switch startedAfterNull?.kind {
        case .null:
            #expect(true)
        default:
            Issue.record("Expected null for startedAfter")
        }
        
        // Test case 2: Empty objects (incorrect format)
        let incorrectEmptyJSON = """
        {
            "startedAfter": {},
            "startedBefore": {}
        }
        """
        
        let incorrectContent = try GeneratedContent(json: incorrectEmptyJSON)
        let incorrectProps = try incorrectContent.properties()
        
        // Empty objects cannot convert to Date
        let startedAfterEmpty = incorrectProps["startedAfter"]
        switch startedAfterEmpty?.kind {
        case .structure(let props, _):
            #expect(props.isEmpty)
            // This would fail to convert to Date
            #expect(throws: (any Error).self) {
                _ = try startedAfterEmpty?.value(Date.self)
            }
        default:
            Issue.record("Expected structure for empty object")
        }
    }
    
    @Test("Difference between {} and null in conversion")
    func conversionDifferences() throws {
        
        // Case 1: Proper null values
        let nullValuesJSON = """
        {
            "optionalString": null,
            "optionalInt": null
        }
        """
        
        let nullContent = try GeneratedContent(json: nullValuesJSON)
        let nullArgs = try TestArguments(nullContent)
        #expect(nullArgs.optionalString == nil)
        #expect(nullArgs.optionalInt == nil)
        
        // Case 2: Empty objects (should fail conversion)
        let emptyObjectsJSON = """
        {
            "optionalString": {},
            "optionalInt": {}
        }
        """
        
        let emptyContent = try GeneratedContent(json: emptyObjectsJSON)
        
        // This should throw an error because {} cannot convert to String or Int
        #expect(throws: (any Error).self) {
            _ = try TestArguments(emptyContent)
        }
    }
    
    @Test("Empty array [] vs empty object {}")
    func emptyArrayVsEmptyObject() throws {
        let emptyArrayJSON = "[]"
        let emptyArrayContent = try GeneratedContent(json: emptyArrayJSON)
        
        switch emptyArrayContent.kind {
        case .array(let elements):
            #expect(elements.isEmpty)
        default:
            Issue.record("Expected array")
        }
        
        let emptyObjectJSON = "{}"
        let emptyObjectContent = try GeneratedContent(json: emptyObjectJSON)
        
        switch emptyObjectContent.kind {
        case .structure(let props, _):
            #expect(props.isEmpty)
        default:
            Issue.record("Expected structure")
        }
        
        #expect(emptyArrayContent != emptyObjectContent)
    }
}