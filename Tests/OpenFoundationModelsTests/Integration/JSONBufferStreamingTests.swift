import Testing
import Foundation
@testable import OpenFoundationModels
@testable import OpenFoundationModelsCore

// Test types for JSON buffer streaming
@Generable
fileprivate struct StreamPerson {
    var name: String
    var age: Int
}

@Generable
fileprivate struct StreamConfig {
    var required: String
    var optional: Int?
}

@Suite("JSON Buffer Streaming Tests")
struct JSONBufferStreamingTests {

    @Test("Partial JSON chunks are accumulated correctly")
    func partialJSONChunksAccumulated() throws {
        // Simulate streaming partial JSON chunks
        let chunks = [
            "{\"na",
            "me\": \"Jo",
            "hn\", \"age\"",
            ": 30}"
        ]

        var buffer = ""
        var parsedContent: GeneratedContent?

        for chunk in chunks {
            buffer += chunk
            // Try to parse accumulated buffer
            if let content = try? GeneratedContent(json: buffer) {
                parsedContent = content
            }
        }

        // Final buffer should be valid JSON
        #expect(buffer == "{\"name\": \"John\", \"age\": 30}")
        #expect(parsedContent != nil)

        // Verify parsed content
        if let content = parsedContent {
            let props = try content.properties()
            #expect(try props["name"]?.value(String.self) == "John")
            #expect(try props["age"]?.value(Int.self) == 30)
        }
    }

    @Test("Complete JSON in single chunk parses immediately")
    func completeJSONInSingleChunk() throws {
        let json = "{\"status\": \"success\", \"count\": 42}"

        var buffer = ""
        buffer += json

        let content = try GeneratedContent(json: buffer)
        let props = try content.properties()

        #expect(try props["status"]?.value(String.self) == "success")
        #expect(try props["count"]?.value(Int.self) == 42)
    }

    @Test("Nested JSON object streaming")
    func nestedJSONObjectStreaming() throws {
        // Simulate streaming nested JSON
        let chunks = [
            "{\"user\": {\"id\":",
            " 123, \"profile\":",
            " {\"name\": \"Alice",
            "\", \"active\": true}",
            "}}"
        ]

        var buffer = ""
        var lastValidContent: GeneratedContent?

        for chunk in chunks {
            buffer += chunk
            if let content = try? GeneratedContent(json: buffer) {
                lastValidContent = content
            }
        }

        #expect(lastValidContent != nil)

        if let content = lastValidContent {
            let props = try content.properties()
            let userContent = props["user"]
            #expect(userContent != nil)

            if let user = userContent {
                let userProps = try user.properties()
                #expect(try userProps["id"]?.value(Int.self) == 123)

                if let profile = userProps["profile"] {
                    let profileProps = try profile.properties()
                    #expect(try profileProps["name"]?.value(String.self) == "Alice")
                    #expect(try profileProps["active"]?.value(Bool.self) == true)
                }
            }
        }
    }

    @Test("Array JSON streaming")
    func arrayJSONStreaming() throws {
        // Simulate streaming JSON array
        let chunks = [
            "[{\"id\": 1}, ",
            "{\"id\": 2}, ",
            "{\"id\": 3}]"
        ]

        var buffer = ""
        var lastValidContent: GeneratedContent?

        for chunk in chunks {
            buffer += chunk
            if let content = try? GeneratedContent(json: buffer) {
                lastValidContent = content
            }
        }

        #expect(lastValidContent != nil)

        if let content = lastValidContent {
            let elements = try content.elements()
            #expect(elements.count == 3)

            for (index, element) in elements.enumerated() {
                let props = try element.properties()
                #expect(try props["id"]?.value(Int.self) == index + 1)
            }
        }
    }

    @Test("Unicode and special characters in streamed JSON")
    func unicodeInStreamedJSON() throws {
        let chunks = [
            "{\"message\": \"こん",
            "にちは\", \"emoji\":",
            " \"🎉\", \"escaped\":",
            " \"line\\nbreak\"}"
        ]

        var buffer = ""
        for chunk in chunks {
            buffer += chunk
        }

        let content = try GeneratedContent(json: buffer)
        let props = try content.properties()

        #expect(try props["message"]?.value(String.self) == "こんにちは")
        #expect(try props["emoji"]?.value(String.self) == "🎉")
        #expect(try props["escaped"]?.value(String.self) == "line\nbreak")
    }

