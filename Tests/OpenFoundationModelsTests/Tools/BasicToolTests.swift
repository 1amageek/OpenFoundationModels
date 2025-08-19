
import Foundation
import Testing
@testable import OpenFoundationModels
import OpenFoundationModelsMacros

@Suite("Basic Tool Tests")
struct BasicToolTests {
    
    
    struct SimpleWeatherTool: Tool {
        let description = "Get weather information for a city"
        
        @Generable
        struct Arguments {
            let city: String
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
    
    struct CalculatorTool: Tool {
        let name = "calculate"
        let description = "Perform basic mathematical calculations"
        
        @Generable
        struct Arguments {
            let expression: String
        }
        
        typealias Output = String
        
        func call(arguments: Arguments) async throws -> String {
            if arguments.expression.contains("/0") {
                throw LanguageModelSession.ToolCallError(
                    tool: CalculatorTool(),
                    underlyingError: NSError(
                        domain: "CalculateError",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "Division by zero"]
                    )
                )
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
    
    
    @Test("Tool protocol properties work")
    func toolProtocolProperties() {
        let tool = SimpleWeatherTool()
        
        #expect(!tool.description.isEmpty)
        #expect(tool.description == "Get weather information for a city")
        #expect(tool.name == "SimpleWeatherTool") // Default name
        #expect(tool.includesSchemaInInstructions == true) // Default value
        let debugString = tool.parameters.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
    
    @Test("Tool custom name works")
    func toolCustomName() {
        let tool = CalculatorTool()
        
        #expect(tool.name == "calculate")
        #expect(tool.description == "Perform basic mathematical calculations")
    }
    
    @Test("Tool with String arguments")
    func toolWithStringArguments() {
        let tool = StringArgumentTool()
        
        let debugString = tool.parameters.debugDescription
        #expect(debugString.contains("GenerationSchema"))
        #expect(tool.description == "Process string input")
    }
    
    
    @Test("Basic tool execution")
    func basicToolExecution() async throws {
        let tool = SimpleWeatherTool()
        let content = GeneratedContent(properties: ["city": "Tokyo"])
        let args = try SimpleWeatherTool.Arguments(content)
        
        let result = try await tool.call(arguments: args)
        
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
        let content = GeneratedContent(properties: ["expression": "10/0"])
        let args = try CalculatorTool.Arguments(content)
        
        do {
            let _ = try await tool.call(arguments: args)
            Issue.record("Expected error to be thrown")
        } catch let error as LanguageModelSession.ToolCallError {
            #expect(error.tool.name == "calculate")
            #expect(error.underlyingError.localizedDescription.contains("Division by zero"))
        } catch {
            Issue.record("Wrong error type thrown: \(error)")
        }
    }
    
    @Test("Tool successful calculation")
    func toolSuccessfulCalculation() async throws {
        let tool = CalculatorTool()
        let content = GeneratedContent(properties: ["expression": "2 + 2"])
        let args = try CalculatorTool.Arguments(content)
        
        let result = try await tool.call(arguments: args)
        let data = result.data(using: .utf8)!
        let calculation = try JSONDecoder().decode(CalculationResult.self, from: data)
        
        #expect(calculation.expression == "2 + 2")
        #expect(calculation.result == 42.0)
        #expect(calculation.success == true)
    }
    
    
    
    @Test("Tool types are Sendable")
    func toolSendableConformance() {
        let weatherTool = SimpleWeatherTool()
        let calculatorTool = CalculatorTool()
        let stringTool = StringArgumentTool()
        
        let _ = weatherTool as Sendable
        let _ = calculatorTool as Sendable
        let _ = stringTool as Sendable
    }
    
    
    
    @Test("Concurrent tool execution")
    func concurrentToolExecution() async throws {
        let tool = SimpleWeatherTool()
        
        async let result1 = try SimpleWeatherTool.Arguments(GeneratedContent(properties: ["city": "Tokyo"]))
        async let result2 = try SimpleWeatherTool.Arguments(GeneratedContent(properties: ["city": "London"]))
        async let result3 = try SimpleWeatherTool.Arguments(GeneratedContent(properties: ["city": "Paris"]))
        
        let args = try await [result1, result2, result3]
        
        async let weather1 = tool.call(arguments: args[0])
        async let weather2 = tool.call(arguments: args[1])
        async let weather3 = tool.call(arguments: args[2])
        
        let outputs = try await [weather1, weather2, weather3]
        
        #expect(outputs.count == 3)
        
        let cities = try outputs.map { output in
            let data = output.data(using: .utf8)!
            return try JSONDecoder().decode(WeatherInfo.self, from: data).city
        }
        #expect(cities.contains("Tokyo"))
        #expect(cities.contains("London"))
        #expect(cities.contains("Paris"))
    }
    
    
    // Move EmptyArgumentsTool outside of test function
    struct EmptyArgumentsTool: Tool {
        let description = "Tool with no meaningful arguments"
        
        @Generable
        struct Arguments {
            // Empty arguments struct
        }
        
        typealias Output = String
        
        func call(arguments: Arguments) async throws -> String {
            let result = SimpleResult(output: "executed")
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            return String(data: data, encoding: .utf8) ?? "{}"
        }
    }
    
    @Test("Tool with empty arguments")
    func toolWithEmptyArguments() async throws {
        let tool = EmptyArgumentsTool()
        let args = try EmptyArgumentsTool.Arguments(GeneratedContent(properties: [:]))
        
        let result = try await tool.call(arguments: args)
        let data = result.data(using: .utf8)!
        let output = try JSONDecoder().decode(SimpleResult.self, from: data)
        
        #expect(output.output == "executed")
    }
    
    @Test("Tool parameter schema for non-Generable arguments")
    func toolParametersForCustomArguments() {
        let tool = SimpleWeatherTool()
        
        let schema = tool.parameters
        let debugString = schema.debugDescription
        #expect(debugString.contains("GenerationSchema"))
    }
}