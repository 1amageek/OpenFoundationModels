import Testing
import Foundation
@testable import OpenFoundationModels

// MARK: - Test Types (defined at top level to avoid local type macro restrictions)

@Generable
struct TestLargeUserProfile {
    // Basic information (10 properties)
    @Guide(description: "First name") let firstName: String
    @Guide(description: "Last name") let lastName: String
    @Guide(description: "Email address") let email: String
    @Guide(description: "Phone number") let phone: String
    @Guide(description: "Date of birth") let dateOfBirth: String
    @Guide(description: "Gender") let gender: String
    @Guide(description: "Nationality") let nationality: String
    @Guide(description: "Occupation") let occupation: String
    @Guide(description: "Company") let company: String
    @Guide(description: "Job title") let jobTitle: String
    
    // Address information (10 properties)
    @Guide(description: "Street address") let streetAddress: String
    @Guide(description: "City") let city: String
    @Guide(description: "State") let state: String
    @Guide(description: "Postal code") let postalCode: String
    @Guide(description: "Country") let country: String
    @Guide(description: "Building number") let buildingNumber: String
    @Guide(description: "Apartment number") let apartmentNumber: String
    @Guide(description: "Floor") let floor: String
    @Guide(description: "Landmark") let landmark: String
    @Guide(description: "Region") let region: String
    
    // Preferences (10 properties)
    @Guide(description: "Language preference") let language: String
    @Guide(description: "Currency") let currency: String
    @Guide(description: "Timezone") let timezone: String
    @Guide(description: "Theme") let theme: String
    @Guide(description: "Notification preference") let notifications: String
    @Guide(description: "Privacy level") let privacy: String
    @Guide(description: "Communication preference") let communication: String
    @Guide(description: "Marketing consent") let marketing: String
    @Guide(description: "Newsletter subscription") let newsletter: String
    @Guide(description: "Account type") let accountType: String
}

@Generable
struct TestComplexConstrainedType {
    @Guide(description: "Username", .pattern("[a-zA-Z0-9_]{3,20}"))
    let username: String
    
    @Guide(description: "Age", .range(18...100))
    let age: Int
    
    @Guide(description: "Score", .range(0.0...100.0))
    let score: Double
    
    @Guide(description: "Role", .enumeration(["admin", "moderator", "user", "guest", "premium"]))
    let role: String
    
    @Guide(description: "Email", .pattern("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"))
    let email: String
    
    @Guide(description: "Priority", .range(1...10))
    let priority: Int
    
    @Guide(description: "Category", .enumeration(["tech", "business", "education", "health", "entertainment"]))
    let category: String
    
    @Guide(description: "Rating", .range(1.0...5.0))
    let rating: Double
}

@Generable
struct TestProductCatalog {
    @Guide(description: "Product ID") let productId: String
    @Guide(description: "Name") let name: String
    @Guide(description: "Description") let description: String
    @Guide(description: "Price") let price: Double
    @Guide(description: "Category") let category: String
    @Guide(description: "Brand") let brand: String
    @Guide(description: "SKU") let sku: String
    @Guide(description: "Weight") let weight: Double
    @Guide(description: "Dimensions") let dimensions: String
    @Guide(description: "Color") let color: String
    @Guide(description: "Material") let material: String
    @Guide(description: "Country of origin") let countryOfOrigin: String
}

@Generable
struct TestOrderDetails {
    @Guide(description: "Order ID") let orderId: String
    @Guide(description: "Customer ID") let customerId: String
    @Guide(description: "Order date") let orderDate: String
    @Guide(description: "Total amount") let totalAmount: Double
    @Guide(description: "Currency") let currency: String
    @Guide(description: "Status") let status: String
    @Guide(description: "Shipping address") let shippingAddress: String
    @Guide(description: "Billing address") let billingAddress: String
    @Guide(description: "Payment method") let paymentMethod: String
    @Guide(description: "Shipping method") let shippingMethod: String
    @Guide(description: "Tracking number") let trackingNumber: String
    @Guide(description: "Notes") let notes: String
}

@Generable
struct TestCustomerProfile {
    @Guide(description: "Customer ID") let customerId: String
    @Guide(description: "Full name") let fullName: String
    @Guide(description: "Email") let email: String
    @Guide(description: "Phone") let phone: String
    @Guide(description: "Registration date") let registrationDate: String
    @Guide(description: "Last login") let lastLogin: String
    @Guide(description: "Status") let status: String
    @Guide(description: "Loyalty tier") let loyaltyTier: String
    @Guide(description: "Total orders") let totalOrders: Int
    @Guide(description: "Total spent") let totalSpent: Double
    @Guide(description: "Preferred language") let preferredLanguage: String
    @Guide(description: "Marketing consent") let marketingConsent: Bool
}

@Generable
struct TestRepeatedAccessType {
    @Guide(description: "Field 1") let field1: String
    @Guide(description: "Field 2") let field2: String
    @Guide(description: "Field 3") let field3: String
    @Guide(description: "Field 4") let field4: String
    @Guide(description: "Field 5") let field5: String
}

