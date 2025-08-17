
import Foundation


public protocol PartiallyGeneratedProtocol: ConvertibleFromGeneratedContent {
    var isComplete: Bool { get }
}
