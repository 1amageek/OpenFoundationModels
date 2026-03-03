import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsExtra
import OpenFoundationModelsCore

@Suite("ResolvedTranscript Tests")
struct ResolvedTranscriptTests {

    // MARK: - Empty

    @Test("empty transcript produces empty result")
    func emptyTranscript() {
        let converted = Transcript().resolved()
        #expect(converted.isEmpty)
        #expect(converted.toolDefinitions.isEmpty)
        #expect(converted.latestOptions == nil)
        #expect(converted.latestResponseFormat == nil)
    }

    // MARK: - Entry assignment

    @Test("instructions entry maps to .instructions")
    func instructionsEntry() {
        let instructions = Transcript.Instructions(
            segments: [.text(.init(content: "Be helpful"))],
            toolDefinitions: []
        )
        let converted = Transcript(entries: [.instructions(instructions)]).resolved()
        #expect(converted.count == 1)
        guard case .instructions(let i) = converted[0] else {
            Issue.record("Expected .instructions entry"); return
        }
        #expect(i.id == instructions.id)
    }

    @Test("prompt entry maps to .prompt")
    func promptEntry() {
        let prompt = Transcript.Prompt(segments: [.text(.init(content: "Hello"))])
        let converted = Transcript(entries: [.prompt(prompt)]).resolved()
        #expect(converted.count == 1)
        guard case .prompt(let p) = converted[0] else {
            Issue.record("Expected .prompt entry"); return
        }
        #expect(p.id == prompt.id)
    }

    @Test("response entry maps to .response")
    func responseEntry() {
        let response = Transcript.Response(id: "r1", assetIDs: [], segments: [.text(.init(content: "Hi"))])
        let converted = Transcript(entries: [.response(response)]).resolved()
        #expect(converted.count == 1)
        guard case .response(let r) = converted[0] else {
            Issue.record("Expected .response entry"); return
        }
        #expect(r.id == response.id)
    }

    // MARK: - Tool interaction

    @Test("toolCalls and toolOutput are paired into a single tool entry")
    func toolInteractionPaired() {
        let call = Transcript.ToolCall(id: "c1", toolName: "myTool", arguments: GeneratedContent(kind: .null))
        let calls = Transcript.ToolCalls([call])
        let output = Transcript.ToolOutput(id: "o1", toolName: "myTool", segments: [.text(.init(content: "result"))])
        let converted = Transcript(entries: [.toolCalls(calls), .toolOutput(output)]).resolved()

        #expect(converted.count == 1)
        guard case .tool(let interaction) = converted[0] else {
            Issue.record("Expected .tool entry"); return
        }
        #expect(interaction.calls.count == 1)
        #expect(interaction.outputs.count == 1)
        #expect(interaction.outputs[0].id == output.id)
    }

    @Test("multiple toolOutputs collected into one tool entry")
    func multipleToolOutputs() {
        let arg = GeneratedContent(kind: .null)
        let calls = Transcript.ToolCalls([
            Transcript.ToolCall(id: "c1", toolName: "t1", arguments: arg),
            Transcript.ToolCall(id: "c2", toolName: "t2", arguments: arg),
        ])
        let out1 = Transcript.ToolOutput(id: "o1", toolName: "t1", segments: [])
        let out2 = Transcript.ToolOutput(id: "o2", toolName: "t2", segments: [])
        let converted = Transcript(entries: [.toolCalls(calls), .toolOutput(out1), .toolOutput(out2)]).resolved()

        #expect(converted.count == 1)
        guard case .tool(let interaction) = converted[0] else {
            Issue.record("Expected .tool entry"); return
        }
        #expect(interaction.calls.count == 2)
        #expect(interaction.outputs.count == 2)
    }

    @Test("toolCalls without outputs flushes as tool entry with empty outputs")
    func toolCallsWithoutOutputs() {
        let calls = Transcript.ToolCalls([
            Transcript.ToolCall(id: "c1", toolName: "t1", arguments: GeneratedContent(kind: .null))
        ])
        let converted = Transcript(entries: [.toolCalls(calls)]).resolved()

        #expect(converted.count == 1)
        guard case .tool(let interaction) = converted[0] else {
            Issue.record("Expected .tool entry"); return
        }
        #expect(interaction.outputs.isEmpty)
    }

