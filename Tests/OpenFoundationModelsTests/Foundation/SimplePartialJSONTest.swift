// SimplePartialJSONTest.swift
// Minimal test case to debug the issue

import Foundation
import Testing
@testable import OpenFoundationModels

@Suite("Simple Partial JSON Test")
struct SimplePartialJSONTest {
    
    @Test("Single incomplete string value")
    func singleIncompleteStringValue() throws {
        let json = #"{"name": "Al"#
        print("Input JSON: \(json)")
        
        // Use the throwing JSON initializer
        let content: GeneratedContent
        do {
            content = try GeneratedContent(json: json)
        } catch {
            print("Error parsing JSON: \(error)")
            throw error
        }
        print("Content kind: \(content.kind)")
        print("Content isComplete: \(content.isComplete)")
        
        #expect(content.isComplete == false)
    }
}