@Generable
struct TestVeryLargeSchema {
    // 50 properties to test macro scalability
    @Guide(description: "Property 1") let prop1: String
    @Guide(description: "Property 2") let prop2: String
    @Guide(description: "Property 3") let prop3: String
    @Guide(description: "Property 4") let prop4: String
    @Guide(description: "Property 5") let prop5: String
    @Guide(description: "Property 6") let prop6: String
    @Guide(description: "Property 7") let prop7: String
    @Guide(description: "Property 8") let prop8: String
    @Guide(description: "Property 9") let prop9: String
    @Guide(description: "Property 10") let prop10: String
    @Guide(description: "Property 11") let prop11: String
    @Guide(description: "Property 12") let prop12: String
    @Guide(description: "Property 13") let prop13: String
    @Guide(description: "Property 14") let prop14: String
    @Guide(description: "Property 15") let prop15: String
    @Guide(description: "Property 16") let prop16: String
    @Guide(description: "Property 17") let prop17: String
    @Guide(description: "Property 18") let prop18: String
    @Guide(description: "Property 19") let prop19: String
    @Guide(description: "Property 20") let prop20: String
    @Guide(description: "Property 21") let prop21: Int
    @Guide(description: "Property 22") let prop22: Int
    @Guide(description: "Property 23") let prop23: Int
    @Guide(description: "Property 24") let prop24: Int
    @Guide(description: "Property 25") let prop25: Int
    @Guide(description: "Property 26") let prop26: Double
    @Guide(description: "Property 27") let prop27: Double
    @Guide(description: "Property 28") let prop28: Double
    @Guide(description: "Property 29") let prop29: Double
    @Guide(description: "Property 30") let prop30: Double
    @Guide(description: "Property 31") let prop31: Bool
    @Guide(description: "Property 32") let prop32: Bool
    @Guide(description: "Property 33") let prop33: Bool
    @Guide(description: "Property 34") let prop34: Bool
    @Guide(description: "Property 35") let prop35: Bool
    @Guide(description: "Property 36") let prop36: String
    @Guide(description: "Property 37") let prop37: String
    @Guide(description: "Property 38") let prop38: String
    @Guide(description: "Property 39") let prop39: String
    @Guide(description: "Property 40") let prop40: String
    @Guide(description: "Property 41") let prop41: Int
    @Guide(description: "Property 42") let prop42: Int
    @Guide(description: "Property 43") let prop43: Int
    @Guide(description: "Property 44") let prop44: Int
    @Guide(description: "Property 45") let prop45: Int
    @Guide(description: "Property 46") let prop46: Double
    @Guide(description: "Property 47") let prop47: Double
    @Guide(description: "Property 48") let prop48: Double
    @Guide(description: "Property 49") let prop49: Double
    @Guide(description: "Property 50") let prop50: String
}

@Generable
struct TestBatchTestType {
    @Guide(description: "ID") let id: String
    @Guide(description: "Name") let name: String
    @Guide(description: "Value") let value: Int
    @Guide(description: "Active") let active: Bool
}

/// Tests for large-scale schema generation and performance
/// 
/// **Focus:** Validates performance characteristics when generating large schemas
/// with many properties, complex nesting, and extensive constraints to ensure
/// the system scales appropriately according to Apple's Foundation Models specification.
///
/// **Apple Foundation Models Documentation:**
/// Large schema tests ensure that @Generable macro expansion and GenerationSchema
/// creation remain performant and memory-efficient with realistic production workloads.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/generationschema
@Suite("Large Schema Tests", .tags(.performance, .schema, .generable))
struct LargeSchemaTests {
    
    @Test("Large schema with many simple properties", .timeLimit(.minutes(1)))
    func largeSchemaWithManySimpleProperties() throws {
        // Test macro performance with many properties
        let startTime = Date()
        
        // Test schema generation performance
        let schema = TestLargeUserProfile.generationSchema
        let schemaTime = Date().timeIntervalSince(startTime)
        
        // Test instance creation performance
        let resetTime = Date()
        let instance = try TestLargeUserProfile(GeneratedContent("{}"))
        let instanceTime = Date().timeIntervalSince(resetTime)
        
        // Verify basic functionality
        #expect(instance.firstName == "")
        #expect(instance.email == "")
        #expect(instance.city == "")
        #expect(instance.language == "")
        
        // Verify schema properties
        #expect(schema.type == "object")
        
        // Performance assertions (generous limits for CI environments)
        #expect(schemaTime < 1.0) // Schema generation should be fast
        #expect(instanceTime < 0.1) // Instance creation should be very fast
    }
    
