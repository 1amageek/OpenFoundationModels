import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct GenerableMacro: MemberMacro, ExtensionMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            let structName = structDecl.name.text
            let description = extractDescription(from: node)
            
            let properties = extractGuidedProperties(from: structDecl)
            
            return [
                generateRawContentProperty(),  // Add property to store original GeneratedContent
                generateInitFromGeneratedContent(structName: structName, properties: properties),
                generateGeneratedContentProperty(structName: structName, description: description, properties: properties),
                generateGenerationSchemaProperty(structName: structName, description: description, properties: properties),
                generatePartiallyGeneratedStruct(structName: structName, properties: properties),
                generateAsPartiallyGeneratedMethod(structName: structName),
                generateInstructionsRepresentationProperty(),
                generatePromptRepresentationProperty()
            ]
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            let enumName = enumDecl.name.text
            let description = extractDescription(from: node)
            
            let cases = extractEnumCases(from: enumDecl)
            
            return [
                generateEnumInitFromGeneratedContent(enumName: enumName, cases: cases),
                generateEnumGeneratedContentProperty(enumName: enumName, description: description, cases: cases),
                generateEnumGenerationSchemaProperty(enumName: enumName, description: description, cases: cases),
                generateAsPartiallyGeneratedMethodForEnum(enumName: enumName),
                generateInstructionsRepresentationProperty(),
                generatePromptRepresentationProperty()
            ]
        } else {
            throw MacroError.notApplicableToType
        }
    }
    
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
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
                if let arguments = attr.arguments?.as(LabeledExprListSyntax.self),
                   let descArg = arguments.first,
                   let stringLiteral = descArg.expression.as(StringLiteralExprSyntax.self) {
                    let description = stringLiteral.segments.description.trimmingCharacters(in: .init(charactersIn: "\""))
                    
                    var guides: [String] = []
                    var pattern: String? = nil
                    
                    for arg in Array(arguments.dropFirst()) {
                        let argText = arg.expression.description
                        
                        if argText.contains(".pattern(") {
                            let patternRegex = #/\.pattern\(\"([^\"]*)\"\)/#
                            if let match = argText.firstMatch(of: patternRegex) {
                                pattern = String(match.1)
                            }
                        } else if argText.contains("pattern(") {
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
    
    // MARK: - Dictionary Type Helpers
    
    private static func isDictionaryType(_ type: String) -> Bool {
        let trimmed = type.trimmingCharacters(in: .whitespacesAndNewlines)
        // Check for Dictionary format: [Key: Value]
        return trimmed.hasPrefix("[") && trimmed.contains(":") && trimmed.hasSuffix("]")
    }
    
    private static func extractDictionaryTypes(_ type: String) -> (key: String, value: String)? {
        let trimmed = type.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove brackets and split by colon
        guard trimmed.hasPrefix("[") && trimmed.hasSuffix("]") && trimmed.contains(":") else {
            return nil
        }
        
        let inner = String(trimmed.dropFirst().dropLast())
        let parts = inner.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        guard parts.count == 2 else { return nil }
        
        return (key: parts[0], value: parts[1])
    }
    
    private static func getDefaultValue(for type: String) -> String {
        let trimmedType = type.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedType.hasSuffix("?") {
            return "nil"
        }
        
        // Check for Dictionary type first
        if isDictionaryType(trimmedType) {
            return "[:]"
        }
        
        if trimmedType.hasPrefix("[") && trimmedType.hasSuffix("]") {
            return "[]"
        }
        
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
            return "nil"
        }
    }
    
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
    
    private static func generateRawContentProperty() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        private let _rawGeneratedContent: GeneratedContent
        """)
    }
    
    private static func generateInitFromGeneratedContent(structName: String, properties: [PropertyInfo]) -> DeclSyntax {
        let propertyExtractions = properties.map { prop in
            generatePropertyExtraction(propertyName: prop.name, propertyType: prop.type)
        }.joined(separator: "\n            ")
        
        // If there are no properties, we don't need to extract them
        if properties.isEmpty {
            return DeclSyntax(stringLiteral: """
            public init(_ generatedContent: GeneratedContent) throws {
                self._rawGeneratedContent = generatedContent
                
                _ = try generatedContent.properties()  // Validate structure even if empty
            }
            """)
        } else {
            return DeclSyntax(stringLiteral: """
            public init(_ generatedContent: GeneratedContent) throws {
                self._rawGeneratedContent = generatedContent
                
                let properties = try generatedContent.properties()
                
                \(propertyExtractions)
            }
            """)
        }
    }
    
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
            // Check if it's a Dictionary type
            let baseType = propertyType.replacingOccurrences(of: "?", with: "")
            if isDictionaryType(baseType) {
                return """
                if let value = properties[\"\(propertyName)\"] {
                    self.\(propertyName) = try? \(baseType)(value)
                } else {
                    self.\(propertyName) = nil
                }
                """
            } else {
                return """
                if let value = properties[\"\(propertyName)\"] {
                    self.\(propertyName) = try? \(propertyType)(value)
                } else {
                    self.\(propertyName) = nil
                }
                """
            }
        }
    }
    
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
            let isOptional = propertyType.hasSuffix("?")
            let isDictionary = isDictionaryType(propertyType.replacingOccurrences(of: "?", with: ""))
            let isArray = !isDictionary && propertyType.hasPrefix("[") && propertyType.hasSuffix("]")
            
            if isOptional {
                let baseType = propertyType.replacingOccurrences(of: "?", with: "")
                
                // For basic optional types like Int?, String?, etc.
                if baseType == "Int" || baseType == "String" || baseType == "Double" || 
                   baseType == "Float" || baseType == "Bool" {
                    return """
                    if let value = properties["\(propertyName)"] {
                        switch value.kind {
                        case .null:
                            self.\(propertyName) = nil
                        default:
                            self.\(propertyName) = try value.value(\(baseType).self)
                        }
                    } else {
                        self.\(propertyName) = nil
                    }
                    """
                } else {
                    // For custom types that have Optional<T: ConvertibleFromGeneratedContent>
                    return """
                    if let value = properties["\(propertyName)"] {
                        switch value.kind {
                        case .null:
                            self.\(propertyName) = nil
                        default:
                            self.\(propertyName) = try \(baseType)(value)
                        }
                    } else {
                        self.\(propertyName) = nil
                    }
                    """
                }
                
            } else if isDictionary {
                return """
                if let value = properties["\(propertyName)"] {
                    self.\(propertyName) = try \(propertyType)(value)
                } else {
                    self.\(propertyName) = [:]
                }
                """
            } else if isArray {
                return """
                if let value = properties["\(propertyName)"] {
                    self.\(propertyName) = try \(propertyType)(value)
                } else {
                    self.\(propertyName) = []
                }
                """
            } else {
                return """
                if let value = properties["\(propertyName)"] {
                    self.\(propertyName) = try \(propertyType)(value)
                } else {
                    self.\(propertyName) = try \(propertyType)(GeneratedContent("{}"))
                }
                """
            }
        }
    }
    
    private static func generateGeneratedContentProperty(structName: String, description: String?, properties: [PropertyInfo]) -> DeclSyntax {
        let propertyConversions = properties.map { prop in
            let propName = prop.name
            let propType = prop.type
            
            if propType.hasSuffix("?") {
                let baseType = String(propType.dropLast()) // Remove "?"
                if baseType == "String" {
                    return "properties[\"\(propName)\"] = \(propName).map { GeneratedContent($0) } ?? GeneratedContent(kind: .null)"
                } else if baseType == "Int" || baseType == "Double" || baseType == "Float" || baseType == "Bool" || baseType == "Decimal" {
                    return "properties[\"\(propName)\"] = \(propName).map { $0.generatedContent } ?? GeneratedContent(kind: .null)"
                } else if isDictionaryType(baseType) {
                    // Handle optional dictionary types
                    return "properties[\"\(propName)\"] = \(propName).map { $0.generatedContent } ?? GeneratedContent(kind: .null)"
                } else if baseType.hasPrefix("[") && baseType.hasSuffix("]") {
                    return "properties[\"\(propName)\"] = \(propName).map { GeneratedContent(elements: $0) } ?? GeneratedContent(kind: .null)"
                } else {
                    return """
                    if let value = \(propName) {
                                properties["\(propName)"] = value.generatedContent
                            } else {
                                properties["\(propName)"] = GeneratedContent(kind: .null)
                            }
                    """
                }
            } else if isDictionaryType(propType) {
                // Handle non-optional dictionary types
                return "properties[\"\(propName)\"] = \(propName).generatedContent"
            } else if propType.hasPrefix("[") && propType.hasSuffix("]") {
                let elementType = String(propType.dropFirst().dropLast())
                if elementType == "String" {
                    return "properties[\"\(propName)\"] = GeneratedContent(elements: \(propName))"
                } else if elementType == "Int" || elementType == "Double" || elementType == "Bool" || elementType == "Float" || elementType == "Decimal" {
                    return "properties[\"\(propName)\"] = GeneratedContent(elements: \(propName))"
                } else {
                    return "properties[\"\(propName)\"] = GeneratedContent(elements: \(propName))"
                }
            } else {
                switch propType {
                case "String":
                    return "properties[\"\(propName)\"] = GeneratedContent(\(propName))"
                case "Int", "Double", "Float", "Bool", "Decimal":
                    return "properties[\"\(propName)\"] = \(propName).generatedContent"
                default:
                    return "properties[\"\(propName)\"] = \(propName).generatedContent"
                }
            }
        }.joined(separator: "\n            ")
        
        let orderedKeys = properties.map { "\"\($0.name)\"" }.joined(separator: ", ")
        
        if properties.isEmpty {
            // For empty structs, use let since properties won't be modified
            return DeclSyntax(stringLiteral: """
            public var generatedContent: GeneratedContent {
                let properties: [String: GeneratedContent] = [:]
                
                return GeneratedContent(
                    kind: .structure(
                        properties: properties,
                        orderedKeys: []
                    )
                )
            }
            """)
        } else {
            return DeclSyntax(stringLiteral: """
            public var generatedContent: GeneratedContent {
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
    }
    
    private static func generateFromGeneratedContentMethod(structName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public static func from(generatedContent: GeneratedContent) throws -> \(structName) {
            return try \(structName)(generatedContent)
        }
        """)
    }
    
    private static func generateToGeneratedContentMethod() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public func toGeneratedContent() -> GeneratedContent {
            return self.generatedContent
        }
        """)
    }
    
    private static func generateGenerationSchemaProperty(structName: String, description: String?, properties: [PropertyInfo]) -> DeclSyntax {
        let propertyDefinitions = properties.map { prop in
            let descriptionParam = prop.guideDescription.map { "description: \"\($0)\"" } ?? "description: nil"
            
            let typeParam: String
            let isOptional = prop.type.hasSuffix("?")
            switch prop.type {
            case "String":
                typeParam = "String.self"
            case "String?":
                typeParam = "String?.self"
            case "Int":
                typeParam = "Int.self"
            case "Int?":
                typeParam = "Int?.self"
            case "Double":
                typeParam = "Double.self"
            case "Double?":
                typeParam = "Double?.self"
            case "Float":
                typeParam = "Float.self"
            case "Float?":
                typeParam = "Float?.self"
            case "Bool":
                typeParam = "Bool.self"
            case "Bool?":
                typeParam = "Bool?.self"
            default:
                if isOptional {
                    typeParam = "\(prop.type).self"
                } else {
                    typeParam = "\(prop.type).self"
                }
            }
            
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
    
    private static func generateAsPartiallyGeneratedMethod(structName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public func asPartiallyGenerated() -> PartiallyGenerated {
            return try! PartiallyGenerated(self._rawGeneratedContent)
        }
        """)
    }
    
    private static func generateAsPartiallyGeneratedMethodForEnum(enumName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public func asPartiallyGenerated() -> PartiallyGenerated {
            return try! PartiallyGenerated(self.generatedContent)
        }
        """)
    }
    
    private static func generatePartiallyGeneratedStruct(structName: String, properties: [PropertyInfo]) -> DeclSyntax {
        let optionalProperties = properties.map { prop in
            let propertyType = prop.type
            if propertyType.hasSuffix("?") {
                return "public let \(prop.name): \(propertyType)"
            } else {
                return "public let \(prop.name): \(propertyType)?"
            }
        }.joined(separator: "\n        ")
        
        let propertyExtractions = properties.map { prop in
            generatePartialPropertyExtraction(propertyName: prop.name, propertyType: prop.type)
        }.joined(separator: "\n            ")
        
        return DeclSyntax(stringLiteral: """
        public struct PartiallyGenerated: Sendable, ConvertibleFromGeneratedContent {
            \(optionalProperties)
            
            private let rawContent: GeneratedContent
            
            public init(_ generatedContent: GeneratedContent) throws {
                self.rawContent = generatedContent
                
                if \(properties.isEmpty ? "let _ = try? generatedContent.properties()" : "let properties = try? generatedContent.properties()") {
                    \(propertyExtractions)
                } else {
                    \(properties.map { "self.\($0.name) = nil" }.joined(separator: "\n                    "))
                }
            }
            
            public var generatedContent: GeneratedContent {
                return rawContent
            }
        }
        """)
    }
    
    private static func generateInstructionsRepresentationProperty() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public var instructionsRepresentation: Instructions {
            return Instructions(self.generatedContent.text)
        }
        """)
    }
    
    private static func generatePromptRepresentationProperty() -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public var promptRepresentation: Prompt {
            return Prompt(self.generatedContent.text)
        }
        """)
    }
    
    
    private static func extractEnumCases(from enumDecl: EnumDeclSyntax) -> [EnumCaseInfo] {
        var cases: [EnumCaseInfo] = []
        
        for member in enumDecl.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    let caseName = element.name.text
                    var associatedValues: [(label: String?, type: String)] = []
                    
                    if let parameterClause = element.parameterClause {
                        for parameter in parameterClause.parameters {
                            let label = parameter.firstName?.text
                            let type = parameter.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                            associatedValues.append((label: label, type: type))
                        }
                    }
                    
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
    
    private static func generateEnumInitFromGeneratedContent(enumName: String, cases: [EnumCaseInfo]) -> DeclSyntax {
        let hasAnyAssociatedValues = cases.contains { $0.hasAssociatedValues }
        
        if hasAnyAssociatedValues {
            let switchCases = cases.map { enumCase in
                if enumCase.associatedValues.isEmpty {
                    return """
                    case "\(enumCase.name)":
                        self = .\(enumCase.name)
                    """
                } else if enumCase.isSingleUnlabeledValue {
                    let valueType = enumCase.associatedValues[0].type
                    return generateSingleValueCase(caseName: enumCase.name, valueType: valueType)
                } else {
                    return generateMultipleValueCase(caseName: enumCase.name, associatedValues: enumCase.associatedValues)
                }
            }.joined(separator: "\n                ")
            
            return DeclSyntax(stringLiteral: """
            public init(_ generatedContent: GeneratedContent) throws {
                
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
            let switchCases = cases.map { enumCase in
                "case \"\(enumCase.name)\": self = .\(enumCase.name)"
            }.joined(separator: "\n            ")
            
            return DeclSyntax(stringLiteral: """
            public init(_ generatedContent: GeneratedContent) throws {
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
    
    private static func generateEnumGeneratedContentProperty(enumName: String, description: String?, cases: [EnumCaseInfo]) -> DeclSyntax {
        let hasAnyAssociatedValues = cases.contains { $0.hasAssociatedValues }
        
        if hasAnyAssociatedValues {
            let switchCases = cases.map { enumCase in
                if enumCase.associatedValues.isEmpty {
                    return """
                    case .\(enumCase.name):
                        return GeneratedContent(properties: [
                            "case": GeneratedContent("\(enumCase.name)"),
                            "value": GeneratedContent("")
                        ])
                    """
                } else if enumCase.isSingleUnlabeledValue {
                    return """
                    case .\\(enumCase.name)(let value):
                        return GeneratedContent(properties: [
                            "case": GeneratedContent("\\(enumCase.name)"),
                            "value": GeneratedContent("\\\\(value)")
                        ])
                    """
                } else {
                    return generateMultipleValueSerialization(caseName: enumCase.name, associatedValues: enumCase.associatedValues)
                }
            }.joined(separator: "\n            ")
            
            return DeclSyntax(stringLiteral: """
            public var generatedContent: GeneratedContent {
                switch self {
                \(switchCases)
                }
            }
            """)
        } else {
            let switchCases = cases.map { enumCase in
                "case .\(enumCase.name): return GeneratedContent(\"\(enumCase.name)\")"
            }.joined(separator: "\n            ")
            
            return DeclSyntax(stringLiteral: """
            public var generatedContent: GeneratedContent {
                switch self {
                \(switchCases)
                }
            }
            """)
        }
    }
    
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
            return """
            case .\(caseName)(let value):
                return GeneratedContent(properties: [
                    "case": GeneratedContent("\(caseName)"),
                    "value": value.generatedContent
                ])
            """
        }
    }
    
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
    
    private static func generateEnumFromGeneratedContentMethod(enumName: String) -> DeclSyntax {
        return DeclSyntax(stringLiteral: """
        public static func from(generatedContent: GeneratedContent) throws -> \(enumName) {
            return try \(enumName)(generatedContent)
        }
        """)
    }
    
    private static func generateEnumGenerationSchemaProperty(enumName: String, description: String?, cases: [EnumCaseInfo]) -> DeclSyntax {
        let hasAnyAssociatedValues = cases.contains { $0.hasAssociatedValues }
        
        if hasAnyAssociatedValues {
            
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
                
                return GenerationSchema(
                    type: Self.self,
                    description: \(description.map { "\"\($0)\"" } ?? "\"Generated \(enumName)\""),
                    properties: [
                        \(caseProperty),
                        \(valueProperty)
                    ]
                )
            }
            """)
        } else {
            let caseNames = cases.map { "\"\($0.name)\"" }.joined(separator: ", ")
            
            return DeclSyntax(stringLiteral: """
            public static var generationSchema: GenerationSchema {
                
                return GenerationSchema(
                    type: Self.self,
                    description: \(description.map { "\"\($0)\"" } ?? "\"Generated \(enumName)\""),
                    anyOf: [\(caseNames)]
                )
            }
            """)
        }
    }
    
    
}

public struct GuideMacro: PeerMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}


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


@main
struct OpenFoundationModelsMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GenerableMacro.self,
        GuideMacro.self
    ]
}