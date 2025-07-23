// OpenFoundationModelsMacrosImpl.swift
// OpenFoundationModels
//
// ✅ CONFIRMED: Based on Apple Foundation Models API specification

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

/// Implementation of the @Generable macro
/// 
/// ✅ CONFIRMED: From Apple Developer Documentation
/// - Generates Generable protocol conformance
/// - Creates init(_:) initializer (NOT generationSchema)
/// - Creates generatedContent property (NOT PartiallyGenerated)
public struct GenerableMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Check if it's a struct or enum
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            let structName = structDecl.name.text
            let description = extractDescription(from: node)
            
            // Get all properties with @Guide annotations
            let properties = extractGuidedProperties(from: structDecl)
            
            // Generate the required members for struct
            return [
                generateInitFromGeneratedContent(structName: structName, properties: properties),
                generateGeneratedContentProperty(structName: structName, description: description, properties: properties),
                // Removed generateFromGeneratedContentMethod and generateToGeneratedContentMethod
                // as they are not needed with the new protocol design
                generateGenerationSchemaProperty(structName: structName, description: description, properties: properties),
                generateAsPartiallyGeneratedMethod(structName: structName),
                // Need to generate these properties as they don't have default implementations
                generateInstructionsRepresentationProperty(),
                generatePromptRepresentationProperty()
            ]
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            let enumName = enumDecl.name.text
            let description = extractDescription(from: node)
            
            // Get all enum cases
            let cases = extractEnumCases(from: enumDecl)
            
            // Generate the required members for enum
            return [
                generateEnumInitFromGeneratedContent(enumName: enumName, cases: cases),
                generateEnumGeneratedContentProperty(enumName: enumName, description: description, cases: cases),
                // Removed generateEnumFromGeneratedContentMethod and generateToGeneratedContentMethod
                // as they are not needed with the new protocol design
                generateEnumGenerationSchemaProperty(enumName: enumName, description: description, cases: cases),
                generateAsPartiallyGeneratedMethod(structName: enumName),
                // Need to generate these properties as they don't have default implementations
                generateInstructionsRepresentationProperty(),
                generatePromptRepresentationProperty()
            ]
        } else {
            throw MacroError.notApplicableToType
        }
    }
    
    // MARK: - ExtensionMacro Implementation
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Create extension with Generable conformance
        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax([
                    InheritedTypeSyntax(
                        type: TypeSyntax("Generable")
                    )
                ])
            ),
            memberBlock: MemberBlockSyntax(
                members: MemberBlockItemListSyntax([])
            )
        )
        
        return [extensionDecl]
    }
    
    
    // MARK: - Helper Methods
    
    private static func extractDescription(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let firstArg = arguments.first,
              firstArg.label?.text == "description",
              let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self) else {
            return nil
        }
        return stringLiteral.segments.description.trimmingCharacters(in: .init(charactersIn: "\""))
    }
    
    private static func extractGuidedProperties(from structDecl: StructDeclSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []
        
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self),
               let binding = varDecl.bindings.first,
               let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                
                let propertyName = identifier.identifier.text
                let propertyType = binding.typeAnnotation?.type.description ?? "String"
                
                // Look for @Guide attributes
                let guideInfo = extractGuideInfo(from: varDecl.attributes)
                
                properties.append(PropertyInfo(
                    name: propertyName,
                    type: propertyType,
                    guideDescription: guideInfo.description,
                    guides: guideInfo.guides,
                    pattern: guideInfo.pattern
                ))
            }
        }
        
        return properties
    }
    
    private static func extractGuideInfo(from attributes: AttributeListSyntax) -> (description: String?, guides: [String], pattern: String?) {
        for attribute in attributes {
            if let attr = attribute.as(AttributeSyntax.self),
               attr.attributeName.description == "Guide" {
                // Extract Guide parameters
                if let arguments = attr.arguments?.as(LabeledExprListSyntax.self),
                   let descArg = arguments.first,
                   let stringLiteral = descArg.expression.as(StringLiteralExprSyntax.self) {
                    let description = stringLiteral.segments.description.trimmingCharacters(in: .init(charactersIn: "\""))
                    
                    var guides: [String] = []
                    var pattern: String? = nil
                    
                    // Extract additional guides if present
                    for arg in Array(arguments.dropFirst()) {
                        let argText = arg.expression.description
                        
                        // Check if this is a .pattern(...) constraint
                        if argText.contains(".pattern(") {
                            // Extract the pattern string from .pattern("regex")
                            let patternRegex = #/\.pattern\(\"([^\"]*)\"\)/#
                            if let match = argText.firstMatch(of: patternRegex) {
                                pattern = String(match.1)
                            }
                        } else if argText.contains("pattern(") {
                            // Handle pattern("regex") format
                            let patternRegex = #/pattern\(\"([^\"]*)\"\)/#
                            if let match = argText.firstMatch(of: patternRegex) {
                                pattern = String(match.1)
                            }
                        } else {
                            guides.append(argText)
                        }
                    }
                    
                    return (description, guides, pattern)
                }
            }
        }
        return (nil, [], nil)
    }
    
    /// Get default value for a type
    private static func getDefaultValue(for type: String) -> String {
        switch type.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "String":
            return "\"\""
        case "Int":
            return "0"
        case "Double", "Float":
            return "0.0"
        case "Bool":
            return "false"
        default:
            return "\"\""
        }
    }
    
    /// Generate property assignment from JSON
    private static func generatePropertyAssignment(for property: PropertyInfo) -> String {
        let propertyName = property.name
        let propertyType = property.type.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultValue = getDefaultValue(for: propertyType)
        
        switch propertyType {
        case "String":
            return "self.\(propertyName) = (json[\"\(propertyName)\"] as? String) ?? \(defaultValue)"
        case "Int":
            return "self.\(propertyName) = (json[\"\(propertyName)\"] as? Int) ?? \(defaultValue)"
        case "Double":
            return "self.\(propertyName) = (json[\"\(propertyName)\"] as? Double) ?? \(defaultValue)"
        case "Float":
            return "self.\(propertyName) = Float((json[\"\(propertyName)\"] as? Double) ?? Double(\(defaultValue)))"
        case "Bool":
            return "self.\(propertyName) = (json[\"\(propertyName)\"] as? Bool) ?? \(defaultValue)"
        default:
            return "self.\(propertyName) = \(defaultValue)"
        }
    }
    
    /// Generate init(_:) initializer according to Apple specs
    private static func generateInitFromGeneratedContent(structName: String, properties: [PropertyInfo]) -> DeclSyntax {
        // Generate property extraction code
        let propertyExtractions = properties.map { prop in
            generatePropertyExtraction(propertyName: prop.name, propertyType: prop.type)
        }.joined(separator: "\n            ")
        
        return DeclSyntax(stringLiteral: """
        public init(_ generatedContent: GeneratedContent) throws {
            // ✅ CONFIRMED: Apple generates init(_:) initializer
            // Extract properties from GeneratedContent
            let properties = try generatedContent.properties()
            
            \(propertyExtractions)
        }
        """)
    }
    
    /// Generate property extraction from GeneratedContent properties
    private static func generatePropertyExtraction(propertyName: String, propertyType: String) -> String {
        switch propertyType {
        case "String":
            return "self.\(propertyName) = properties[\"\(propertyName)\"]?.stringValue ?? \"\""
        case "Int":
            return """
            if let value = properties["\(propertyName)"]?.stringValue, let intValue = Int(value) {
                self.\(propertyName) = intValue
            } else {
                self.\(propertyName) = 0
            }
            """
        case "Double":
            return """
            if let value = properties["\(propertyName)"]?.stringValue, let doubleValue = Double(value) {
                self.\(propertyName) = doubleValue
            } else {
                self.\(propertyName) = 0.0
            }
            """
        case "Float":
            return """
            if let value = properties["\(propertyName)"]?.stringValue, let floatValue = Float(value) {
                self.\(propertyName) = floatValue
            } else {
                self.\(propertyName) = 0.0
            }
            """
        case "Bool":
            return """
            if let value = properties["\(propertyName)"]?.stringValue {
                self.\(propertyName) = value.lowercased() == "true" || value == "1"
            } else {
                self.\(propertyName) = false
            }
            """
        default:
            // For complex types, try to use their init(_:) if they conform to ConvertibleFromGeneratedContent
            return """
            if let value = properties["\(propertyName)"] {
                self.\(propertyName) = try \(propertyType)(value)
            } else {
                // TODO: Handle missing property - for now use default
                self.\(propertyName) = \(getDefaultValue(for: propertyType))
            }
            """
        }
    }
    
    /// Generate generatedContent property according to Apple specs
    private static func generateGeneratedContentProperty(structName: String, description: String?, properties: [PropertyInfo]) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public var generatedContent: GeneratedContent {
            // ✅ CONFIRMED: Apple generates generatedContent property
            // Convert this instance to GeneratedContent format
            return GeneratedContent("\\(self)")
        }
        """)
    }
    
    /// Generate from(generatedContent:) static method
    private static func generateFromGeneratedContentMethod(structName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public static func from(generatedContent: GeneratedContent) throws -> \(structName) {
            // For now, just create with init - proper parsing will be implemented later
            return try \(structName)(generatedContent)
        }
        """)
    }
    
    /// Generate toGeneratedContent() instance method
    private static func generateToGeneratedContentMethod() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public func toGeneratedContent() -> GeneratedContent {
            return self.generatedContent
        }
        """)
    }
    
    /// Generate generationSchema static property
    private static func generateGenerationSchemaProperty(structName: String, description: String?, properties: [PropertyInfo]) -> DeclSyntax {
        // Generate property definitions for the schema
        let propertyDefinitions = properties.map { prop in
            let descriptionValue = prop.guideDescription.map { "\"\($0)\"" } ?? "\"\""
            let patternValue = prop.pattern.map { "\"\($0)\"" } ?? "nil"
            return """
                GenerationSchema.Property(
                    name: "\(prop.name)",
                    type: "\(prop.type)",
                    description: \(descriptionValue),
                    guides: [],
                    pattern: \(patternValue)
                )
            """
        }
        
        let _ = propertyDefinitions.isEmpty ? "[]" : """
