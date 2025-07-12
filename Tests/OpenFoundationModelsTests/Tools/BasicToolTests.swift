// BasicToolTests.swift
// OpenFoundationModelsTests
//
// ✅ APPLE OFFICIAL: Tests for Apple Foundation Models Tool system (simplified)

import Foundation
import Testing
@testable import OpenFoundationModels

/// Basic tests for Tool protocol and implementation
/// 
/// **Focus:** Validates Tool protocol conformance, default implementations,
/// and tool execution without relying on @Generable macro.
///
/// **Apple Foundation Models Documentation:**
/// Tools allow models to call code to gather information or perform side effects.
/// Tests ensure proper tool definition, argument handling, and execution.
///
/// **Reference:** https://developer.apple.com/documentation/foundationmodels/tool
@Suite("Basic Tool Tests")
struct BasicToolTests {
    
    // MARK: - Test Tools (Manual Conformance)
    
    /// Simple test tool with string arguments
    struct SimpleWeatherTool: Tool {
        let description = "Get weather information for a city"
        
        struct Arguments: ConvertibleFromGeneratedContent {
            let city: String
            
            static func from(generatedContent: GeneratedContent) throws -> Arguments {
                // Simple implementation - parse city from content
                let content = generatedContent.stringValue
                return Arguments(city: content.isEmpty ? "Unknown" : content)
            }
            
            private init(city: String) {
                self.city = city
            }
        }
        
        func call(arguments: Arguments) async throws -> ToolOutput {
            let weather = WeatherInfo(
                city: arguments.city,
                temperature: 22,
                condition: "sunny"
            )
            return ToolOutput(weather)
        }
    }
    
    /// Calculator tool with error handling
    struct CalculatorTool: Tool {
        let name = "calculate"
        let description = "Perform basic mathematical calculations"
        
        struct Arguments: ConvertibleFromGeneratedContent {
            let expression: String
            
            static func from(generatedContent: GeneratedContent) throws -> Arguments {
                return Arguments(expression: generatedContent.stringValue)
            }
            
            private init(expression: String) {
                self.expression = expression
            }
        }
        
        func call(arguments: Arguments) async throws -> ToolOutput {
            // Simple calculator logic
            if arguments.expression.contains("/0") {
                throw ToolCallError.invalidArguments(toolName: "calculate", reason: "Division by zero")
            }
            
            let result = CalculationResult(
                expression: arguments.expression,
                result: 42.0,
                success: true
            )
            return ToolOutput(result)
        }
    }
    
    /// Tool that uses String as arguments (built-in Generable)
    struct StringArgumentTool: Tool {
        let description = "Process string input"
        
        typealias Arguments = String
        
        func call(arguments: String) async throws -> ToolOutput {
            let result = SimpleResult(output: "Processed: \(arguments)")
            return ToolOutput(result)
        }
    }
    
    // MARK: - Supporting Types
    
    struct WeatherInfo: Codable {
        let city: String
        let temperature: Int
        let condition: String
    }
    
    struct CalculationResult: Codable {
        let expression: String
        let result: Double
        let success: Bool
    }
    
    struct SimpleResult: Codable {
        let output: String
    }
    
    // MARK: - Basic Tool Protocol Tests
    
    @Test("Tool protocol properties work")
    func toolProtocolProperties() {
        let tool = SimpleWeatherTool()
        
        // Required properties exist and have expected values
        #expect(!tool.description.isEmpty)
        #expect(tool.description == "Get weather information for a city")
        #expect(tool.name == "SimpleWeatherTool") // Default name
        #expect(tool.includesSchemaInInstructions == true) // Default value
        #expect(tool.parameters.type == "string") // Default for non-Generable
    }
    
    @Test("Tool custom name works")
    func toolCustomName() {
        let tool = CalculatorTool()
        
        // Custom name should override default
        #expect(tool.name == "calculate")
        #expect(tool.description == "Perform basic mathematical calculations")
    }
    
    @Test("Tool with String arguments")
    func toolWithStringArguments() {
        let tool = StringArgumentTool()
        
        // String is built-in Generable type
        #expect(tool.parameters.type == "string")
        #expect(tool.description == "Process string input")
    }
    
    // MARK: - Tool Execution Tests
    
    @Test("Basic tool execution")
    func basicToolExecution() async throws {
        let tool = SimpleWeatherTool()
        let content = GeneratedContent("Tokyo")
        let args = try SimpleWeatherTool.Arguments.from(generatedContent: content)
        
        let result = try await tool.call(arguments: args)
        
        // Verify result can be decoded
        let weather = try result.decode(as: WeatherInfo.self)
        #expect(weather.city == "Tokyo")
        #expect(weather.temperature == 22)
        #expect(weather.condition == "sunny")
    }
    
    @Test("Tool execution with String arguments")
    func toolExecutionWithString() async throws {
        let tool = StringArgumentTool()
        let args = "test input"
        
        let result = try await tool.call(arguments: args)
        let output = try result.decode(as: SimpleResult.self)
        
        #expect(output.output == "Processed: test input")
    }
    
