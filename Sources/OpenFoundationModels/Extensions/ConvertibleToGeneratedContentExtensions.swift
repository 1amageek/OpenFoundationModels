// ConvertibleToGeneratedContentExtensions.swift
// OpenFoundationModels  
//
// ✅ APPLE OFFICIAL: Extensions for ConvertibleToGeneratedContent protocol

import Foundation
import OpenFoundationModelsCore

// MARK: - ConvertibleToGeneratedContent Default Implementations

extension ConvertibleToGeneratedContent {
    /// An instance that represents the instructions.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An instance that represents the instructions.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent/instructionsrepresentation
    /// 
    /// **Apple Official API:** `var instructionsRepresentation: Instructions`
    public var instructionsRepresentation: Instructions {
        return Instructions(self.generatedContent.stringValue)
    }
    
    /// An instance that represents a prompt.
    /// 
    /// **Apple Foundation Models Documentation:**
    /// An instance that represents a prompt.
    /// 
    /// **Source:** https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent/promptrepresentation
    /// 
    /// **Apple Official API:** `var promptRepresentation: Prompt`
    public var promptRepresentation: Prompt {
        return Prompt(self.generatedContent.stringValue)
    }
}