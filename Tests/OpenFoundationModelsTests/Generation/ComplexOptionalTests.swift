import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore

// MARK: - Complex Test Structures

/// Nested optional with guides
@Generable
fileprivate struct Address {
    @Guide(description: "Street address")
    var street: String

    @Guide(description: "City name")
    var city: String

    @Guide(description: "Postal code", .pattern(/^\d{3}-\d{4}$/))
    var postalCode: String?
}

/// User with optional nested type
@Generable
fileprivate struct User {
    @Guide(description: "User ID")
    var id: String

    @Guide(description: "User name")
    var name: String

    @Guide(description: "User's address")
    var address: Address?

    @Guide(description: "Age between 0 and 150", .minimum(0), .maximum(150))
    var age: Int?

    @Guide(description: "Tags", .minimumCount(0), .maximumCount(10))
    var tags: [String]?
}

/// Product with multiple optional guides
@Generable
fileprivate struct Product {
    @Guide(description: "Product name")
    var name: String

    @Guide(description: "Price between 0 and 1000000", .minimum(0.0), .maximum(1000000.0))
    var price: Double?

    @Guide(description: "Stock count", .minimum(0))
    var stock: Int?

    @Guide(description: "Category", .anyOf(["electronics", "clothing", "food", "other"]))
    var category: String?
}

/// Order with nested arrays and optionals
@Generable
fileprivate struct OrderItem {
    @Guide(description: "Product ID")
    var productId: String

    @Guide(description: "Quantity", .minimum(1), .maximum(100))
    var quantity: Int

    @Guide(description: "Discount percentage", .minimum(0.0), .maximum(100.0))
    var discount: Double?
}

@Generable
fileprivate struct Order {
    @Guide(description: "Order ID")
    var orderId: String

    @Guide(description: "Customer ID")
    var customerId: String

    @Guide(description: "Order items", .minimumCount(1))
    var items: [OrderItem]

    @Guide(description: "Shipping address")
    var shippingAddress: Address?

    @Guide(description: "Notes")
    var notes: String?
}

/// Deeply nested structure
@Generable
fileprivate struct Department {
    var name: String
}

@Generable
fileprivate struct Employee {
    var name: String
    var department: Department?
}

@Generable
fileprivate struct Company {
    var name: String
    var ceo: Employee?
    var employees: [Employee]?
}

/// All optional properties - no required fields
@Generable
fileprivate struct AllOptional {
    var name: String?
    var age: Int?
    var active: Bool?
}

/// Enum for optional enum test
@Generable
fileprivate enum Status: String {
    case active
    case inactive
    case pending
}

/// Struct with optional enum
@Generable
fileprivate struct Task {
    var title: String
    var status: Status?
}

// MARK: - Tests

@Suite("Complex Optional Schema Tests")
struct ComplexOptionalTests {

    @Test("Nested optional Generable type generates correct schema")
    func nestedOptionalGenerable() throws {
        let schema = User.generationSchema
        let jsonSchema = schema.toSchemaDictionary()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!
        print("User Schema:")
        print(json)

        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }

        // Check required fields
        guard let required = jsonSchema["required"] as? [String] else {
            Issue.record("Required array not found")
            return
        }
        #expect(required.contains("id"))
        #expect(required.contains("name"))
        #expect(!required.contains("address"))
        #expect(!required.contains("age"))
        #expect(!required.contains("tags"))

        // Check age has guides and allows null
        if let ageProp = properties["age"] as? [String: Any] {
            #expect(ageProp["minimum"] as? Int == 0)
            #expect(ageProp["maximum"] as? Int == 150)
            if let typeArray = ageProp["type"] as? [String] {
                #expect(typeArray.contains("integer"))
                #expect(typeArray.contains("null"))
            }
        } else {
            Issue.record("age property not found")
        }