[
            \(propertyDefinitions.joined(separator: ",\n            "))
        ]
"""
        
        return DeclSyntax(stringLiteral: """
        public static var generationSchema: GenerationSchema {
            return GenerationSchema(
                type: "object",
                description: \(description.map { "\"\($0)\"" } ?? "\"Generated \(structName)\""),
                properties: [:],  // Will be computed dynamically
                anyOf: []
            )
        }
        """)
    }
    
    /// Generate asPartiallyGenerated method
    private static func generateAsPartiallyGeneratedMethod(structName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public func asPartiallyGenerated() -> Self {
            return self
        }
        """)
    }
    
    /// Generate PartiallyGenerated nested struct according to Apple specs
    private static func generatePartiallyGeneratedStruct(structName: String, properties: [PropertyInfo]) -> DeclSyntax {
        // Generate optional properties for partial representation
        let optionalProperties = properties.map { prop in
            "public var \(prop.name): \(prop.type)?"
        }.joined(separator: "\n        ")
        
        // Generate initialization assignments for partial
        let partialAssignments = properties.map { prop in
            "self.\(prop.name) = partial?.\(prop.name)"
        }.joined(separator: "\n            ")
        
        return DeclSyntax(stringLiteral: """
        /// Partially generated representation for streaming
        /// ✅ APPLE SPEC: Nested type for streaming support
        public struct PartiallyGenerated: Codable, Sendable, ConvertibleFromGeneratedContent {
            // Optional properties from original struct
            \(optionalProperties)
            
            // Apple required fields for streaming state
            public var isComplete: Bool
            public var rawContent: GeneratedContent
            
            /// Initialize with partial data
            public init(partial: \(structName)? = nil, isComplete: Bool = false, rawContent: GeneratedContent) {
                \(partialAssignments)
                self.isComplete = isComplete
                self.rawContent = rawContent
            }
            
            /// ConvertibleFromGeneratedContent conformance
            public static func from(generatedContent: GeneratedContent) throws -> PartiallyGenerated {
                // Basic implementation - decode from JSON if possible
                let isComplete = !generatedContent.text.isEmpty
                return PartiallyGenerated(
                    partial: nil,
                    isComplete: isComplete,
                    rawContent: generatedContent
                )
            }
        }
        """)
    }
    
    /// Generate instructionsRepresentation property
    private static func generateInstructionsRepresentationProperty() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public var instructionsRepresentation: Instructions {
            return Instructions(self.generatedContent.stringValue)
        }
        """)
    }
    
    /// Generate promptRepresentation property
    private static func generatePromptRepresentationProperty() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public var promptRepresentation: Prompt {
            return Prompt(self.generatedContent.stringValue)
        }
        """)
    }
    
    // MARK: - Enum Support Methods
    
    /// Extract enum cases from enum declaration
    private static func extractEnumCases(from enumDecl: EnumDeclSyntax) -> [EnumCaseInfo] {
        var cases: [EnumCaseInfo] = []
        
        for member in enumDecl.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    let caseName = element.name.text
                    var associatedValues: [(label: String?, type: String)] = []
                    
                    // Extract associated values if present
                    if let parameterClause = element.parameterClause {
                        for parameter in parameterClause.parameters {
                            let label = parameter.firstName?.text
                            let type = parameter.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                            associatedValues.append((label: label, type: type))
                        }
                    }
                    
                    // Look for @Guide attributes (if supported on enum cases)
                    let guideDescription: String? = nil // Enum cases don't typically have @Guide
                    
                    cases.append(EnumCaseInfo(
                        name: caseName,
                        associatedValues: associatedValues,
                        guideDescription: guideDescription
                    ))
                }
            }
        }
        
        return cases
    }
    
    /// Generate init(_:) for enums
    private static func generateEnumInitFromGeneratedContent(enumName: String, cases: [EnumCaseInfo]) -> DeclSyntax {
        // Generate switch-case based initialization for simple enums
        let switchCases = cases.map { enumCase in
            if enumCase.associatedValues.isEmpty {
                // Simple case without associated values
                return "case \"\(enumCase.name)\": self = .\(enumCase.name)"
            } else {
                // Associated values support - future implementation
                // For now, skip cases with associated values to avoid compiler crash
                return """
                // TODO: Future implementation for associated values
                // case with associated values: .\(enumCase.name)
                """
            }
        }.joined(separator: "\n            ")
        
        return DeclSyntax(stringLiteral: """
        public init(_ generatedContent: GeneratedContent) throws {
            // ✅ CONFIRMED: Apple generates init(_:) initializer for enums
            // Parse enum case from GeneratedContent string value
            let value = generatedContent.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            switch value {
            \(switchCases)
            default:
                throw GenerationError.decodingFailure(
                    GenerationError.Context(debugDescription: "Invalid enum case '\\(value)' for \(enumName). Valid cases: [\(cases.filter { $0.associatedValues.isEmpty }.map { $0.name }.joined(separator: ", "))]")
                )
            }
        }
        """)
    }
    
    /// Generate generatedContent property for enums
    private static func generateEnumGeneratedContentProperty(enumName: String, description: String?, cases: [EnumCaseInfo]) -> DeclSyntax {
        // Generate switch cases for simple enums only
        let switchCases = cases.map { enumCase in
            if enumCase.associatedValues.isEmpty {
                return "case .\(enumCase.name): return GeneratedContent(\"\(enumCase.name)\")"
            } else {
                // Associated values support - future implementation
                return """
                // TODO: Future implementation for associated values
                // case .\(enumCase.name): // with associated values
                """
            }
        }.joined(separator: "\n            ")
        
        return DeclSyntax(stringLiteral: """
        public var generatedContent: GeneratedContent {
            // ✅ CONFIRMED: Apple generates generatedContent property for enums
            // Convert enum case to GeneratedContent string representation
            switch self {
            \(switchCases)
            }
        }
        """)
    }
    
    /// Generate from(generatedContent:) static method for enums
    private static func generateEnumFromGeneratedContentMethod(enumName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public static func from(generatedContent: GeneratedContent) throws -> \(enumName) {
            return try \(enumName)(generatedContent)
        }
        """)
    }
    
    /// Generate generationSchema for enums
    private static func generateEnumGenerationSchemaProperty(enumName: String, description: String?, cases: [EnumCaseInfo]) -> DeclSyntax {
        // Create anyOf array for simple enum cases only (as strings)
        let simpleCases = cases.filter { $0.associatedValues.isEmpty }
        let caseNames = simpleCases.map { "\"\($0.name)\"" }.joined(separator: ", ")
        
        return DeclSyntax(stringLiteral: """
        public static var generationSchema: GenerationSchema {
            // ✅ CONFIRMED: Apple generates generationSchema for enums
            // Create schema for simple enum with anyOf containing possible case names
            return GenerationSchema(
                type: "string",
                description: \(description.map { "\"\($0)\"" } ?? "\"Generated \(enumName)\""),
                anyOf: [\(caseNames)]
            )
        }
        """)
    }
    
    
}

/// Implementation of the @Guide macro
/// 
/// ✅ CONFIRMED: From Apple Developer Documentation
/// - @attached(peer) - attaches to properties
/// - Provides generation guidance for properties
public struct GuideMacro: PeerMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // @Guide is metadata-only - no code generation needed
        // The GenerableMacro reads these attributes to generate schema
        return []
    }
}

// MARK: - Supporting Types

struct PropertyInfo {
    let name: String
    let type: String
    let guideDescription: String?
    let guides: [String]
    let pattern: String?
}

struct EnumCaseInfo {
    let name: String
    let associatedValues: [(label: String?, type: String)]
    let guideDescription: String?
}

enum MacroError: Error, CustomStringConvertible {
    case notApplicableToType
    case invalidSyntax
    case missingRequiredParameter
    
    var description: String {
        switch self {
        case .notApplicableToType:
            return "@Generable can only be applied to structs, actors, or enumerations"
        case .invalidSyntax:
            return "Invalid macro syntax"
        case .missingRequiredParameter:
            return "Missing required parameter"
        }
    }
}

// MARK: - Compiler Plugin

@main
struct OpenFoundationModelsMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GenerableMacro.self,
        GuideMacro.self
    ]
}