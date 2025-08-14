import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore

/// Tests for standard types Generable conformance
/// 
/// **Focus:** Validates that UUID, Date, URL, and Data types correctly conform to Generable
/// and can be used in structured generation workflows
///
/// **Reference:** Extended standard type support for practical LLM tool development

// MARK: - Tests

@Suite("Standard Types Generable Conformance")
struct StandardTypesTests {
    
    // MARK: - UUID Tests
    
    @Test("UUID Generable conformance")
    func testUUIDGenerable() throws {
        let uuid = UUID()
        let content = uuid.generatedContent
        
        // Verify UUID is stored as string
        guard case .string(let uuidString) = content.kind else {
            #expect(Bool(false), "UUID should be stored as string")
            return
        }
        
        #expect(uuidString == uuid.uuidString)
        
        // Test round-trip
        let reconstructed = try UUID(content)
        #expect(reconstructed == uuid)
    }
    
    @Test("UUID parsing from various formats")
    func testUUIDParsing() throws {
        // Standard format
        let validUUID = "550e8400-e29b-41d4-a716-446655440000"
        let content1 = GeneratedContent(kind: .string(validUUID))
        let uuid1 = try UUID(content1)
        #expect(uuid1.uuidString.lowercased() == validUUID.lowercased())
        
        // Uppercase format
        let upperUUID = "550E8400-E29B-41D4-A716-446655440000"
        let content2 = GeneratedContent(kind: .string(upperUUID))
        let uuid2 = try UUID(content2)
        #expect(uuid2.uuidString.uppercased() == upperUUID)
        
        // Invalid format should throw
        let invalidUUID = "not-a-uuid"
        let content3 = GeneratedContent(kind: .string(invalidUUID))
        #expect(throws: DecodingError.self) {
            _ = try UUID(content3)
        }
    }
    
    // MARK: - Date Tests
    
    @Test("Date Generable conformance")
    func testDateGenerable() throws {
        let date = Date()
        let content = date.generatedContent
        
        // Verify Date is stored as ISO8601 string
        guard case .string(let dateString) = content.kind else {
            #expect(Bool(false), "Date should be stored as string")
            return
        }
        
        // Check for ISO8601 format markers
        #expect(dateString.contains("T"))
        #expect(dateString.contains("Z") || dateString.contains("+"))
        
        // Test round-trip (allowing for small precision loss)
        let reconstructed = try Date(content)
        let timeDifference = abs(reconstructed.timeIntervalSince(date))
        #expect(timeDifference < 0.001) // Within 1 millisecond
    }
    
    @Test("Date parsing from various formats")
    func testDateParsing() throws {
        // ISO8601 with fractional seconds
        let iso1 = "2024-01-15T10:30:45.123Z"
        let content1 = GeneratedContent(kind: .string(iso1))
        let date1 = try Date(content1)
        #expect(date1.timeIntervalSince1970 > 0)
        
        // ISO8601 without fractional seconds
        let iso2 = "2024-01-15T10:30:45Z"
        let content2 = GeneratedContent(kind: .string(iso2))
        let date2 = try Date(content2)
        #expect(date2.timeIntervalSince1970 > 0)
        
        // Unix timestamp
        let timestamp = "1705315845"
        let content3 = GeneratedContent(kind: .string(timestamp))
        let date3 = try Date(content3)
        #expect(date3.timeIntervalSince1970 == 1705315845)
        
        // Invalid format should throw
        let invalid = "not-a-date"
        let content4 = GeneratedContent(kind: .string(invalid))
        #expect(throws: DecodingError.self) {
            _ = try Date(content4)
        }
    }
    
    // MARK: - URL Tests
    
    @Test("URL Generable conformance")
    func testURLGenerable() throws {
        let url = URL(string: "https://example.com/path?query=value#fragment")!
        let content = url.generatedContent
        
        // Verify URL is stored as string
        guard case .string(let urlString) = content.kind else {
            #expect(Bool(false), "URL should be stored as string")
            return
        }
        
        #expect(urlString == url.absoluteString)
        
        // Test round-trip
        let reconstructed = try URL(content)
        #expect(reconstructed == url)
    }
    
    @Test("URL parsing various formats")
    func testURLParsing() throws {
        // HTTP URL
        let httpURL = "http://example.com"
        let content1 = GeneratedContent(kind: .string(httpURL))
        let url1 = try URL(content1)
        #expect(url1.absoluteString == httpURL)
        
        // HTTPS URL with path
        let httpsURL = "https://api.example.com/v1/users"
        let content2 = GeneratedContent(kind: .string(httpsURL))
        let url2 = try URL(content2)
        #expect(url2.absoluteString == httpsURL)
        
        // File URL
        let fileURL = "file:///Users/test/document.pdf"
        let content3 = GeneratedContent(kind: .string(fileURL))
        let url3 = try URL(content3)
        #expect(url3.absoluteString == fileURL)
        
        // Invalid URL should throw
        let invalidURL = ""  // Empty string is invalid URL
        let content4 = GeneratedContent(kind: .string(invalidURL))
        #expect(throws: DecodingError.self) {
            _ = try URL(content4)
        }
    }
    
    // MARK: - Schema Tests
    
    @Test("Generation schema for standard types")
    func testGenerationSchemaForStandardTypes() {
        // UUID schema
        let uuidSchema = UUID.generationSchema
        #expect(uuidSchema.description?.contains("UUID") == true)
        
        // Date schema
        let dateSchema = Date.generationSchema
        #expect(dateSchema.description?.contains("ISO") == true)
        
        // URL schema
        let urlSchema = URL.generationSchema
        #expect(urlSchema.description?.contains("URL") == true)
    }
    
    // MARK: - Integration Tests
    
    @Test("Standard types in GeneratedContent structure")
    func testStandardTypesInStructure() throws {
        // Create a structure with all standard types
        let content = GeneratedContent(
            kind: .structure(
                properties: [
                    "id": UUID().generatedContent,
                    "created": Date().generatedContent,
                    "url": URL(string: "https://example.com")!.generatedContent,
                    "optional": GeneratedContent(kind: .null)
                ],
                orderedKeys: ["id", "created", "url", "optional"]
            )
        )
        
        guard case .structure(let props, let keys) = content.kind else {
            #expect(Bool(false), "Expected structure")
            return
        }
        
        // Verify all properties are present and have correct types
        #expect(keys.count == 4)
        
        if let idContent = props["id"] {
            guard case .string(_) = idContent.kind else {
                #expect(Bool(false), "ID should be string")
                return
            }
        }
        
        if let createdContent = props["created"] {
            guard case .string(_) = createdContent.kind else {
                #expect(Bool(false), "Created should be string")
                return
            }
        }
        
        if let urlContent = props["url"] {
            guard case .string(_) = urlContent.kind else {
                #expect(Bool(false), "URL should be string")
                return
            }
        }
        
        if let dataContent = props["data"] {
            guard case .string(_) = dataContent.kind else {
                #expect(Bool(false), "Data should be string")
                return
            }
        }
        
        if let optionalContent = props["optional"] {
            guard case .null = optionalContent.kind else {
                #expect(Bool(false), "Optional should be null")
                return
            }
        }
    }
}
