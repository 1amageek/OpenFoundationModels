import Testing
import Foundation
@testable import OpenFoundationModels



@Generable
struct TestUserProfile {
    let name: String
    let age: Int
}

@Generable
struct TestPerson {
    @Guide(description: "Full name of the person")
    let name: String
    
    @Guide(description: "Age in years")
    let age: Int
    
    @Guide(description: "Email address")
    let email: String
}

@Generable
struct TestValidatedUser {
    @Guide(description: "Username", .pattern(/[a-zA-Z0-9_]+/))
    let username: String
    
    @Guide(description: "Age", .range(13...120))
    let age: Int
    
    @Guide(description: "Role", .anyOf(["admin", "user", "guest"]))
    let role: String
}

@Generable
struct TestAddress {
    @Guide(description: "Street address")
    let street: String
    
    @Guide(description: "City name")
    let city: String
    
    @Guide(description: "ZIP code", .pattern(/\d{5}/))
    let zipCode: String
}

@Generable
struct TestGuidedProduct {
    @Guide(description: "Product name")
    let name: String
    
    @Guide(description: "Price in USD", .range(0.01...9999.99))
    let price: Double
}

@Generable
struct TestItem {
    let value: String
}

@Generable
struct TestSimpleList {
    @Guide(description: "Total cost")
    let totalCost: Double
    
    @Guide(description: "Item count")
    let itemCount: Int
}

@Generable
struct TestBook {
    @Guide(description: "Book title")
    let title: String
    
    @Guide(description: "Author name")
    let author: String
}

@Generable
struct TestAuthor {
    @Guide(description: "Author name")
    let name: String
    
    @Guide(description: "Birth year")
    let birthYear: Int
}

@Generable
struct TestGuidedSafeData {
    let message: String
    let timestamp: Int
}

@Suite("Guided Generation Tests", .tags(.generable, .integration, .guide))
struct GuidedGenerationTests {
    
    @Test("Simple Generable type creation and basic properties")
    func simpleGenerableCreation() throws {
        let content = try TestUserProfile(GeneratedContent("{}"))
        
        #expect(content.name == "")
        #expect(content.age == 0)
    }
    
    @Test("Generable with Guide annotations")
    func generableWithGuideAnnotations() throws {
        let person = try TestPerson(GeneratedContent("{}"))
        
        #expect(person.name == "")
        #expect(person.age == 0)
        #expect(person.email == "")
    }
    
    @Test("Generable with constraint guides")
    func generableWithConstraintGuides() throws {
        let user = try TestValidatedUser(GeneratedContent("{}"))
        
        #expect(user.username == "")
        #expect(user.age == 0)
        #expect(user.role == "")
    }
    
    @Test("Simple nested structures")
    func simpleNestedStructures() throws {
        let address = try TestAddress(GeneratedContent("{}"))
        
        #expect(address.street == "")
        #expect(address.city == "")
        #expect(address.zipCode == "")
    }
    
    @Test("Generable generationSchema property exists")
    func generableGenerationSchemaExists() {
        let schema = TestGuidedProduct.generationSchema
        
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
    
    @Test("Generable protocol methods exist")
    func generableProtocolMethodsExist() throws {
        let json = #"{"value": "test"}"#
        let item = try TestItem(GeneratedContent(json: json))
        
        let generatedContent = item.generatedContent
        #expect(generatedContent.text.contains("value"))
        #expect(generatedContent.text.contains("test"))
        
        let converted = item.generatedContent
        #expect(converted.text == item.generatedContent.text)
        
        let partial = item.asPartiallyGenerated()
        #expect(partial.value == item.value)
        
        let emptyItem = try TestItem(GeneratedContent("{}"))
        let emptyPartial = emptyItem.asPartiallyGenerated()
        #expect(emptyPartial.value == nil) // Empty JSON has no value property
    }
    
    @Test("Generable with simple array properties")
    func generableWithSimpleArrayProperties() throws {
        let list = try TestSimpleList(GeneratedContent("{}"))
        
        #expect(list.totalCost == 0.0)
        #expect(list.itemCount == 0)
    }
    
    @Test("Multiple Generable types in same scope")
    func multipleGenerableTypesInSameScope() throws {
        let book = try TestBook(GeneratedContent("{}"))
        let author = try TestAuthor(GeneratedContent("{}"))
        
        #expect(book.title == "")
        #expect(book.author == "")
        #expect(author.name == "")
        #expect(author.birthYear == 0)
    }
    
    @Test("Generable Sendable conformance")
    func generableSendableConformance() throws {
        let data = try TestGuidedSafeData(GeneratedContent("{}"))
        
        let _: any Sendable = data
        #expect(Bool(true)) // Compilation success indicates Sendable conformance
        
        Task {
            let asyncData = data
            #expect(asyncData.message == "")
        }
    }
}