import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore

// Test structures defined at module level to avoid macro expansion issues
@Generable
fileprivate struct PersonProfile {
    var name: String
    var age: Int
    var occupation: String
    var hobbies: [String]?
    var contact: ContactInfo?
    
    @Generable
    struct ContactInfo {
        var email: String
        var phone: String?
    }
}

@Generable
fileprivate struct TestArrays {
    var strings: [String]?
    var numbers: [Int]?
    var booleans: [Bool]?
    var requiredArray: [String]
}

// Dictionary tests will be added later
// @Generable
// fileprivate struct TestDictionary {
//     var metadata: [String: Int]?
//     var config: [String: String]?
//     var requiredDict: [String: Bool]
// }

@Generable
fileprivate struct OuterNested {
    var inner: InnerNested?
    var requiredInner: InnerNested
    
    @Generable
    struct InnerNested {
        var value: String
        var nested: DeepNested?
        
        @Generable
        struct DeepNested {
            var id: Int
            var data: String?
        }
    }
}

@Suite("Complete JSON Schema Generation Tests", .tags(.schema, .unit))
struct CompleteJSONSchemaTests {
    
    @Test("PersonProfile generates complete JSON Schema with nested objects and arrays")
    func testPersonProfileCompleteSchema() throws {
        let schema = PersonProfile.generationSchema
        let json = schema.toSchemaDictionary()
        
        // Verify top-level structure
        #expect(json["type"] as? String == "object")
        #expect(json["properties"] != nil)
        
        guard let properties = json["properties"] as? [String: Any] else {
            Issue.record("Properties not found in schema")
            return
        }
        
        // Verify required fields
        if let required = json["required"] as? [String] {
            #expect(required.contains("name"))
            #expect(required.contains("age"))
            #expect(required.contains("occupation"))
            #expect(!required.contains("hobbies"))
            #expect(!required.contains("contact"))
        } else {
            Issue.record("Required array not found")
        }
        
        // Test primitive required fields
        #expect((properties["name"] as? [String: Any])?["type"] as? String == "string")
        #expect((properties["age"] as? [String: Any])?["type"] as? String == "integer")
        #expect((properties["occupation"] as? [String: Any])?["type"] as? String == "string")
        
        // Test hobbies: Optional array of strings
        if let hobbies = properties["hobbies"] as? [String: Any] {
            // Type should be ["array", "null"]
            if let typeArray = hobbies["type"] as? [String] {
                #expect(typeArray.contains("array"))
                #expect(typeArray.contains("null"))
                #expect(typeArray.count == 2)
            } else {
                Issue.record("hobbies type should be an array [\"array\", \"null\"]")
            }
            
            // Items should define element type
            if let items = hobbies["items"] as? [String: Any] {
                #expect(items["type"] as? String == "string")
            } else {
                Issue.record("hobbies should have items field defining element type")
            }
        } else {
            Issue.record("hobbies property not found")
        }
        
        // Test contact: Optional nested object
        if let contact = properties["contact"] as? [String: Any] {
            // Type should be ["object", "null"]
            if let typeArray = contact["type"] as? [String] {
                #expect(typeArray.contains("object"))
                #expect(typeArray.contains("null"))
                #expect(typeArray.count == 2)
            } else {
                Issue.record("contact type should be an array [\"object\", \"null\"]")
            }
            
            // Properties should be preserved
            if let contactProps = contact["properties"] as? [String: Any] {
                // email: required string
                #expect((contactProps["email"] as? [String: Any])?["type"] as? String == "string")
                
                // phone: optional string
                if let phone = contactProps["phone"] as? [String: Any] {
                    if let phoneType = phone["type"] as? [String] {
                        #expect(phoneType.contains("string"))
                        #expect(phoneType.contains("null"))
                    }
                }
                
                // Check required fields in nested object
                if let contactRequired = contact["required"] as? [String] {
                    #expect(contactRequired.contains("email"))
                    #expect(!contactRequired.contains("phone"))
                }
            } else {
                Issue.record("contact should have properties field with nested structure")
            }
        } else {
            Issue.record("contact property not found")
        }
    }
    