    @Test("toolCalls is flushed when next non-output entry arrives")
    func toolCallsFlushedOnNextEntry() {
        let calls = Transcript.ToolCalls([
            Transcript.ToolCall(id: "c1", toolName: "t1", arguments: GeneratedContent(kind: .null))
        ])
        let out = Transcript.ToolOutput(id: "o1", toolName: "t1", segments: [])
        let prompt = Transcript.Prompt(segments: [.text(.init(content: "follow-up"))])
        let converted = Transcript(entries: [.toolCalls(calls), .toolOutput(out), .prompt(prompt)]).resolved()

        #expect(converted.count == 2)
        guard case .tool(let interaction) = converted[0] else {
            Issue.record("Expected .tool entry at index 0"); return
        }
        #expect(interaction.outputs.count == 1)
        guard case .prompt = converted[1] else {
            Issue.record("Expected .prompt entry at index 1"); return
        }
    }

    @Test("orphaned toolOutput without preceding toolCalls is ignored")
    func orphanedToolOutputIgnored() {
        let output = Transcript.ToolOutput(id: "o1", toolName: "t1", segments: [])
        let converted = Transcript(entries: [.toolOutput(output)]).resolved()
        #expect(converted.isEmpty)
    }

    // MARK: - Tool definitions

    @Test("tool definitions extracted from instructions")
    func toolDefinitionsExtracted() {
        let schema = GenerationSchema(type: String.self, description: "arg", properties: [])
        let tool = Transcript.ToolDefinition(name: "myTool", description: "does stuff", parameters: schema)
        let instructions = Transcript.Instructions(segments: [], toolDefinitions: [tool])
        let converted = Transcript(entries: [.instructions(instructions)]).resolved()

        #expect(converted.toolDefinitions.count == 1)
        #expect(converted.toolDefinitions[0].name == "myTool")
    }

    @Test("later instructions overwrites tool definitions")
    func toolDefinitionsOverwrittenByLaterInstructions() {
        let schema = GenerationSchema(type: String.self, description: "arg", properties: [])
        let i1 = Transcript.Instructions(segments: [], toolDefinitions: [
            Transcript.ToolDefinition(name: "tool1", description: "first", parameters: schema)
        ])
        let i2 = Transcript.Instructions(segments: [], toolDefinitions: [
            Transcript.ToolDefinition(name: "tool2", description: "second", parameters: schema)
        ])
        let converted = Transcript(entries: [.instructions(i1), .instructions(i2)]).resolved()

        #expect(converted.toolDefinitions.count == 1)
        #expect(converted.toolDefinitions[0].name == "tool2")
    }

    @Test("empty tool definitions in later instructions clears previous tools")
    func emptyToolDefinitionsClearsPrevious() {
        let schema = GenerationSchema(type: String.self, description: "arg", properties: [])
        let i1 = Transcript.Instructions(segments: [], toolDefinitions: [
            Transcript.ToolDefinition(name: "tool1", description: "first", parameters: schema)
        ])
        let i2 = Transcript.Instructions(segments: [], toolDefinitions: [])
        let converted = Transcript(entries: [.instructions(i1), .instructions(i2)]).resolved()

        #expect(converted.toolDefinitions.isEmpty)
    }

    // MARK: - Latest options

    @Test("latestOptions reflects most recent prompt")
    func latestOptionsFromMostRecentPrompt() {
        let p1 = Transcript.Prompt(segments: [], options: GenerationOptions(temperature: 0.1))
        let p2 = Transcript.Prompt(segments: [], options: GenerationOptions(temperature: 0.9))
        let converted = Transcript(entries: [.prompt(p1), .prompt(p2)]).resolved()

        #expect(converted.latestOptions?.temperature == 0.9)
    }

