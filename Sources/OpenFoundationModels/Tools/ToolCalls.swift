// ToolCalls.swift
// OpenFoundationModels
//
// ✅ PHASE 4.6: Apple Foundation Models compliant ToolCalls structure

import Foundation

/// A collection of tool calls made by the model
/// 
/// ✅ APPLE SPEC: Tool calls collection from Apple documentation
/// - Contains array of ToolCall instances
/// - Codable for transcript serialization
/// - Collection conformance for easy iteration
public struct ToolCalls: Codable, Sendable {
    /// Array of tool calls
    /// ✅ APPLE SPEC: Required for multiple tool execution
    public let calls: [ToolCall]
    
    /// Initialize tool calls
    /// - Parameter calls: Array of tool calls
    public init(calls: [ToolCall]) {
        self.calls = calls
    }
    
    /// Initialize tool calls with a single call
    /// - Parameter call: Single tool call
    public init(_ call: ToolCall) {
        self.calls = [call]
    }
    
    /// Initialize empty tool calls
    public init() {
        self.calls = []
    }
}

// MARK: - Collection Conformance

extension ToolCalls: Collection {
    public typealias Index = Array<ToolCall>.Index
    public typealias Element = ToolCall
    
    public var startIndex: Index {
        return calls.startIndex
    }
    
    public var endIndex: Index {
        return calls.endIndex
    }
    
    public subscript(index: Index) -> Element {
        return calls[index]
    }
    
    public func index(after i: Index) -> Index {
        return calls.index(after: i)
    }
}

// MARK: - Convenience Methods

public extension ToolCalls {
    /// Get tool call by ID
    /// - Parameter id: Tool call ID
    /// - Returns: Tool call if found
    func toolCall(withId id: String) -> ToolCall? {
        return calls.first { $0.id == id }
    }
    
    /// Get tool calls by name
    /// - Parameter name: Tool name
    /// - Returns: Array of tool calls with matching name
    func toolCalls(withName name: String) -> [ToolCall] {
        return calls.filter { $0.name == name }
    }
    
    /// Check if collection is empty
    var isEmpty: Bool {
        return calls.isEmpty
    }
    
    /// Count of tool calls
    var count: Int {
        return calls.count
    }
}

// MARK: - ExpressibleByArrayLiteral

extension ToolCalls: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: ToolCall...) {
        self.calls = elements
    }
}

// MARK: - CustomStringConvertible

extension ToolCalls: CustomStringConvertible {
    public var description: String {
        return "ToolCalls(\(calls.count) calls: \(calls.map { $0.name }.joined(separator: ", ")))"
    }
}