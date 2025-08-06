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
            
            init(_ content: GeneratedContent) throws {
                // Simple implementation - parse city from content
                let value = content.stringValue
                self.city = value.isEmpty ? "Unknown" : value
            }
        }
        
        typealias Output = String
        
        func call(arguments: Arguments) async throws -> String {
            let weather = WeatherInfo(
                city: arguments.city,
                temperature: 22,
                condition: "sunny"
            )
            let encoder = JSONEncoder()
            let data = try encoder.encode(weather)
            return String(data: data, encoding: .utf8) ?? "{}"
        }
    }
    
    /// Calculator tool with error handling
    struct CalculatorTool: Tool {
        let name = "calculate"
        let description = "Perform basic mathematical calculations"
        
        struct Arguments: ConvertibleFromGeneratedContent {
            let expression: String
            
            init(_ content: GeneratedContent) throws {
                self.expression = content.stringValue
            }
        }
        
        typealias Output = String
        
        func call(arguments: Arguments) async throws -> String {
            // Simple calculator logic
            if arguments.expression.contains("/0") {
                throw ToolCallError.invalidArguments(toolName: "calculate", reason: "Division by zero")
            }
            
            let result = CalculationResult(
                expression: arguments.expression,
                result: 42.0,
                success: true
            )
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            return String(data: data, encoding: .utf8) ?? "{}"
        }
    }
    
    /// Tool that uses String as arguments (built-in Generable)
    struct StringArgumentTool: Tool {
        let description = "Process string input"
        
        typealias Arguments = String
        typealias Output = String
        
        func call(arguments: String) async throws -> String {
            let result = SimpleResult(output: "Processed: \(arguments)")
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            return String(data: data, encoding: .utf8) ?? "{}"
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
        // Schema type is internal, just verify schema was created
        let debugString = tool.parameters.debugDescription
        #expect(debugString.contains("GenerationSchema"))
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
        
        // String is built-in Generable type, but Swift type system limitations
        // prevent proper detection when used as typealias Arguments = String
        // Schema type is internal, just verify schema was created
        let debugString = tool.parameters.debugDescription
        #expect(debugString.contains("GenerationSchema"))
        #expect(tool.description == "Process string input")
    }
    
    // MARK: - Tool Execution Tests
    
    @Test("Basic tool execution")
    func basicToolExecution() async throws {
        let tool = SimpleWeatherTool()
        let content = GeneratedContent("Tokyo")
        let args = try SimpleWeatherTool.Arguments(content)
        
        let result = try await tool.call(arguments: args)
        
        // Verify result can be decoded
        let data = result.data(using: .utf8)!
        let weather = try JSONDecoder().decode(WeatherInfo.self, from: data)
        #expect(weather.city == "Tokyo")
        #expect(weather.temperature == 22)
        #expect(weather.condition == "sunny")
    }
    
    @Test("Tool execution with String arguments")
    func toolExecutionWithString() async throws {
        let tool = StringArgumentTool()
        let args = "test input"
        
        let result = try await tool.call(arguments: args)
        let data = result.data(using: .utf8)!
        let output = try JSONDecoder().decode(SimpleResult.self, from: data)
        
        #expect(output.output == "Processed: test input")
    }
    
    @Test("Tool error handling")
    func toolErrorHandling() async throws {
        let tool = CalculatorTool()
        let content = GeneratedContent("10/0")
        let args = try CalculatorTool.Arguments(content)
        
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
        let args = try CalculatorTool.Arguments(content)
        
        let result = try await tool.call(arguments: args)
        let data = result.data(using: .utf8)!
        let calculation = try JSONDecoder().decode(CalculationResult.self, from: data)
        
        #expect(calculation.expression == "2 + 2")
        #expect(calculation.result == 42.0)
        #expect(calculation.success == true)
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
    
    
    // MARK: - Concurrent Execution
    
    @Test("Concurrent tool execution")
    func concurrentToolExecution() async throws {
        let tool = SimpleWeatherTool()
        
        // Execute multiple tool calls concurrently
        async let result1 = try SimpleWeatherTool.Arguments(GeneratedContent("Tokyo"))
        async let result2 = try SimpleWeatherTool.Arguments(GeneratedContent("London"))
        async let result3 = try SimpleWeatherTool.Arguments(GeneratedContent("Paris"))
        
        let args = try await [result1, result2, result3]
        
        // Execute tool calls concurrently
        async let weather1 = tool.call(arguments: args[0])
        async let weather2 = tool.call(arguments: args[1])
        async let weather3 = tool.call(arguments: args[2])
        
        let outputs = try await [weather1, weather2, weather3]
        
        // All should complete successfully
        #expect(outputs.count == 3)
        
        let cities = try outputs.map { output in
            let data = output.data(using: .utf8)!
            return try JSONDecoder().decode(WeatherInfo.self, from: data).city
        }
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
                init(_ content: GeneratedContent) throws {
                    // No properties to initialize
                }
            }
            
            typealias Output = String
            
            func call(arguments: Arguments) async throws -> String {
                let result = SimpleResult(output: "executed")
                let encoder = JSONEncoder()
                let data = try encoder.encode(result)
                return String(data: data, encoding: .utf8) ?? "{}"
            }
        }
        
        let tool = EmptyArgumentsTool()
        let args = try EmptyArgumentsTool.Arguments(GeneratedContent(""))
        
        let result = try await tool.call(arguments: args)
        let data = result.data(using: .utf8)!
        let output = try JSONDecoder().decode(SimpleResult.self, from: data)
        
        #expect(output.output == "executed")
    }
    
    @Test("Tool parameter schema for non-Generable arguments")
    func toolParametersForCustomArguments() {
        let tool = SimpleWeatherTool()
        
        // Should generate basic schema for ConvertibleFromGeneratedContent
        let schema = tool.parameters
        // Schema type and description are internal, just verify schema was created
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
}