    @Test("latestOptions is nil when transcript has no prompts")
    func latestOptionsNilWithoutPrompts() {
        let instructions = Transcript.Instructions(segments: [], toolDefinitions: [])
        let converted = Transcript(entries: [.instructions(instructions)]).resolved()

        #expect(converted.latestOptions == nil)
    }

    // MARK: - Latest response format

    @Test("latestResponseFormat reflects most recent prompt with responseFormat")
    func latestResponseFormatSet() {
        let schema = GenerationSchema(type: String.self, description: "resp", properties: [])
        let format = Transcript.ResponseFormat(schema: schema)
        let prompt = Transcript.Prompt(segments: [], responseFormat: format)
        let converted = Transcript(entries: [.prompt(prompt)]).resolved()

        #expect(converted.latestResponseFormat != nil)
        #expect(converted.latestResponseFormat?.name == format.name)
    }

    @Test("latestResponseFormat is nil when latest prompt has no responseFormat")
    func latestResponseFormatNilWhenLatestPromptHasNone() {
        let schema = GenerationSchema(type: String.self, description: "resp", properties: [])
        let format = Transcript.ResponseFormat(schema: schema)
        let p1 = Transcript.Prompt(segments: [], responseFormat: format)
        let p2 = Transcript.Prompt(segments: [])
        let converted = Transcript(entries: [.prompt(p1), .prompt(p2)]).resolved()

        #expect(converted.latestResponseFormat == nil)
    }

    // MARK: - Consecutive toolCalls

    @Test("consecutive toolCalls each produce a separate tool entry")
    func consecutiveToolCallsWithoutOutputs() {
        let arg = GeneratedContent(kind: .null)
        let calls1 = Transcript.ToolCalls(id: "tc1", [Transcript.ToolCall(id: "c1", toolName: "t1", arguments: arg)])
        let calls2 = Transcript.ToolCalls(id: "tc2", [Transcript.ToolCall(id: "c2", toolName: "t2", arguments: arg)])
        let converted = Transcript(entries: [.toolCalls(calls1), .toolCalls(calls2)]).resolved()

        #expect(converted.count == 2)
        guard case .tool(let i1) = converted[0] else { Issue.record("entry[0] should be .tool"); return }
        guard case .tool(let i2) = converted[1] else { Issue.record("entry[1] should be .tool"); return }
        #expect(i1.calls.id == calls1.id)
        #expect(i1.outputs.isEmpty)
        #expect(i2.calls.id == calls2.id)
        #expect(i2.outputs.isEmpty)
    }

    @Test("toolOutput after consecutive toolCalls attaches only to the last toolCalls")
    func consecutiveToolCallsOutputAttachesToLast() {
        let arg = GeneratedContent(kind: .null)
        let calls1 = Transcript.ToolCalls(id: "tc1", [Transcript.ToolCall(id: "c1", toolName: "t1", arguments: arg)])
        let calls2 = Transcript.ToolCalls(id: "tc2", [Transcript.ToolCall(id: "c2", toolName: "t2", arguments: arg)])
        let out = Transcript.ToolOutput(id: "o1", toolName: "t2", segments: [])
        let converted = Transcript(entries: [.toolCalls(calls1), .toolCalls(calls2), .toolOutput(out)]).resolved()

        #expect(converted.count == 2)
        guard case .tool(let i1) = converted[0] else { Issue.record("entry[0] should be .tool"); return }
        guard case .tool(let i2) = converted[1] else { Issue.record("entry[1] should be .tool"); return }
        #expect(i1.outputs.isEmpty)
        #expect(i2.outputs.count == 1)
        #expect(i2.outputs[0].id == out.id)
    }

    // MARK: - Multi-round agent patterns

