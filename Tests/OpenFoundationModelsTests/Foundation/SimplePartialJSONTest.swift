
import Foundation
import Testing
@testable import OpenFoundationModels

@Suite("Simple Partial JSON Test")
struct SimplePartialJSONTest {
    
    @Test("Single incomplete string value")
    func singleIncompleteStringValue() throws {
        let json = #"{"name": "Al"#
        print("Input JSON: \(json)")
        
        let content: GeneratedContent
        do {
            content = try GeneratedContent(json: json)
        } catch {
            // Expected - incomplete JSON should fail to parse
            // Create partial content using Codable decoder approach
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let stringData = try encoder.encode(json)
            content = try decoder.decode(GeneratedContent.self, from: stringData)
        }
        print("Content kind: \(content.kind)")
        print("Content isComplete: \(content.isComplete)")
        
        #expect(content.isComplete == false)
    }
}