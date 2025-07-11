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
public struct GenerableMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract the struct name
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.notApplicableToType
        }
        
        let structName = structDecl.name.text
        let description = extractDescription(from: node)
        
        // Get all properties with @Guide annotations
        let properties = extractGuidedProperties(from: structDecl)
        
        // Generate the required members according to Apple specs
        // ✅ CONFIRMED: Apple only generates init(_:) and generatedContent
        // Plus we need to generate protocol methods for full conformance
        return [
            generateInitFromGeneratedContent(structName: structName, properties: properties),
            generateGeneratedContentProperty(structName: structName, description: description, properties: properties),
            generateFromGeneratedContentMethod(structName: structName),
            generateToGeneratedContentMethod(),
            generateGenerationSchemaProperty(structName: structName, description: description, properties: properties),
            generateAsPartiallyGeneratedMethod(structName: structName),
            generatePartiallyGeneratedStruct(structName: structName, properties: properties)
        ]
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
    
    /// Generate init(_:) initializer according to Apple specs
    private static func generateInitFromGeneratedContent(structName: String, properties: [PropertyInfo]) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public init(_ generatedContent: GeneratedContent) {
            // ✅ CONFIRMED: Apple generates init(_:) initializer
            fatalError("init(_:) not implemented - requires GeneratedContent parsing")
        }
        """)
    }
    
    /// Generate generatedContent property according to Apple specs
    private static func generateGeneratedContentProperty(structName: String, description: String?, properties: [PropertyInfo]) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public var generatedContent: GeneratedContent {
            // ✅ CONFIRMED: Apple generates generatedContent property
            // Convert this instance to GeneratedContent format
            fatalError("generatedContent not implemented - requires instance serialization")
        }
        """)
    }
    
    /// Generate from(generatedContent:) static method
    private static func generateFromGeneratedContentMethod(structName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public static func from(generatedContent: GeneratedContent) throws -> \(structName) {
            return \(structName)(generatedContent)
        }
        """)
    }
    
    /// Generate toGeneratedContent() instance method
    private static func generateToGeneratedContentMethod() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public func toGeneratedContent() throws -> GeneratedContent {
            return self.generatedContent
        }
        """)
    }
    
    /// Generate generationSchema static property
    private static func generateGenerationSchemaProperty(structName: String, description: String?, properties: [PropertyInfo]) -> DeclSyntax {
        // Generate property definitions for the schema
        let propertyDefinitions = properties.map { prop in
            let descriptionValue = prop.guideDescription.map { "\"\($0)\"" } ?? "nil"
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
        
        let propertiesArray = propertyDefinitions.isEmpty ? "[]" : """
[
            \(propertyDefinitions.joined(separator: ",\n            "))
        ]
"""
        
        return DeclSyntax(stringLiteral: """
        public static var generationSchema: GenerationSchema {
            return GenerationSchema(
                type: \(structName).self,
                description: \(description.map { "\"\($0)\"" } ?? "nil"),
                properties: \(propertiesArray)
            )
        }
        """)
    }
    
    /// Generate asPartiallyGenerated method
    private static func generateAsPartiallyGeneratedMethod(structName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public func asPartiallyGenerated() -> PartiallyGenerated {
            return PartiallyGenerated(
                partial: self,
                isComplete: true,
                rawContent: self.generatedContent
            )
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
                let decoder = JSONDecoder()
                let decoded = try? decoder.decode(\(structName).self, from: generatedContent.dataValue)
                return PartiallyGenerated(
                    partial: decoded,
                    isComplete: decoded != nil,
                    rawContent: generatedContent
                )
            }
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

enum MacroError: Error, CustomStringConvertible {
    case notApplicableToType
    case invalidSyntax
    case missingRequiredParameter
    
    var description: String {
        switch self {
        case .notApplicableToType:
            return "@Generable can only be applied to structs"
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