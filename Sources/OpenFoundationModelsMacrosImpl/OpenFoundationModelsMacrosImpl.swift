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
                generateRawContentProperty(),  // Add property to store original GeneratedContent
                generateInitFromGeneratedContent(structName: structName, properties: properties),
                generateGeneratedContentProperty(structName: structName, description: description, properties: properties),
                // Removed generateFromGeneratedContentMethod and generateToGeneratedContentMethod
                // as they are not needed with the new protocol design
                generateGenerationSchemaProperty(structName: structName, description: description, properties: properties),
                generatePartiallyGeneratedStruct(structName: structName, properties: properties),
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
                generateAsPartiallyGeneratedMethodForEnum(enumName: enumName),
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
        let trimmedType = type.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for Optional types (ends with ?)
        if trimmedType.hasSuffix("?") {
            return "nil"
        }
        
        // Check for Array types (starts with [ and ends with ])
        if trimmedType.hasPrefix("[") && trimmedType.hasSuffix("]") {
            return "[]"
        }
        
        // Handle basic types
        switch trimmedType {
        case "String":
            return "\"\""
        case "Int":
            return "0"
        case "Double", "Float":
            return "0.0"
        case "Bool":
            return "false"
        default:
            // For custom types, return nil (will need proper handling in generatePropertyExtraction)
            return "nil"
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
    
    /// Generate property to store original GeneratedContent
    private static func generateRawContentProperty() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        private let _rawGeneratedContent: GeneratedContent
        """)
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
            // Store the original GeneratedContent
            self._rawGeneratedContent = generatedContent
            
            // Extract properties from GeneratedContent
            let properties = try generatedContent.properties()
            
            \(propertyExtractions)
        }
        """)
    }
    
    /// Generate property extraction from GeneratedContent properties for partial types
    private static func generatePartialPropertyExtraction(propertyName: String, propertyType: String) -> String {
        switch propertyType {
        case "String", "String?":
            return "self.\(propertyName) = try? properties[\"\(propertyName)\"]?.value(String.self)"
        case "Int", "Int?":
            return "self.\(propertyName) = try? properties[\"\(propertyName)\"]?.value(Int.self)"
        case "Double", "Double?":
            return "self.\(propertyName) = try? properties[\"\(propertyName)\"]?.value(Double.self)"
        case "Float", "Float?":
            return "self.\(propertyName) = try? properties[\"\(propertyName)\"]?.value(Float.self)"
        case "Bool", "Bool?":
            return "self.\(propertyName) = try? properties[\"\(propertyName)\"]?.value(Bool.self)"
        default:
            // For complex types, try to initialize if possible
            return """
            if let value = properties[\"\(propertyName)\"] {
                self.\(propertyName) = try? \(propertyType)(value)
            } else {
                self.\(propertyName) = nil
            }
            """
        }
    }
    
    /// Generate property extraction from GeneratedContent properties
    private static func generatePropertyExtraction(propertyName: String, propertyType: String) -> String {
        switch propertyType {
        case "String":
            return """
            self.\(propertyName) = try properties["\(propertyName)"]?.value(String.self) ?? ""
            """
        case "Int":
            return """
            self.\(propertyName) = try properties["\(propertyName)"]?.value(Int.self) ?? 0
            """
        case "Double":
            return """
            self.\(propertyName) = try properties["\(propertyName)"]?.value(Double.self) ?? 0.0
            """
        case "Float":
            return """
            self.\(propertyName) = try properties["\(propertyName)"]?.value(Float.self) ?? 0.0
            """
        case "Bool":
            return """
            self.\(propertyName) = try properties["\(propertyName)"]?.value(Bool.self) ?? false
            """
        default:
            // For complex types, try to use their init(_:) if they conform to ConvertibleFromGeneratedContent
            // Check if the type is optional or an array
            let isOptional = propertyType.hasSuffix("?")
            let isArray = propertyType.hasPrefix("[") && propertyType.hasSuffix("]")
            
            if isOptional {
                // For optional types, can safely use nil
                return """
                if let value = properties["\(propertyName)"] {
                    self.\(propertyName) = try \(propertyType.replacingOccurrences(of: "?", with: ""))(value)
                } else {
                    self.\(propertyName) = nil
                }
                """
            } else if isArray {
                // For array types, use empty array as default
                return """
                if let value = properties["\(propertyName)"] {
                    self.\(propertyName) = try \(propertyType)(value)
                } else {
                    self.\(propertyName) = []
                }
                """
            } else {
                // For non-optional custom types, we need to handle carefully
                // In PartiallyGenerated context, everything is optional, so this shouldn't happen
                // But for normal init, we might want to throw an error or use a default constructor
                return """
                if let value = properties["\(propertyName)"] {
                    self.\(propertyName) = try \(propertyType)(value)
                } else {
                    // For non-optional custom types, attempt default initialization
                    // This will fail at compile time if no default init exists
                    self.\(propertyName) = try \(propertyType)(GeneratedContent("{}"))
                }
                """
            }
        }
    }
    
    /// Generate generatedContent property according to Apple specs
    private static func generateGeneratedContentProperty(structName: String, description: String?, properties: [PropertyInfo]) -> DeclSyntax {
        // Generate property conversion code for each property
        let propertyConversions = properties.map { prop in
            let propName = prop.name
            let propType = prop.type
            
            if propType.hasSuffix("?") {
                // Optional property
                let baseType = String(propType.dropLast()) // Remove "?"
                if baseType == "String" {
                    return "properties[\"\(propName)\"] = \(propName).map { GeneratedContent($0) } ?? GeneratedContent(kind: .null)"
                } else if baseType == "Int" || baseType == "Double" || baseType == "Float" || baseType == "Bool" {
                    return "properties[\"\(propName)\"] = \(propName).map { GeneratedContent(String($0)) } ?? GeneratedContent(kind: .null)"
                } else if baseType.hasPrefix("[") && baseType.hasSuffix("]") {
                    // Optional array
                    return "properties[\"\(propName)\"] = \(propName).map { GeneratedContent(elements: $0) } ?? GeneratedContent(kind: .null)"
                } else {
                    // Custom optional type - use if-let to avoid ambiguity
                    return """
                    if let value = \(propName) {
                                properties["\(propName)"] = value.generatedContent
                            } else {
                                properties["\(propName)"] = GeneratedContent(kind: .null)
                            }
                    """
                }
            } else if propType.hasPrefix("[") && propType.hasSuffix("]") {
                // Array property
                let elementType = String(propType.dropFirst().dropLast())
                if elementType == "String" {
                    return "properties[\"\(propName)\"] = GeneratedContent(elements: \(propName))"
                } else if elementType == "Int" || elementType == "Double" || elementType == "Bool" || elementType == "Float" {
                    return "properties[\"\(propName)\"] = GeneratedContent(elements: \(propName).map { String($0) })"
                } else {
                    // Custom type array
                    return "properties[\"\(propName)\"] = GeneratedContent(elements: \(propName))"
                }
            } else {
                // Required non-array property
                switch propType {
                case "String":
                    return "properties[\"\(propName)\"] = GeneratedContent(\(propName))"
                case "Int", "Double", "Float", "Bool":
                    return "properties[\"\(propName)\"] = GeneratedContent(String(\(propName)))"
                default:
                    // Custom type
                    return "properties[\"\(propName)\"] = \(propName).generatedContent"
                }
            }
        }.joined(separator: "\n            ")
        
        let orderedKeys = properties.map { "\"\($0.name)\"" }.joined(separator: ", ")
        
        return DeclSyntax(stringLiteral: """
        public var generatedContent: GeneratedContent {
            // ✅ CONFIRMED: Apple generates generatedContent property
            // Build GeneratedContent from current property values
            var properties: [String: GeneratedContent] = [:]
            \(propertyConversions)
            
            return GeneratedContent(
                kind: .structure(
                    properties: properties,
                    orderedKeys: [\(orderedKeys)]
                )
            )
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
            let descriptionParam = prop.guideDescription.map { "description: \"\($0)\"" } ?? "description: nil"
            
            // Map Swift types to correct type parameter
            let typeParam: String
            switch prop.type {
            case "String", "String?":
                typeParam = "String.self"
            case "Int", "Int?":
                typeParam = "Int.self"
            case "Double", "Double?":
                typeParam = "Double.self"
            case "Float", "Float?":
                typeParam = "Float.self"
            case "Bool", "Bool?":
                typeParam = "Bool.self"
            default:
                // For other types, assume they are Generable
                typeParam = "\(prop.type.replacingOccurrences(of: "?", with: "")).self"
            }
            
            // Build guides array
            var guides: [String] = []
            if let pattern = prop.pattern {
                guides.append("try! Regex(\"\(pattern)\")")
            }
            let guidesParam = guides.isEmpty ? "[]" : "[\(guides.joined(separator: ", "))]"
            
            return """
                GenerationSchema.Property(
                    name: "\(prop.name)",
                    \(descriptionParam),
                    type: \(typeParam),
                    guides: \(guidesParam)
                )
            """
        }
        
        let propertiesArray = propertyDefinitions.isEmpty ? "[]" : """
[
                \(propertyDefinitions.joined(separator: ",\n                "))
            ]
"""
        
        return DeclSyntax(stringLiteral: """
        public static var generationSchema: GenerationSchema {
            return GenerationSchema(
                type: \(structName).self,
                description: \(description.map { "\"\($0)\"" } ?? "\"Generated \(structName)\""),
                properties: \(propertiesArray)
            )
        }
        """)
    }
    
    /// Generate asPartiallyGenerated method for structs
    private static func generateAsPartiallyGeneratedMethod(structName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public func asPartiallyGenerated() -> PartiallyGenerated {
            // Convert this instance to its PartiallyGenerated representation
            // Use the raw generated content to preserve the original JSON structure
            return try! PartiallyGenerated(self._rawGeneratedContent)
        }
        """)
    }
    
    /// Generate asPartiallyGenerated method for enums
    private static func generateAsPartiallyGeneratedMethodForEnum(enumName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public func asPartiallyGenerated() -> PartiallyGenerated {
            // For enums, convert to generatedContent and then to PartiallyGenerated
            // Enums don't store raw content, so we use the generated representation
            return try! PartiallyGenerated(self.generatedContent)
        }
        """)
    }
    
    /// Generate PartiallyGenerated nested struct according to Apple specs
    private static func generatePartiallyGeneratedStruct(structName: String, properties: [PropertyInfo]) -> DeclSyntax {
        // Generate optional properties for partial representation
        // Avoid double optionals by checking if the type is already optional
        let optionalProperties = properties.map { prop in
            let propertyType = prop.type
            // Check if the type already ends with ?
            if propertyType.hasSuffix("?") {
                // Already optional, don't add another ?
                return "public let \(prop.name): \(propertyType)"
            } else {
                // Make it optional
                return "public let \(prop.name): \(propertyType)?"
            }
        }.joined(separator: "\n        ")
        
        // Generate property extraction from GeneratedContent
        let propertyExtractions = properties.map { prop in
            generatePartialPropertyExtraction(propertyName: prop.name, propertyType: prop.type)
        }.joined(separator: "\n            ")
        
        // Generate required properties check for isComplete
        // Only non-optional properties are required
        let requiredProperties = properties.filter { !$0.type.hasSuffix("?") }
        let requiredPropertiesCheck: String
        if requiredProperties.isEmpty {
            requiredPropertiesCheck = "true"
        } else {
            let checks = requiredProperties.map { "self.\($0.name) != nil" }.joined(separator: " && ")
            requiredPropertiesCheck = "(\(checks))"
        }
        
        return DeclSyntax(stringLiteral: """
        /// Partially generated representation for streaming
        /// ✅ APPLE SPEC: Nested type for streaming support
        public struct PartiallyGenerated: Sendable, ConvertibleFromGeneratedContent, PartiallyGeneratedProtocol {
            // Optional properties from original struct
            \(optionalProperties)
            
            // Track completion state
            public let isComplete: Bool
            
            // Store the raw content
            private let rawContent: GeneratedContent
            
            /// ConvertibleFromGeneratedContent conformance
            public init(_ generatedContent: GeneratedContent) throws {
                self.rawContent = generatedContent
                
                // Try to extract properties, allowing partial parsing
                if let properties = try? generatedContent.properties() {
                    \(propertyExtractions)
                    
                    // Check if JSON is syntactically complete AND all required properties are present
                    self.isComplete = generatedContent.isComplete && \(requiredPropertiesCheck)
                } else {
                    // If we can't parse as structure, initialize all as nil
                    \(properties.map { "self.\($0.name) = nil" }.joined(separator: "\n                    "))
                    self.isComplete = false
                }
            }
            
            /// ConvertibleToGeneratedContent conformance
            public var generatedContent: GeneratedContent {
                return rawContent
            }
        }
        """)
    }
    
    /// Generate instructionsRepresentation property
    private static func generateInstructionsRepresentationProperty() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public var instructionsRepresentation: Instructions {
            return Instructions(self.generatedContent.text)
        }
        """)
    }
    
    /// Generate promptRepresentation property
    private static func generatePromptRepresentationProperty() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public var promptRepresentation: Prompt {
            return Prompt(self.generatedContent.text)
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
        let hasAnyAssociatedValues = cases.contains { $0.hasAssociatedValues }
        
        if hasAnyAssociatedValues {
            // Mixed enum with associated values - use discriminated union approach
            let switchCases = cases.map { enumCase in
                if enumCase.associatedValues.isEmpty {
                    // Simple case
                    return """
                    case "\(enumCase.name)":
                        self = .\(enumCase.name)
                    """
                } else if enumCase.isSingleUnlabeledValue {
                    // Single unlabeled associated value: case text(String)
                    let valueType = enumCase.associatedValues[0].type
                    return generateSingleValueCase(caseName: enumCase.name, valueType: valueType)
                } else {
                    // Multiple or labeled associated values: case video(url: String, duration: Int)
                    return generateMultipleValueCase(caseName: enumCase.name, associatedValues: enumCase.associatedValues)
                }
            }.joined(separator: "\n                ")
            
            return DeclSyntax(stringLiteral: """
            public init(_ generatedContent: GeneratedContent) throws {
                // ✅ CONFIRMED: Apple generates init(_:) initializer for enums with associated values
                // Parse discriminated union: {"case": "caseName", "value": associatedData}
                
                do {
                    let properties = try generatedContent.properties()
                    
                    guard let caseValue = properties["case"]?.text else {
                        throw GenerationError.decodingFailure(
                            GenerationError.Context(debugDescription: "Missing 'case' property in enum data for \(enumName)")
                        )
                    }
                    
                    let valueContent = properties["value"]
                    
                    switch caseValue {
                    \(switchCases)
                    default:
                        throw GenerationError.decodingFailure(
                            GenerationError.Context(debugDescription: "Invalid enum case '\\(caseValue)' for \(enumName). Valid cases: [\(cases.map { $0.name }.joined(separator: ", "))]")
                        )
                    }
                } catch {
                    // Fallback: try simple string parsing for backward compatibility
                    let value = generatedContent.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    switch value {
                    \(cases.filter { !$0.hasAssociatedValues }.map { "case \"\($0.name)\": self = .\($0.name)" }.joined(separator: "\n                    "))
                    default:
                        throw GenerationError.decodingFailure(
                            GenerationError.Context(debugDescription: "Invalid enum case '\\(value)' for \(enumName). Valid cases: [\(cases.map { $0.name }.joined(separator: ", "))]")
                        )
                    }
                }
            }
            """)
        } else {
            // Simple enum cases only (existing logic)
            let switchCases = cases.map { enumCase in
                "case \"\(enumCase.name)\": self = .\(enumCase.name)"
            }.joined(separator: "\n            ")
            
            return DeclSyntax(stringLiteral: """
            public init(_ generatedContent: GeneratedContent) throws {
                // ✅ CONFIRMED: Apple generates init(_:) initializer for simple enums
                // Parse enum case from GeneratedContent string value
                let value = generatedContent.text.trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch value {
                \(switchCases)
                default:
                    throw GenerationError.decodingFailure(
                        GenerationError.Context(debugDescription: "Invalid enum case '\\(value)' for \(enumName). Valid cases: [\(cases.map { $0.name }.joined(separator: ", "))]")
                    )
                }
            }
            """)
        }
    }
    
    /// Generate switch case for single unlabeled associated value
    private static func generateSingleValueCase(caseName: String, valueType: String) -> String {
        switch valueType {
        case "String":
            return """
            case "\(caseName)":
                if let valueContent = valueContent {
                    let stringValue = valueContent.text
                    self = .\(caseName)(stringValue)
                } else {
                    self = .\(caseName)("")
                }
            """
        case "Int":
            return """
            case "\(caseName)":
                if let valueContent = valueContent,
                   let intValue = Int(valueContent.text) {
                    self = .\(caseName)(intValue)
                } else {
                    self = .\(caseName)(0)
                }
            """
        case "Double":
            return """
            case "\(caseName)":
                if let valueContent = valueContent,
                   let doubleValue = Double(valueContent.text) {
                    self = .\(caseName)(doubleValue)
                } else {
                    self = .\(caseName)(0.0)
                }
            """
        case "Bool":
            return """
            case "\(caseName)":
                if let valueContent = valueContent {
                    let boolValue = valueContent.text.lowercased() == "true"
                    self = .\(caseName)(boolValue)
                } else {
                    self = .\(caseName)(false)
                }
            """
        default:
            // For custom types that conform to ConvertibleFromGeneratedContent
            return """
            case "\(caseName)":
                if let valueContent = valueContent {
                    let associatedValue = try \(valueType)(valueContent)
                    self = .\(caseName)(associatedValue)
                } else {
                    throw GenerationError.decodingFailure(
                        GenerationError.Context(debugDescription: "Missing value for enum case '\(caseName)' with associated type \(valueType)")
                    )
                }
            """
        }
    }
    
    /// Generate switch case for multiple or labeled associated values
    private static func generateMultipleValueCase(caseName: String, associatedValues: [(label: String?, type: String)]) -> String {
        let valueExtractions = associatedValues.enumerated().map { index, assocValue in
            let label = assocValue.label ?? "param\(index)"
            let type = assocValue.type
            
            switch type {
            case "String":
                return "let \(label) = valueProperties[\"\(label)\"]?.text ?? \"\""
            case "Int":
                return "let \(label) = Int(valueProperties[\"\(label)\"]?.text ?? \"0\") ?? 0"
            case "Double":
                return "let \(label) = Double(valueProperties[\"\(label)\"]?.text ?? \"0.0\") ?? 0.0"
            case "Bool":
                return "let \(label) = valueProperties[\"\(label)\"]?.text?.lowercased() == \"true\""
            default:
                return "let \(label) = try \(type)(valueProperties[\"\(label)\"] ?? GeneratedContent(\"{}\"))"
            }
        }.joined(separator: "\n                    ")
        
        let parameterList = associatedValues.enumerated().map { index, assocValue in
            let label = assocValue.label ?? "param\(index)"
            if assocValue.label != nil {
                return "\(label): \(label)"
            } else {
                return label
            }
        }.joined(separator: ", ")
        
        return """
        case "\(caseName)":
            if let valueContent = valueContent {
                let valueProperties = try valueContent.properties()
                \(valueExtractions)
                self = .\(caseName)(\(parameterList))
            } else {
                throw GenerationError.decodingFailure(
                    GenerationError.Context(debugDescription: "Missing value data for enum case '\(caseName)' with associated values")
                )
            }
        """
    }
    
    /// Generate generatedContent property for enums
    private static func generateEnumGeneratedContentProperty(enumName: String, description: String?, cases: [EnumCaseInfo]) -> DeclSyntax {
        let hasAnyAssociatedValues = cases.contains { $0.hasAssociatedValues }
        
        if hasAnyAssociatedValues {
            // Mixed enum with associated values - generate discriminated union
            let switchCases = cases.map { enumCase in
                if enumCase.associatedValues.isEmpty {
                    // Simple case
                    return """
                    case .\(enumCase.name):
                        return GeneratedContent(properties: [
                            "case": GeneratedContent("\(enumCase.name)"),
                            "value": GeneratedContent("")
                        ])
                    """
                } else if enumCase.isSingleUnlabeledValue {
                    // Single unlabeled associated value - store value directly
                    return """
                    case .\\(enumCase.name)(let value):
                        return GeneratedContent(properties: [
                            "case": GeneratedContent("\\(enumCase.name)"),
                            "value": GeneratedContent("\\\\(value)")
                        ])
                    """
                } else {
                    // Multiple or labeled associated values
                    return generateMultipleValueSerialization(caseName: enumCase.name, associatedValues: enumCase.associatedValues)
                }
            }.joined(separator: "\n            ")
            
            return DeclSyntax(stringLiteral: """
            public var generatedContent: GeneratedContent {
                // ✅ CONFIRMED: Apple generates generatedContent property for enums with associated values
                // Convert enum case to discriminated union: {"case": "caseName", "value": associatedData}
                switch self {
                \(switchCases)
                }
            }
            """)
        } else {
            // Simple enum cases only (existing logic)
            let switchCases = cases.map { enumCase in
                "case .\(enumCase.name): return GeneratedContent(\"\(enumCase.name)\")"
            }.joined(separator: "\n            ")
            
            return DeclSyntax(stringLiteral: """
            public var generatedContent: GeneratedContent {
                // ✅ CONFIRMED: Apple generates generatedContent property for simple enums
                // Convert enum case to GeneratedContent string representation
                switch self {
                \(switchCases)
                }
            }
            """)
        }
    }
    
    /// Generate serialization for single unlabeled associated value
    private static func generateSingleValueSerialization(caseName: String, valueType: String) -> String {
        switch valueType {
        case "String", "Int", "Double", "Bool":
            return """
            case .\(caseName)(let value):
                return GeneratedContent(properties: [
                    "case": GeneratedContent("\(caseName)"),
                    "value": GeneratedContent("\\(value)")
                ])
            """
        default:
            // For custom types that conform to ConvertibleToGeneratedContent
            return """
            case .\(caseName)(let value):
                return GeneratedContent(properties: [
                    "case": GeneratedContent("\(caseName)"),
                    "value": value.generatedContent
                ])
            """
        }
    }
    
    /// Generate serialization for multiple or labeled associated values
    private static func generateMultipleValueSerialization(caseName: String, associatedValues: [(label: String?, type: String)]) -> String {
        let parameterList = associatedValues.enumerated().map { index, assocValue in
            let label = assocValue.label ?? "param\(index)"
            return "let \(label)"
        }.joined(separator: ", ")
        
        let propertyMappings = associatedValues.enumerated().map { index, assocValue in
            let label = assocValue.label ?? "param\(index)"
            let type = assocValue.type
            
            switch type {
            case "String", "Int", "Double", "Bool":
                return "\"\(label)\": GeneratedContent(\"\\(\(label))\")"
            default:
                return "\"\(label)\": \(label).generatedContent"
            }
        }.joined(separator: ",\n                        ")
        
        return """
        case .\(caseName)(\(parameterList)):
            return GeneratedContent(properties: [
                "case": GeneratedContent("\(caseName)"),
                "value": GeneratedContent(properties: [
                    \(propertyMappings)
                ])
            ])
        """
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
        let hasAnyAssociatedValues = cases.contains { $0.hasAssociatedValues }
        
        if hasAnyAssociatedValues {
            // Mixed enum with both simple and associated value cases
            // Use object type with discriminated union approach
            
            // Create properties for discriminated union
            let caseProperty = """
GenerationSchema.Property(
                        name: "case",
                        description: "Enum case identifier",
                        type: String.self,
                        guides: []
                    )
"""
            let valueProperty = """
GenerationSchema.Property(
                        name: "value",
                        description: "Associated value data",
                        type: String.self,
                        guides: []
                    )
"""
            
            return DeclSyntax(stringLiteral: """
            public static var generationSchema: GenerationSchema {
                // ✅ CONFIRMED: Apple generates discriminated union schema for enums with associated values
                // Each case becomes an object with "case" and "value" properties
                
                // Create a dummy Generable type for the enum schema
                struct \(enumName)Schema: Generable {
                    public init(_ generatedContent: GeneratedContent) throws {}
                    public var generatedContent: GeneratedContent { GeneratedContent("") }
                    public static var generationSchema: GenerationSchema { 
                        GenerationSchema(type: \(enumName)Schema.self, description: "Enum", properties: [])
                    }
                }
                
                return GenerationSchema(
                    type: \(enumName)Schema.self,
                    description: \(description.map { "\"\($0)\"" } ?? "\"Generated \(enumName)\""),
                    properties: [
                        \(caseProperty),
                        \(valueProperty)
                    ]
                )
            }
            """)
        } else {
            // Simple enum cases only - use type initializer with anyOf
            let caseNames = cases.map { "\"\($0.name)\"" }.joined(separator: ", ")
            
            return DeclSyntax(stringLiteral: """
            public static var generationSchema: GenerationSchema {
                // ✅ CONFIRMED: Apple generates generationSchema for simple enums
                // Create schema for simple enum using type initializer with anyOf
                
                // Create a dummy Generable type for the enum schema
                struct \(enumName)Schema: Generable {
                    public init(_ generatedContent: GeneratedContent) throws {}
                    public var generatedContent: GeneratedContent { GeneratedContent("") }
                    public static var generationSchema: GenerationSchema { 
                        GenerationSchema(type: \(enumName)Schema.self, description: "Enum", anyOf: [])
                    }
                }
                
                return GenerationSchema(
                    type: \(enumName)Schema.self,
                    description: \(description.map { "\"\($0)\"" } ?? "\"Generated \(enumName)\""),
                    anyOf: [\(caseNames)]
                )
            }
            """)
        }
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
    
    // Associated values support helpers
    var hasAssociatedValues: Bool { 
        !associatedValues.isEmpty 
    }
    
    var isSingleUnlabeledValue: Bool { 
        associatedValues.count == 1 && associatedValues[0].label == nil 
    }
    
    var isMultipleLabeledValues: Bool {
        associatedValues.count > 1 || (associatedValues.count == 1 && associatedValues[0].label != nil)
    }
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