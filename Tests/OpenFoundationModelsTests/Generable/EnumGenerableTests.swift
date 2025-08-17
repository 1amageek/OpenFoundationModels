
import XCTest
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore
import OpenFoundationModelsMacros

final class EnumGenerableTests: XCTestCase {
    
    @Generable
    enum TaskDifficulty: String, CaseIterable, Sendable {
        case trivial = "trivial"
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        case expert = "expert"
    }
    
    @Generable
    enum DependencyAction: String, Sendable {
        case add = "add"
        case remove = "remove"
    }
    
    func testSimpleEnumGeneration() throws {
        let schema = TaskDifficulty.generationSchema
        XCTAssertNotNil(schema)
        
        let content = GeneratedContent(kind: .string("easy"))
        let difficulty = try TaskDifficulty(content)
        XCTAssertEqual(difficulty, .easy)
    }
    
    func testEnumGenerationSchema() throws {
        let schema = DependencyAction.generationSchema
        XCTAssertNotNil(schema)
        
        let content = GeneratedContent(kind: .string("add"))
        let action = try DependencyAction(content)
        XCTAssertEqual(action, .add)
    }
    
    func testEnumGeneratedContent() throws {
        let easy = TaskDifficulty.easy
        let content = easy.generatedContent
        XCTAssertEqual(content.kind, .string("easy"))
    }
    
    func testEnumPartiallyGenerated() throws {
        let hard = TaskDifficulty.hard
        let partial = hard.asPartiallyGenerated()
        XCTAssertEqual(partial, hard)
    }
    
    func testEnumInstructionsRepresentation() throws {
        let expert = TaskDifficulty.expert
        let instructions = expert.instructionsRepresentation
        XCTAssertNotNil(instructions)
    }
    
    func testEnumPromptRepresentation() throws {
        let remove = DependencyAction.remove
        let prompt = remove.promptRepresentation
        XCTAssertNotNil(prompt)
    }
}