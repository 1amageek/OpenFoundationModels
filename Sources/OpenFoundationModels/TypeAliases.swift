import Foundation
@_exported @_spi(Internal) import Generation

public typealias Response = LanguageModelSession.Response
public typealias ResponseStream = LanguageModelSession.ResponseStream
public typealias GenerationError = LanguageModelSession.GenerationError
public typealias ToolCallError = LanguageModelSession.ToolCallError
public typealias ToolCall = Transcript.ToolCall
public typealias ToolCalls = Transcript.ToolCalls
public typealias Availability = AvailabilityStatus