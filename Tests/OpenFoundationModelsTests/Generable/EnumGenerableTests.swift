// EnumGenerableTests.swift
// OpenFoundationModelsTests

import XCTest
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore
import OpenFoundationModelsMacros

/// Tests for @Generable macro with enums
final class EnumGenerableTests: XCTestCase {
    
    // Test simple enum with @Generable
    @Generable
    enum TaskDifficulty: String, CaseIterable, Sendable {
        case trivial = "trivial"
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        case expert = "expert"
    }
    
    // Test enum with @Generable
    @Generable
    enum DependencyAction: String, Sendable {
        case add = "add"
        case remove = "remove"
    }
    
    func testSimpleEnumGeneration() throws {
        // Test that generation schema is created
        let schema = TaskDifficulty.generationSchema
        XCTAssertNotNil(schema)
        
        // Test that enum can be initialized from GeneratedContent
        let content = GeneratedContent(kind: .string("easy"))
        let difficulty = try TaskDifficulty(content)
        XCTAssertEqual(difficulty, .easy)
    }
    
    func testEnumGenerationSchema() throws {
        // Test that generation schema is created
        let schema = DependencyAction.generationSchema
        XCTAssertNotNil(schema)
        
        // Test that enum can be initialized from GeneratedContent
        let content = GeneratedContent(kind: .string("add"))
        let action = try DependencyAction(content)
        XCTAssertEqual(action, .add)
    }
    
    func testEnumGeneratedContent() throws {
        // Test that enum can convert to GeneratedContent
        let easy = TaskDifficulty.easy
        let content = easy.generatedContent
        XCTAssertEqual(content.kind, .string("easy"))
    }
    
    func testEnumPartiallyGenerated() throws {
        // Test that enum can be partially generated
        let hard = TaskDifficulty.hard
        let partial = hard.asPartiallyGenerated()
        XCTAssertEqual(partial, hard)
    }
    
    func testEnumInstructionsRepresentation() throws {
        // Test that enum conforms to InstructionsRepresentable
        let expert = TaskDifficulty.expert
        let instructions = expert.instructionsRepresentation
        XCTAssertNotNil(instructions)
    }
    
    func testEnumPromptRepresentation() throws {
        // Test that enum conforms to PromptRepresentable
        let remove = DependencyAction.remove
        let prompt = remove.promptRepresentation
        XCTAssertNotNil(prompt)
    }
}