    @Test("two tool rounds followed by response produce correct entry sequence")
    func twoToolRoundsFollowedByResponse() {
        let arg = GeneratedContent(kind: .null)
        let inst = Transcript.Instructions(segments: [], toolDefinitions: [])
        let p1 = Transcript.Prompt(segments: [.text(.init(content: "query"))])
        let calls1 = Transcript.ToolCalls([Transcript.ToolCall(id: "c1", toolName: "t1", arguments: arg)])
        let out1 = Transcript.ToolOutput(id: "o1", toolName: "t1", segments: [])
        let calls2 = Transcript.ToolCalls([
            Transcript.ToolCall(id: "c2a", toolName: "t2", arguments: arg),
            Transcript.ToolCall(id: "c2b", toolName: "t3", arguments: arg),
        ])
        let out2a = Transcript.ToolOutput(id: "o2a", toolName: "t2", segments: [])
        let out2b = Transcript.ToolOutput(id: "o2b", toolName: "t3", segments: [])
        let response = Transcript.Response(id: "r1", assetIDs: [], segments: [])

        let converted = Transcript(entries: [
            .instructions(inst),
            .prompt(p1),
            .toolCalls(calls1),
            .toolOutput(out1),
            .toolCalls(calls2),
            .toolOutput(out2a),
            .toolOutput(out2b),
            .response(response),
        ]).resolved()

        #expect(converted.count == 5)
        guard case .instructions = converted[0] else { Issue.record("entry[0] should be .instructions"); return }
        guard case .prompt        = converted[1] else { Issue.record("entry[1] should be .prompt"); return }
        guard case .tool(let ia)  = converted[2] else { Issue.record("entry[2] should be .tool"); return }
        guard case .tool(let ib)  = converted[3] else { Issue.record("entry[3] should be .tool"); return }
        guard case .response      = converted[4] else { Issue.record("entry[4] should be .response"); return }
        #expect(ia.outputs.count == 1)
        #expect(ib.outputs.count == 2)
    }

    @Test("latestOptions reflects last prompt across multiple tool rounds")
    func latestOptionsAcrossToolRounds() {
        let arg = GeneratedContent(kind: .null)
        let p1 = Transcript.Prompt(segments: [], options: GenerationOptions(temperature: 0.3))
        let calls1 = Transcript.ToolCalls([Transcript.ToolCall(id: "c1", toolName: "t1", arguments: arg)])
        let out1 = Transcript.ToolOutput(id: "o1", toolName: "t1", segments: [])
        let p2 = Transcript.Prompt(segments: [], options: GenerationOptions(temperature: 0.8))
        let calls2 = Transcript.ToolCalls([Transcript.ToolCall(id: "c2", toolName: "t2", arguments: arg)])
        let out2 = Transcript.ToolOutput(id: "o2", toolName: "t2", segments: [])
        let response = Transcript.Response(id: "r1", assetIDs: [], segments: [])

        let converted = Transcript(entries: [
            .prompt(p1),
            .toolCalls(calls1), .toolOutput(out1),
            .prompt(p2),
            .toolCalls(calls2), .toolOutput(out2),
            .response(response),
        ]).resolved()

        #expect(converted.count == 5)
        #expect(converted.latestOptions?.temperature == 0.8)
    }

    // MARK: - Mid-conversation instructions

    @Test("instructions mid-conversation produces two instructions entries with updated toolDefinitions")
    func instructionsReplacedMidConversation() {
        let schema = GenerationSchema(type: String.self, description: "arg", properties: [])
        let i1 = Transcript.Instructions(segments: [], toolDefinitions: [
            Transcript.ToolDefinition(name: "tool1", description: "first", parameters: schema)
        ])
        let p1 = Transcript.Prompt(segments: [])
        let i2 = Transcript.Instructions(segments: [], toolDefinitions: [
            Transcript.ToolDefinition(name: "tool2", description: "second", parameters: schema)
        ])
        let p2 = Transcript.Prompt(segments: [])

        let converted = Transcript(entries: [.instructions(i1), .prompt(p1), .instructions(i2), .prompt(p2)]).resolved()

        #expect(converted.count == 4)
        guard case .instructions = converted[0] else { Issue.record("entry[0] should be .instructions"); return }
        guard case .prompt        = converted[1] else { Issue.record("entry[1] should be .prompt"); return }
        guard case .instructions = converted[2] else { Issue.record("entry[2] should be .instructions"); return }
        guard case .prompt        = converted[3] else { Issue.record("entry[3] should be .prompt"); return }
        #expect(converted.toolDefinitions.count == 1)
        #expect(converted.toolDefinitions[0].name == "tool2")
    }

