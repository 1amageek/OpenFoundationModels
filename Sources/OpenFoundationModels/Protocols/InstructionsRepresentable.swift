import Foundation

public protocol InstructionsRepresentable {
    @InstructionsBuilder var instructionsRepresentation: Instructions { get }
}