    @Test("Optional arrays generate correct JSON Schema with items field")
    func testOptionalArrays() throws {
        let schema = TestArrays.generationSchema
        let json = schema.toSchemaDictionary()
        
        guard let properties = json["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }
        
        // Test optional string array
        if let strings = properties["strings"] as? [String: Any] {
            if let type = strings["type"] as? [String] {
                #expect(type.contains("array"))
                #expect(type.contains("null"))
            }
            #expect((strings["items"] as? [String: Any])?["type"] as? String == "string")
        } else {
            Issue.record("strings property not found")
        }
        
        // Test optional integer array
        if let numbers = properties["numbers"] as? [String: Any] {
            if let type = numbers["type"] as? [String] {
                #expect(type.contains("array"))
                #expect(type.contains("null"))
            }
            #expect((numbers["items"] as? [String: Any])?["type"] as? String == "integer")
        } else {
            Issue.record("numbers property not found")
        }
        
        // Test optional boolean array
        if let booleans = properties["booleans"] as? [String: Any] {
            if let type = booleans["type"] as? [String] {
                #expect(type.contains("array"))
                #expect(type.contains("null"))
            }
            #expect((booleans["items"] as? [String: Any])?["type"] as? String == "boolean")
        } else {
            Issue.record("booleans property not found")
        }
        
        // Test required array (should not have null)
        if let requiredArray = properties["requiredArray"] as? [String: Any] {
            #expect(requiredArray["type"] as? String == "array")
            #expect((requiredArray["items"] as? [String: Any])?["type"] as? String == "string")
        } else {
            Issue.record("requiredArray property not found")
        }
        
        // Check required fields
        if let required = json["required"] as? [String] {
            #expect(required.contains("requiredArray"))
            #expect(!required.contains("strings"))
            #expect(!required.contains("numbers"))
            #expect(!required.contains("booleans"))
        }
    }
    
    // Dictionary test will be added later after fixing Dictionary+Generable
    
    @Test("Deeply nested optional objects preserve complete structure")
    func testNestedOptionalObjects() throws {
        let schema = OuterNested.generationSchema
        let json = schema.toSchemaDictionary()
        
        guard let properties = json["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }
        
        // Test optional inner object
        if let inner = properties["inner"] as? [String: Any] {
            // Type should be ["object", "null"]
            if let type = inner["type"] as? [String] {
                #expect(type.contains("object"))
                #expect(type.contains("null"))
            }
            
            // Inner properties should be preserved
            if let innerProps = inner["properties"] as? [String: Any] {
                // value: required string
                #expect((innerProps["value"] as? [String: Any])?["type"] as? String == "string")
                
                // nested: optional DeepNested object
                if let nested = innerProps["nested"] as? [String: Any] {
                    // Type should be ["object", "null"]
                    if let nestedType = nested["type"] as? [String] {
                        #expect(nestedType.contains("object"))
                        #expect(nestedType.contains("null"))
                    }
                    
                    // DeepNested properties should be preserved
                    if let deepProps = nested["properties"] as? [String: Any] {
                        #expect((deepProps["id"] as? [String: Any])?["type"] as? String == "integer")
                        
                        // data: optional string
                        if let data = deepProps["data"] as? [String: Any] {
                            if let dataType = data["type"] as? [String] {
                                #expect(dataType.contains("string"))
                                #expect(dataType.contains("null"))
                            }
                        }
                    } else {
                        Issue.record("DeepNested properties not preserved")
                    }
                } else {
                    Issue.record("nested property not found in InnerNested")
                }
                
                // Check required fields in InnerNested
                if let innerRequired = inner["required"] as? [String] {
                    #expect(innerRequired.contains("value"))
                    #expect(!innerRequired.contains("nested"))
                }
            } else {
                Issue.record("inner should have properties field")
            }
        } else {
            Issue.record("inner property not found")
        }
        
        // Test required inner object (should not have null in type)
        if let requiredInner = properties["requiredInner"] as? [String: Any] {
            #expect(requiredInner["type"] as? String == "object")
            #expect(requiredInner["properties"] != nil)
        }
        
        // Check top-level required fields
        if let required = json["required"] as? [String] {
            #expect(required.contains("requiredInner"))
            #expect(!required.contains("inner"))
        }
    }
}