    @Test("instructions flushes pending toolCalls before adding instructions entry")
    func instructionsFlushesPendingToolCalls() {
        let arg = GeneratedContent(kind: .null)
        let calls = Transcript.ToolCalls([Transcript.ToolCall(id: "c1", toolName: "t1", arguments: arg)])
        let out = Transcript.ToolOutput(id: "o1", toolName: "t1", segments: [])
        let inst = Transcript.Instructions(segments: [], toolDefinitions: [])

        let converted = Transcript(entries: [.toolCalls(calls), .toolOutput(out), .instructions(inst)]).resolved()

        #expect(converted.count == 2)
        guard case .tool(let interaction) = converted[0] else { Issue.record("entry[0] should be .tool"); return }
        guard case .instructions = converted[1] else { Issue.record("entry[1] should be .instructions"); return }
        #expect(interaction.outputs.count == 1)
    }

    // MARK: - Output ordering

    @Test("toolOutputs are stored in insertion order regardless of toolName")
    func toolOutputsPreserveInsertionOrder() {
        let arg = GeneratedContent(kind: .null)
        let calls = Transcript.ToolCalls([
            Transcript.ToolCall(id: "cA", toolName: "A", arguments: arg),
            Transcript.ToolCall(id: "cB", toolName: "B", arguments: arg),
            Transcript.ToolCall(id: "cC", toolName: "C", arguments: arg),
        ])
        let outC = Transcript.ToolOutput(id: "oC", toolName: "C", segments: [])
        let outA = Transcript.ToolOutput(id: "oA", toolName: "A", segments: [])
        let outB = Transcript.ToolOutput(id: "oB", toolName: "B", segments: [])

        let converted = Transcript(entries: [
            .toolCalls(calls),
            .toolOutput(outC),
            .toolOutput(outA),
            .toolOutput(outB),
        ]).resolved()

        guard case .tool(let interaction) = converted[0] else { Issue.record("Expected .tool entry"); return }
        #expect(interaction.outputs.count == 3)
        #expect(interaction.outputs[0].id == "oC")
        #expect(interaction.outputs[1].id == "oA")
        #expect(interaction.outputs[2].id == "oB")
    }

    // MARK: - Data identity

    @Test("prompt entry preserves all Prompt fields")
    func promptEntryPreservesAllFields() {
        let prompt = Transcript.Prompt(
            id: "fixed-prompt-id",
            segments: [.text(.init(id: "s1", content: "Hello"))],
            options: GenerationOptions(temperature: 0.7),
            responseFormat: nil
        )
        let converted = Transcript(entries: [.prompt(prompt)]).resolved()

        guard case .prompt(let extracted) = converted[0] else { Issue.record("Expected .prompt entry"); return }
        #expect(extracted == prompt)
        #expect(extracted.id == "fixed-prompt-id")
        #expect(extracted.options.temperature == 0.7)
    }

    @Test("response entry preserves assetIDs and all segments")
    func responseEntryPreservesAssetIDs() {
        let response = Transcript.Response(
            id: "r-fixed",
            assetIDs: ["asset-1", "asset-2"],
            segments: [
                .text(.init(id: "s1", content: "Part 1")),
                .text(.init(id: "s2", content: "Part 2")),
            ]
        )
        let converted = Transcript(entries: [.response(response)]).resolved()

        guard case .response(let extracted) = converted[0] else { Issue.record("Expected .response entry"); return }
        #expect(extracted == response)
        #expect(extracted.assetIDs == ["asset-1", "asset-2"])
        #expect(extracted.segments.count == 2)
    }