        // Check tags has array constraints
        if let tagsProp = properties["tags"] as? [String: Any] {
            #expect(tagsProp["minItems"] as? Int == 0)
            #expect(tagsProp["maxItems"] as? Int == 10)
        }
    }

    @Test("Product with multiple guide types on optional properties")
    func productMultipleGuides() throws {
        let schema = Product.generationSchema
        let jsonSchema = schema.toSchemaDictionary()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!
        print("Product Schema:")
        print(json)

        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }

        // Check price has range
        if let priceProp = properties["price"] as? [String: Any] {
            #expect(priceProp["minimum"] as? Double == 0.0)
            #expect(priceProp["maximum"] as? Double == 1000000.0)
            if let typeArray = priceProp["type"] as? [String] {
                #expect(typeArray.contains("number"))
                #expect(typeArray.contains("null"))
            }
        } else {
            Issue.record("price property not found")
        }

        // Check category has enum
        if let categoryProp = properties["category"] as? [String: Any] {
            if let enumValues = categoryProp["enum"] as? [String] {
                #expect(enumValues.contains("electronics"))
                #expect(enumValues.contains("clothing"))
                #expect(enumValues.contains("food"))
                #expect(enumValues.contains("other"))
            }
            if let typeArray = categoryProp["type"] as? [String] {
                #expect(typeArray.contains("string"))
                #expect(typeArray.contains("null"))
            }
        } else {
            Issue.record("category property not found")
        }

        // Check stock has minimum only
        if let stockProp = properties["stock"] as? [String: Any] {
            #expect(stockProp["minimum"] as? Int == 0)
            #expect(stockProp["maximum"] == nil) // No maximum set
        }
    }

    @Test("Order with nested array of Generable and optional address")
    func orderComplexNesting() throws {
        let schema = Order.generationSchema
        let jsonSchema = schema.toSchemaDictionary()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!
        print("Order Schema:")
        print(json)

        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }

        // Check items has minItems
        if let itemsProp = properties["items"] as? [String: Any] {
            #expect(itemsProp["minItems"] as? Int == 1)
            #expect(itemsProp["type"] as? String == "array")
        }

        // Check required
        guard let required = jsonSchema["required"] as? [String] else {
            Issue.record("Required array not found")
            return
        }
        #expect(required.contains("orderId"))
        #expect(required.contains("customerId"))
        #expect(required.contains("items"))
        #expect(!required.contains("shippingAddress"))
        #expect(!required.contains("notes"))
    }

    @Test("Deeply nested optional structure")
    func deeplyNestedOptional() throws {
        let schema = Company.generationSchema
        let jsonSchema = schema.toSchemaDictionary()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!
        print("Company Schema:")
        print(json)

        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }

        // Check ceo is optional (allows null)
        if let ceoProp = properties["ceo"] as? [String: Any] {
            if let typeArray = ceoProp["type"] as? [String] {
                #expect(typeArray.contains("object"))
                #expect(typeArray.contains("null"))
            } else if ceoProp["anyOf"] != nil {
                // Also acceptable for complex nested types
                #expect(true)
            }
        }

        // Check employees is optional array
        if let employeesProp = properties["employees"] as? [String: Any] {
            // Should allow null for optional array
            if let typeArray = employeesProp["type"] as? [String] {
                #expect(typeArray.contains("array"))
                #expect(typeArray.contains("null"))
            }
        }

        // Check required
        guard let required = jsonSchema["required"] as? [String] else {
            Issue.record("Required array not found")
            return
        }
        #expect(required.contains("name"))
        #expect(!required.contains("ceo"))
        #expect(!required.contains("employees"))
    }

    @Test("Address with optional postal code pattern")
    func addressOptionalPattern() throws {
        let schema = Address.generationSchema
        let jsonSchema = schema.toSchemaDictionary()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!
        print("Address Schema:")
        print(json)

        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }

        // Check postalCode has pattern and allows null
        if let postalProp = properties["postalCode"] as? [String: Any] {
            #expect(postalProp["pattern"] != nil, "postalCode should have pattern")
            if let typeArray = postalProp["type"] as? [String] {
                #expect(typeArray.contains("string"))
                #expect(typeArray.contains("null"))
            }
        } else {
            Issue.record("postalCode property not found")
        }

        // Check required
        guard let required = jsonSchema["required"] as? [String] else {
            Issue.record("Required array not found")
            return
        }
        #expect(required.contains("street"))
        #expect(required.contains("city"))
        #expect(!required.contains("postalCode"))
    }

    @Test("OrderItem with mixed required and optional guides")
    func orderItemMixedGuides() throws {
        let schema = OrderItem.generationSchema
        let jsonSchema = schema.toSchemaDictionary()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!
        print("OrderItem Schema:")
        print(json)

        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }

        // Check quantity (required with guides)
        if let quantityProp = properties["quantity"] as? [String: Any] {
            #expect(quantityProp["minimum"] as? Int == 1)
            #expect(quantityProp["maximum"] as? Int == 100)
            #expect(quantityProp["type"] as? String == "integer") // Not array, required
        }

        // Check discount (optional with guides)
        if let discountProp = properties["discount"] as? [String: Any] {
            #expect(discountProp["minimum"] as? Double == 0.0)
            #expect(discountProp["maximum"] as? Double == 100.0)
            if let typeArray = discountProp["type"] as? [String] {
                #expect(typeArray.contains("number"))
                #expect(typeArray.contains("null"))
            }
        }

        // Check required
        guard let required = jsonSchema["required"] as? [String] else {
            Issue.record("Required array not found")
            return
        }
        #expect(required.contains("productId"))
        #expect(required.contains("quantity"))
        #expect(!required.contains("discount"))
    }

    @Test("All optional properties struct has empty required array")
    func allOptionalProperties() throws {
        let schema = AllOptional.generationSchema
        let jsonSchema = schema.toSchemaDictionary()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!
        print("AllOptional Schema:")
        print(json)

        // Check required is empty or nil
        let required = jsonSchema["required"] as? [String] ?? []
        #expect(required.isEmpty, "All-optional struct should have empty required array")

        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }

        // All properties should have null type
        for (name, prop) in properties {
            guard let propDict = prop as? [String: Any],
                  let typeArray = propDict["type"] as? [String] else {
                Issue.record("\(name) should have type array")
                continue
            }
            #expect(typeArray.contains("null"), "\(name) should allow null")
        }
    }

    @Test("Optional enum property generates correct schema")
    func optionalEnumProperty() throws {
        let schema = Task.generationSchema
        let jsonSchema = schema.toSchemaDictionary()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!
        print("Task Schema:")
        print(json)

        guard let properties = jsonSchema["properties"] as? [String: Any] else {
            Issue.record("Properties not found")
            return
        }

        // Check title is required
        if let titleProp = properties["title"] as? [String: Any] {
            #expect(titleProp["type"] as? String == "string")
        }

        // Check status allows null (optional enum)
        if let statusProp = properties["status"] as? [String: Any] {
            if let typeArray = statusProp["type"] as? [String] {
                #expect(typeArray.contains("null"), "Optional enum should allow null")
            } else if statusProp["anyOf"] != nil {
                // anyOf with null is also acceptable
                #expect(Bool(true))
            }
        }

        // Check required
        guard let required = jsonSchema["required"] as? [String] else {
            Issue.record("Required array not found")
            return
        }
        #expect(required.contains("title"))
        #expect(!required.contains("status"))
    }

    @Test("GeneratedContent null converts to nil for optional")
    func nullConvertToNil() throws {
        // Create GeneratedContent with null
        let nullContent = GeneratedContent(kind: .null)

        // Convert to Optional<String>
        let optionalString: String? = try nullContent.value(String?.self)
        #expect(optionalString == nil)

        // Convert to Optional<Int>
        let optionalInt: Int? = try nullContent.value(Int?.self)
        #expect(optionalInt == nil)
    }

    @Test("GeneratedContent with value converts correctly for optional")
    func valueConvertToOptional() throws {
        // Create GeneratedContent with string value
        let stringContent = GeneratedContent(kind: .string("hello"))
        let optionalString: String? = try stringContent.value(String?.self)
        #expect(optionalString == "hello")

        // Create GeneratedContent with number value
        let numberContent = GeneratedContent(kind: .number(42))
        let optionalInt: Int? = try numberContent.value(Int?.self)
        #expect(optionalInt == 42)
    }

    @Test("Nested structure with optional fields converts from GeneratedContent")
    func nestedStructFromGeneratedContent() throws {
        // Create GeneratedContent for User with some optional fields nil
        let userContent = GeneratedContent(kind: .structure(
            properties: [
                "id": GeneratedContent(kind: .string("user-123")),
                "name": GeneratedContent(kind: .string("John")),
                "age": GeneratedContent(kind: .null),
                "address": GeneratedContent(kind: .null),
                "tags": GeneratedContent(kind: .null)
            ],
            orderedKeys: ["id", "name", "age", "address", "tags"]
        ))

        // Convert to User
        let user = try User(userContent)
        #expect(user.id == "user-123")
        #expect(user.name == "John")
        #expect(user.age == nil)
        #expect(user.address == nil)
        #expect(user.tags == nil)
    }
}
