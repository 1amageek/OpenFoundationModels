import Foundation
import OpenFoundationModelsCore

extension ConvertibleToGeneratedContent {
    public var instructionsRepresentation: Instructions {
        return Instructions(self.generatedContent.text)
    }
    
    public var promptRepresentation: Prompt {
        return Prompt(self.generatedContent.text)
    }
}