    @Test("tool entry preserves all ToolCall fields including arguments")
    func toolEntryPreservesAllCallFields() {
        let calls = Transcript.ToolCalls(id: "tc-fixed", [
            Transcript.ToolCall(id: "c1", toolName: "toolA", arguments: GeneratedContent(kind: .string("arg1"))),
            Transcript.ToolCall(id: "c2", toolName: "toolB", arguments: GeneratedContent(kind: .number(42.0))),
        ])
        let converted = Transcript(entries: [.toolCalls(calls)]).resolved()

        guard case .tool(let interaction) = converted[0] else { Issue.record("Expected .tool entry"); return }
        #expect(interaction.calls.id == "tc-fixed")
        #expect(interaction.calls[0].id == "c1")
        #expect(interaction.calls[0].toolName == "toolA")
        #expect(interaction.calls[1].arguments == GeneratedContent(kind: .number(42.0)))
    }

    // MARK: - Equatable conformance

    @Test("same entries produce equal ResolvedTranscripts")
    func sameInputProducesEqualResult() {
        let instructions = Transcript.Instructions(id: "i1", segments: [], toolDefinitions: [])
        let prompt = Transcript.Prompt(id: "p1", segments: [], options: .default)
        let entries: [Transcript.Entry] = [.instructions(instructions), .prompt(prompt)]

        let t1 = Transcript(entries: entries).resolved()
        let t2 = Transcript(entries: entries).resolved()
        #expect(t1 == t2)
    }

    @Test("different entry order produces unequal ResolvedTranscripts")
    func differentOrderProducesUnequalResult() {
        let p1 = Transcript.Prompt(id: "p1", segments: [.text(.init(id: "s1", content: "first"))])
        let p2 = Transcript.Prompt(id: "p2", segments: [.text(.init(id: "s2", content: "second"))])

        let t1 = Transcript(entries: [.prompt(p1), .prompt(p2)]).resolved()
        let t2 = Transcript(entries: [.prompt(p2), .prompt(p1)]).resolved()
        #expect(t1 != t2)
    }

    @Test("different toolOutput IDs produce unequal tool entries")
    func differentOutputsProducesUnequalToolEntry() {
        let arg = GeneratedContent(kind: .null)
        let calls = Transcript.ToolCalls(id: "tc1", [Transcript.ToolCall(id: "c1", toolName: "t1", arguments: arg)])
        let out1 = Transcript.ToolOutput(id: "oA", toolName: "t1", segments: [])
        let out2 = Transcript.ToolOutput(id: "oB", toolName: "t1", segments: [])

        let t1 = Transcript(entries: [.toolCalls(calls), .toolOutput(out1)]).resolved()
        let t2 = Transcript(entries: [.toolCalls(calls), .toolOutput(out2)]).resolved()
        #expect(t1 != t2)
    }

    // MARK: - Edge cases

    @Test("multiple consecutive orphaned toolOutputs are all ignored")
    func multipleConsecutiveOrphanedOutputsIgnored() {
        let entries: [Transcript.Entry] = [
            .toolOutput(Transcript.ToolOutput(id: "o1", toolName: "t1", segments: [])),
            .toolOutput(Transcript.ToolOutput(id: "o2", toolName: "t2", segments: [])),
            .toolOutput(Transcript.ToolOutput(id: "o3", toolName: "t3", segments: [])),
        ]
        let converted = Transcript(entries: entries).resolved()
        #expect(converted.isEmpty)
    }

    @Test("toolCalls at transcript end is flushed with empty outputs")
    func toolCallsAtEndFlushedByFinalFlush() {
        let arg = GeneratedContent(kind: .null)
        let inst = Transcript.Instructions(segments: [], toolDefinitions: [])
        let calls = Transcript.ToolCalls([Transcript.ToolCall(id: "c1", toolName: "t1", arguments: arg)])

        let converted = Transcript(entries: [.instructions(inst), .toolCalls(calls)]).resolved()

        #expect(converted.count == 2)
        guard case .instructions = converted[0] else { Issue.record("entry[0] should be .instructions"); return }
        guard case .tool(let interaction) = converted[1] else { Issue.record("entry[1] should be .tool"); return }
        #expect(interaction.outputs.isEmpty)
    }