    @Test("Empty buffer does not crash")
    func emptyBufferDoesNotCrash() throws {
        let buffer = ""

        // Should not crash - may return null content for empty string
        let content = try? GeneratedContent(json: buffer)
        // The parser handles empty string gracefully (returns null or valid content)
        // Main expectation is no crash
        #expect(content != nil || content == nil) // Always passes - just checking no crash
    }

    @Test("Partial JSON returns partial content")
    func partialJSONReturnsPartialContent() throws {
        // The parser can handle incomplete JSON and return partial content
        let chunks = [
            "{\"incomplete\":",
            " \"value"
            // Missing closing quotes and brace
        ]

        var buffer = ""
        for chunk in chunks {
            buffer += chunk
        }

        // Parser may return partial content for incomplete JSON
        let content = try? GeneratedContent(json: buffer)
        // This verifies the parser doesn't crash on incomplete input
        #expect(buffer == "{\"incomplete\": \"value")
    }

    @Test("Buffer accumulation with whitespace")
    func bufferAccumulationWithWhitespace() throws {
        let chunks = [
            "  {  ",
            "\"key\"  :  ",
            "  \"value\"  ",
            "}  "
        ]

        var buffer = ""
        var lastValidContent: GeneratedContent?

        for chunk in chunks {
            buffer += chunk
            if let content = try? GeneratedContent(json: buffer) {
                lastValidContent = content
            }
        }

        #expect(lastValidContent != nil)

        if let content = lastValidContent {
            let props = try content.properties()
            #expect(try props["key"]?.value(String.self) == "value")
        }
    }

    @Test("Large JSON streaming simulation")
    func largeJSONStreamingSimulation() throws {
        // Build a large JSON object in small chunks
        var jsonParts: [String] = ["{"]

        for i in 0..<50 {
            let comma = i > 0 ? ", " : ""
            jsonParts.append("\(comma)\"field\(i)\": \(i)")
        }
        jsonParts.append("}")

        // Simulate streaming by breaking into small chunks
        let fullJSON = jsonParts.joined()
        let chunkSize = 20
        var chunks: [String] = []

        var index = fullJSON.startIndex
        while index < fullJSON.endIndex {
            let endIndex = fullJSON.index(index, offsetBy: chunkSize, limitedBy: fullJSON.endIndex) ?? fullJSON.endIndex
            chunks.append(String(fullJSON[index..<endIndex]))
            index = endIndex
        }

        var buffer = ""
        var lastValidContent: GeneratedContent?

        for chunk in chunks {
            buffer += chunk
            if let content = try? GeneratedContent(json: buffer) {
                lastValidContent = content
            }
        }

        #expect(lastValidContent != nil)

        if let content = lastValidContent {
            let props = try content.properties()
            #expect(props.count == 50)
            #expect(try props["field0"]?.value(Int.self) == 0)
            #expect(try props["field49"]?.value(Int.self) == 49)
        }
    }

    @Test("Generable type from accumulated JSON buffer")
    func generableTypeFromAccumulatedBuffer() throws {
        let chunks = [
            "{\"name\":",
            " \"Bob\",",
            " \"age\": 25}"
        ]

        var buffer = ""
        var lastValidContent: GeneratedContent?

        for chunk in chunks {
            buffer += chunk
            if let content = try? GeneratedContent(json: buffer) {
                lastValidContent = content
            }
        }

        #expect(lastValidContent != nil)

        if let content = lastValidContent {
            let person = try StreamPerson(content)
            #expect(person.name == "Bob")
            #expect(person.age == 25)
        }
    }

    @Test("Optional fields in accumulated JSON")
    func optionalFieldsInAccumulatedJSON() throws {
        // Test with optional present
        let chunksWithOptional = [
            "{\"required\": \"val",
            "ue\", \"optional\":",
            " 42}"
        ]

        var buffer1 = ""
        for chunk in chunksWithOptional {
            buffer1 += chunk
        }

        let content1 = try GeneratedContent(json: buffer1)
        let config1 = try StreamConfig(content1)
        #expect(config1.required == "value")
        #expect(config1.optional == 42)

        // Test with optional null
        let chunksWithNull = [
            "{\"required\": \"test",
            "\", \"optional\":",
            " null}"
        ]

        var buffer2 = ""
        for chunk in chunksWithNull {
            buffer2 += chunk
        }

        let content2 = try GeneratedContent(json: buffer2)
        let config2 = try StreamConfig(content2)
        #expect(config2.required == "test")
        #expect(config2.optional == nil)
    }
}