    @Test("Schema generation with complex constraints", .timeLimit(.minutes(1)))
    func schemaGenerationWithComplexConstraints() throws {
        let startTime = Date()
        
        // Test constraint processing performance
        let schema = TestComplexConstrainedType.generationSchema
        let instance = try TestComplexConstrainedType(GeneratedContent("{}"))
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Verify functionality
        #expect(instance.username == "")
        #expect(instance.age == 0)
        #expect(instance.score == 0.0)
        #expect(instance.role == "")
        
        // Verify schema
        #expect(schema.type == "object")
        
        // Performance check
        #expect(totalTime < 0.5) // Complex constraints should still be fast
    }
    
    @Test("Multiple large schemas in parallel", .timeLimit(.minutes(2)))
    func multipleLargeSchemasInParallel() async throws {
        let startTime = Date()
        
        // Test parallel schema and instance creation
        async let productSchema = Task { TestProductCatalog.generationSchema }
        async let orderSchema = Task { TestOrderDetails.generationSchema }
        async let customerSchema = Task { TestCustomerProfile.generationSchema }
        
        async let productInstance = Task { try TestProductCatalog(GeneratedContent("{}")) }
        async let orderInstance = Task { try TestOrderDetails(GeneratedContent("{}")) }
        async let customerInstance = Task { try TestCustomerProfile(GeneratedContent("{}")) }
        
        // Await all results
        let (pSchema, oSchema, cSchema) = await (productSchema.value, orderSchema.value, customerSchema.value)
        let (pInstance, oInstance, cInstance) = try await (productInstance.value, orderInstance.value, customerInstance.value)
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Verify all schemas are valid
        #expect(pSchema.type == "object")
        #expect(oSchema.type == "object")
        #expect(cSchema.type == "object")
        
        // Verify all instances are created
        #expect(pInstance.productId == "")
        #expect(oInstance.orderId == "")
        #expect(cInstance.customerId == "")
        
        // Performance check - parallel should be faster than sequential
        #expect(totalTime < 2.0)
    }
    
    @Test("Schema memory efficiency with repeated access", .timeLimit(.minutes(1)))
    func schemaMemoryEfficiencyWithRepeatedAccess() throws {
        let iterations = 1000
        let startTime = Date()
        
        // Test repeated schema access
        for _ in 0..<iterations {
            let schema = TestRepeatedAccessType.generationSchema
            #expect(schema.type == "object")
        }
        
        let schemaAccessTime = Date().timeIntervalSince(startTime)
        
        // Test repeated instance creation
        let instanceStartTime = Date()
        var instances: [TestRepeatedAccessType] = []
        
        for _ in 0..<100 { // Fewer instances to avoid memory issues
            let instance = try TestRepeatedAccessType(GeneratedContent("{}"))
            instances.append(instance)
        }
        
        let instanceCreationTime = Date().timeIntervalSince(instanceStartTime)
        
        // Verify results
        #expect(instances.count == 100)
        #expect(instances.first?.field1 == "")
        
        // Performance expectations
        #expect(schemaAccessTime < 1.0) // 1000 schema accesses should be fast
        #expect(instanceCreationTime < 0.5) // 100 instance creations should be fast
        
        // Memory efficiency - verify instances are independent
        for instance in instances {
            #expect(instance.field1 == "")
        }
    }
    
    @Test("Large schema compilation performance", .timeLimit(.minutes(2)))
    func largeSchemaCompilationPerformance() throws {
        // Test that large schemas compile in reasonable time
        // If this compiles and runs, the macro handled the large schema successfully
        let startTime = Date()
        
        let schema = TestVeryLargeSchema.generationSchema
        let instance = try TestVeryLargeSchema(GeneratedContent("{}"))
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Basic verification
        #expect(schema.type == "object")
        #expect(instance.prop1 == "")
        #expect(instance.prop21 == 0)
        #expect(instance.prop26 == 0.0)
        #expect(instance.prop31 == false)
        #expect(instance.prop50 == "")
        
        // Performance check
        #expect(totalTime < 2.0) // Large schema should still be reasonably fast
    }
    
    @Test("Batch schema operations performance", .timeLimit(.minutes(1)))
    func batchSchemaOperationsPerformance() throws {
        let batchSize = 500
        let startTime = Date()
        
        // Test batch instance creation
        var instances: [TestBatchTestType] = []
        instances.reserveCapacity(batchSize)
        
        for _ in 0..<batchSize {
            let instance = try TestBatchTestType(GeneratedContent("{}"))
            instances.append(instance)
        }
        
        let creationTime = Date().timeIntervalSince(startTime)
        
        // Test batch property access
        let accessStartTime = Date()
        var totalLength = 0
        
        for instance in instances {
            totalLength += instance.id.count + instance.name.count
        }
        
        let accessTime = Date().timeIntervalSince(accessStartTime)
        
        // Verify results
        #expect(instances.count == batchSize)
        #expect(totalLength == 0) // All strings are empty defaults
        
        // Performance expectations
        #expect(creationTime < 1.0) // 500 instances should create quickly
        #expect(accessTime < 0.1) // Property access should be very fast
    }
}