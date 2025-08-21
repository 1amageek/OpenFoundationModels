import XCTest
@testable import OpenFoundationModelsCore
import OpenFoundationModels

final class ArraySchemaTests: XCTestCase {
    
    func testSimpleArraySchema() throws {
        // Test [String] generates correct JSON Schema
        let schema = [String].generationSchema
        let jsonSchema = schema.toSchemaDictionary()
        
        XCTAssertEqual(jsonSchema["type"] as? String, "array")
        XCTAssertNotNil(jsonSchema["items"] as? [String: Any])
        
        let items = jsonSchema["items"] as? [String: Any]
        XCTAssertEqual(items?["type"] as? String, "string")
    }
    
    func testIntArraySchema() throws {
        // Test [Int] generates correct JSON Schema
        let schema = [Int].generationSchema
        let jsonSchema = schema.toSchemaDictionary()
        
        XCTAssertEqual(jsonSchema["type"] as? String, "array")
        XCTAssertNotNil(jsonSchema["items"] as? [String: Any])
        
        let items = jsonSchema["items"] as? [String: Any]
        XCTAssertEqual(items?["type"] as? String, "integer")
    }
    
    func testNestedArraySchema() throws {
        // Test [[String]] generates correct JSON Schema
        let schema = [[String]].generationSchema
        let jsonSchema = schema.toSchemaDictionary()
        
        XCTAssertEqual(jsonSchema["type"] as? String, "array")
        XCTAssertNotNil(jsonSchema["items"] as? [String: Any])
        
        let items = jsonSchema["items"] as? [String: Any]
        XCTAssertEqual(items?["type"] as? String, "array")
        
        let nestedItems = items?["items"] as? [String: Any]
        XCTAssertEqual(nestedItems?["type"] as? String, "string")
    }
    
    func testTodoListSchema() throws {
        // Define test types
        struct TodoItem: Generable {
            var id: GenerationID
            var title: String
            var completed: Bool
            
            static var generationSchema: GenerationSchema {
                GenerationSchema(
                    type: TodoItem.self,
                    description: "Todo item",
                    properties: [
                        GenerationSchema.Property(name: "id", type: GenerationID.self),
                        GenerationSchema.Property(name: "title", type: String.self),
                        GenerationSchema.Property(name: "completed", type: Bool.self)
                    ]
                )
            }
            
            init(_ content: GeneratedContent) throws {
                let props = try content.properties()
                self.id = try props["id"]?.value(GenerationID.self) ?? GenerationID()
                self.title = try props["title"]?.value(String.self) ?? ""
                self.completed = try props["completed"]?.value(Bool.self) ?? false
            }
            
            var generatedContent: GeneratedContent {
                GeneratedContent(kind: .structure(
                    properties: [
                        "id": id.generatedContent,
                        "title": title.generatedContent,
                        "completed": completed.generatedContent
                    ],
                    orderedKeys: ["id", "title", "completed"]
                ))
            }
            
            init(id: GenerationID, title: String, completed: Bool) {
                self.id = id
                self.title = title
                self.completed = completed
            }
        }
        
        struct TodoList: Generable {
            var todos: [TodoItem]
            
            static var generationSchema: GenerationSchema {
                GenerationSchema(
                    type: TodoList.self,
                    description: "Todo list",
                    properties: [
                        GenerationSchema.Property(name: "todos", type: [TodoItem].self)
                    ]
                )
            }
            
            init(_ content: GeneratedContent) throws {
                let props = try content.properties()
                self.todos = try props["todos"]?.value([TodoItem].self) ?? []
            }
            
            var generatedContent: GeneratedContent {
                GeneratedContent(kind: .structure(
                    properties: [
                        "todos": todos.generatedContent
                    ],
                    orderedKeys: ["todos"]
                ))
            }
            
            init(todos: [TodoItem]) {
                self.todos = todos
            }
        }
        
        // Test TodoList schema
        let schema = TodoList.generationSchema
        let jsonSchema = schema.toSchemaDictionary()
        
        // TodoList should be an object
        XCTAssertEqual(jsonSchema["type"] as? String, "object")
        
        // Check properties
        let properties = jsonSchema["properties"] as? [String: Any]
        XCTAssertNotNil(properties)
        
        // todos property should be an array
        let todosSchema = properties?["todos"] as? [String: Any]
        XCTAssertEqual(todosSchema?["type"] as? String, "array")
        
        // items should be TodoItem schema
        let itemsSchema = todosSchema?["items"] as? [String: Any]
        XCTAssertEqual(itemsSchema?["type"] as? String, "object")
        
        // TodoItem should have properties
        let itemProperties = itemsSchema?["properties"] as? [String: Any]
        XCTAssertNotNil(itemProperties)
        XCTAssertNotNil(itemProperties?["id"])
        XCTAssertNotNil(itemProperties?["title"])
        XCTAssertNotNil(itemProperties?["completed"])
    }
    
    func testArraySchemaEncodingToJSON() throws {
        // Test that array schema encodes correctly to JSON
        let schema = [String].generationSchema
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(schema)
        _ = String(data: jsonData, encoding: .utf8)!  // Computed but not used in test
        
        // Parse JSON to verify structure
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        XCTAssertEqual(json["type"] as? String, "array")
        XCTAssertNotNil(json["items"])
    }
}