    @Test("Tool error handling")
    func toolErrorHandling() async throws {
        let tool = CalculatorTool()
        let content = GeneratedContent("10/0")
        let args = try CalculatorTool.Arguments.from(generatedContent: content)
        
        // Should throw error for division by zero
        do {
            let _ = try await tool.call(arguments: args)
            Issue.record("Expected error to be thrown")
        } catch let error as ToolCallError {
            #expect(error.toolName == "calculate")
            #expect(error.errorType == .invalidArguments)
            #expect(error.localizedDescription.contains("Division by zero"))
        } catch {
            Issue.record("Wrong error type thrown: \(error)")
        }
    }
    
    @Test("Tool successful calculation")
    func toolSuccessfulCalculation() async throws {
        let tool = CalculatorTool()
        let content = GeneratedContent("2 + 2")
        let args = try CalculatorTool.Arguments.from(generatedContent: content)
        
        let result = try await tool.call(arguments: args)
        let calculation = try result.decode(as: CalculationResult.self)
        
        #expect(calculation.expression == "2 + 2")
        #expect(calculation.result == 42.0)
        #expect(calculation.success == true)
    }
    
    // MARK: - ToolOutput Tests
    
    @Test("ToolOutput creation and decoding")
    func toolOutputCreationDecoding() throws {
        let weather = WeatherInfo(city: "London", temperature: 15, condition: "rainy")
        let output = ToolOutput(weather)
        
        // Should be able to decode back to original type
        let decoded = try output.decode(as: WeatherInfo.self)
        #expect(decoded.city == "London")
        #expect(decoded.temperature == 15)
        #expect(decoded.condition == "rainy")
    }
    
    @Test("ToolOutput from GeneratedContent")
    func toolOutputFromGeneratedContent() throws {
        let content = GeneratedContent("test content")
        let output = ToolOutput.from(generatedContent: content)
        
        // Should have valid description
        #expect(!output.description.isEmpty)
        
        // Should convert back to GeneratedContent
        let converted = output.toGeneratedContent()
        #expect(converted.stringValue.contains("test content"))
    }
    
    @Test("ToolOutput description format")
    func toolOutputDescription() {
        let simple = SimpleResult(output: "test")
        let output = ToolOutput(simple)
        
        // Description should contain JSON representation
        let description = output.description
        #expect(description.contains("test"))
        #expect(description.contains("output"))
    }
    
    // MARK: - Sendable Conformance
    
    @Test("Tool types are Sendable")
    func toolSendableConformance() {
        let weatherTool = SimpleWeatherTool()
        let calculatorTool = CalculatorTool()
        let stringTool = StringArgumentTool()
        
        // Tools should conform to Sendable
        let _ = weatherTool as Sendable
        let _ = calculatorTool as Sendable
        let _ = stringTool as Sendable
    }
    
    @Test("ToolOutput is Sendable")
    func toolOutputSendableConformance() {
        let output = ToolOutput(SimpleResult(output: "test"))
        
        // ToolOutput should conform to Sendable
        let _ = output as Sendable
    }
    
    // MARK: - Concurrent Execution
    
    @Test("Concurrent tool execution")
    func concurrentToolExecution() async throws {
        let tool = SimpleWeatherTool()
        
        // Execute multiple tool calls concurrently
        async let result1 = try SimpleWeatherTool.Arguments.from(generatedContent: GeneratedContent("Tokyo"))
        async let result2 = try SimpleWeatherTool.Arguments.from(generatedContent: GeneratedContent("London"))
        async let result3 = try SimpleWeatherTool.Arguments.from(generatedContent: GeneratedContent("Paris"))
        
        let args = try await [result1, result2, result3]
        
        // Execute tool calls concurrently
        async let weather1 = tool.call(arguments: args[0])
        async let weather2 = tool.call(arguments: args[1])
        async let weather3 = tool.call(arguments: args[2])
        
        let outputs = try await [weather1, weather2, weather3]
        
        // All should complete successfully
        #expect(outputs.count == 3)
        
        let cities = try outputs.map { try $0.decode(as: WeatherInfo.self).city }
        #expect(cities.contains("Tokyo"))
        #expect(cities.contains("London"))
        #expect(cities.contains("Paris"))
    }
    
    // MARK: - Edge Cases
    
    @Test("Tool with empty arguments")
    func toolWithEmptyArguments() async throws {
        struct EmptyArgumentsTool: Tool {
            let description = "Tool with no meaningful arguments"
            
            struct Arguments: ConvertibleFromGeneratedContent {
                static func from(generatedContent: GeneratedContent) throws -> Arguments {
                    return Arguments()
                }
                
                private init() {}
            }
            
            func call(arguments: Arguments) async throws -> ToolOutput {
                return ToolOutput(SimpleResult(output: "executed"))
            }
        }
        
        let tool = EmptyArgumentsTool()
        let args = try EmptyArgumentsTool.Arguments.from(generatedContent: GeneratedContent(""))
        
        let result = try await tool.call(arguments: args)
        let output = try result.decode(as: SimpleResult.self)
        
        #expect(output.output == "executed")
    }
    
    @Test("Tool parameter schema for non-Generable arguments")
    func toolParametersForCustomArguments() {
        let tool = SimpleWeatherTool()
        
        // Should generate basic schema for ConvertibleFromGeneratedContent
        let schema = tool.parameters
        #expect(schema.type == "string")
        #expect(schema.description?.contains("SimpleWeatherTool") == true)
    }
}