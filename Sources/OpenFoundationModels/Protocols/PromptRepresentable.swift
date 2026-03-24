import Foundation

public protocol PromptRepresentable {
    @PromptBuilder var promptRepresentation: Prompt { get }
}