    @Test("more toolOutputs than toolCalls are all collected")
    func moreOutputsThanCallsAreAllCollected() {
        let arg = GeneratedContent(kind: .null)
        let calls = Transcript.ToolCalls([Transcript.ToolCall(id: "c1", toolName: "t1", arguments: arg)])
        let entries: [Transcript.Entry] = [
            .toolCalls(calls),
            .toolOutput(Transcript.ToolOutput(id: "o1", toolName: "t1", segments: [])),
            .toolOutput(Transcript.ToolOutput(id: "o2", toolName: "t1", segments: [])),
            .toolOutput(Transcript.ToolOutput(id: "o3", toolName: "t1", segments: [])),
        ]
        let converted = Transcript(entries: entries).resolved()

        #expect(converted.count == 1)
        guard case .tool(let interaction) = converted[0] else { Issue.record("Expected .tool entry"); return }
        #expect(interaction.calls.count == 1)
        #expect(interaction.outputs.count == 3)
    }

    @Test("response entry does not update latestOptions")
    func responseDoesNotClearLatestOptions() {
        let p1 = Transcript.Prompt(segments: [], options: GenerationOptions(temperature: 0.5))
        let r1 = Transcript.Response(id: "r1", assetIDs: [], segments: [])

        let converted = Transcript(entries: [.prompt(p1), .response(r1)]).resolved()
        #expect(converted.latestOptions?.temperature == 0.5)
    }

    @Test("empty toolCalls followed by toolOutput produces tool entry")
    func emptyToolCallsWithOutput() {
        let emptyCalls = Transcript.ToolCalls(id: "tc-empty", [])
        let out = Transcript.ToolOutput(id: "o1", toolName: "t1", segments: [])

        let converted = Transcript(entries: [.toolCalls(emptyCalls), .toolOutput(out)]).resolved()

        #expect(converted.count == 1)
        guard case .tool(let interaction) = converted[0] else { Issue.record("Expected .tool entry"); return }
        #expect(interaction.calls.isEmpty)
        #expect(interaction.outputs.count == 1)
    }

    // MARK: - Entry ordering

    @Test("full multi-turn conversation produces correct entry order")
    func fullConversationEntryOrder() {
        let schema = GenerationSchema(type: String.self, description: "arg", properties: [])
        let toolDef = Transcript.ToolDefinition(name: "myTool", description: "does stuff", parameters: schema)
        let instructions = Transcript.Instructions(
            segments: [.text(.init(content: "Be helpful"))],
            toolDefinitions: [toolDef]
        )
        let prompt = Transcript.Prompt(segments: [.text(.init(content: "Use the tool"))])
        let calls = Transcript.ToolCalls([
            Transcript.ToolCall(id: "c1", toolName: "myTool", arguments: GeneratedContent(kind: .null))
        ])
        let output = Transcript.ToolOutput(id: "o1", toolName: "myTool", segments: [.text(.init(content: "done"))])
        let response = Transcript.Response(id: "r1", assetIDs: [], segments: [.text(.init(content: "All done!"))])

        let converted = Transcript(entries: [
            .instructions(instructions),
            .prompt(prompt),
            .toolCalls(calls),
            .toolOutput(output),
            .response(response),
        ]).resolved()

        #expect(converted.count == 4)
        #expect(converted.toolDefinitions.count == 1)

        guard case .instructions = converted[0] else { Issue.record("entry[0] should be .instructions"); return }
        guard case .prompt        = converted[1] else { Issue.record("entry[1] should be .prompt"); return }
        guard case .tool(let interaction) = converted[2] else { Issue.record("entry[2] should be .tool"); return }
        guard case .response      = converted[3] else { Issue.record("entry[3] should be .response"); return }

        #expect(interaction.calls.count == 1)
        #expect(interaction.outputs.count == 1)
    }
}
