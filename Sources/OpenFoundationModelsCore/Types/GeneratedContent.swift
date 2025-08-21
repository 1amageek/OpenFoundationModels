
import Foundation



public struct GeneratedContent: Sendable, Equatable, CustomDebugStringConvertible, Codable, ConvertibleToGeneratedContent {
    public enum Kind: Sendable, Equatable {
        case null
        case bool(Bool)
        case number(Double)
        case string(String)
        case array([GeneratedContent])
        case structure(properties: [String: GeneratedContent], orderedKeys: [String])
    }

    private struct Storage: Sendable, Equatable {
        var root: JSONValue?
        var partialRaw: String?
        var isComplete: Bool
        var generationID: GenerationID?
    }

    private var storage: Storage

    public var id: GenerationID? { storage.generationID }

    public var kind: Kind {
        if let root = storage.root { return mapJSONValueToKind(root) }
        if let raw = storage.partialRaw {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.hasPrefix("{") {
                let obj = PartialJSON.extractObject(t)
                return .structure(properties: obj.properties, orderedKeys: obj.orderedKeys)
            } else if t.hasPrefix("[") {
                let arr = PartialJSON.extractArray(t)
                return .array(arr.elements)
            } else {
                if let scalar = PartialJSON.extractTopLevelScalar(t) {
                    return mapJSONValueToKind(scalar)
                }
                // Return non-JSON text as-is instead of empty string
                return .string(t)
            }
        }
        return .null
    }

    public var isComplete: Bool { storage.isComplete }

    public var jsonString: String {
        if let raw = storage.partialRaw { return raw }
        do { return try toJSONString() } catch { return stringValue }
    }

    public var generatedContent: GeneratedContent { self }

    public var debugDescription: String {
        switch kind {
        case .null: return "GeneratedContent(null)"
        case .bool(let b): return "GeneratedContent(\(b))"
        case .number(let d): return "GeneratedContent(\(d))"
        case .string(let s): return "GeneratedContent(\"\(s)\")"
        case .array(let a): return "GeneratedContent([" + a.map { $0.debugDescription }.joined(separator: ", ") + "])"
        case .structure(let props, _):
            let body = props.keys.sorted().map { "\($0): \(props[$0]!.debugDescription)" }.joined(separator: ", ")
            return "GeneratedContent({" + body + "})"
        }
    }


    public init(_ value: some ConvertibleToGeneratedContent) { 
        self = value.generatedContent 
    }
    
    public init(_ value: some ConvertibleToGeneratedContent, id: GenerationID) {
        self = value.generatedContent
        self.storage.generationID = id
    }

    public init<S: Sequence>(elements: S, id: GenerationID? = nil) where S.Element: ConvertibleToGeneratedContent {
        let arr = Array(elements).map { $0.generatedContent }
        self.storage = Storage(root: .array(arr.map { $0.asJSONValue() }), partialRaw: nil, isComplete: true, generationID: id)
    }

    public init(properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>, id: GenerationID? = nil) {
        var dict: [String: JSONValue] = [:]
        var ordered: [String] = []
        for (k, v) in properties { dict[k] = v.generatedContent.asJSONValue(); ordered.append(k) }
        self.storage = Storage(root: .object(dict, orderedKeys: ordered), partialRaw: nil, isComplete: true, generationID: id)
    }

    public init<S>(properties: S, id: GenerationID? = nil, uniquingKeysWith combine: (GeneratedContent, GeneratedContent) throws -> some ConvertibleToGeneratedContent) rethrows where S : Sequence, S.Element == (String, any ConvertibleToGeneratedContent) {
        var map: [String: GeneratedContent] = [:]
        var ordered: [String] = []
        for (k, v) in properties {
            let vContent = v.generatedContent
            if let exist = map[k] { 
                map[k] = try combine(exist, vContent).generatedContent 
            } else { 
                map[k] = vContent
                ordered.append(k) 
            }
        }
        self.storage = Storage(root: .object(map.mapValues { $0.asJSONValue() }, orderedKeys: ordered), partialRaw: nil, isComplete: true, generationID: id)
    }

    public init(kind: Kind, id: GenerationID? = nil) {
        self.storage = Storage(root: Self.mapKindToJSONValue(kind), partialRaw: nil, isComplete: true, generationID: id)
    }

    /// Creates equivalent content from a JSON string.
    ///
    /// The JSON string you provide may be incomplete. This is useful for correctly handling partially generated responses.
    ///
    /// ```swift
    /// @Generable struct NovelIdea {
    ///   let title: String
    /// }
    ///
    /// let partial = #"{"title": "A story of"#
    /// let content = try GeneratedContent(json: partial)
    /// let idea = try NovelIdea(content)
    /// print(idea.title) // A story of
    /// ```
    public init(json: String) throws {
        let t = json.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { 
            self.storage = Storage(root: .null, partialRaw: nil, isComplete: true, generationID: nil)
            return 
        }
        
        // First, try to parse as complete JSON (including fragments like numbers, strings, booleans)
        if let data = t.data(using: .utf8) {
            do {
                let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
                let root = try Self.decodeJSONObject(obj)
                self.storage = Storage(root: root, partialRaw: nil, isComplete: true, generationID: nil)
                return
            } catch {
                // If complete JSON parsing fails, try partial JSON parsing
            }
        }
        
        // Try to parse as partial JSON
        if t.hasPrefix("{") {
            let obj = PartialJSON.extractObject(t)
            self.storage = Storage(root: nil, partialRaw: t, isComplete: obj.complete, generationID: nil)
            return
        }
        
        if t.hasPrefix("[") {
            let arr = PartialJSON.extractArray(t)
            self.storage = Storage(root: nil, partialRaw: t, isComplete: arr.complete, generationID: nil)
            return
        }
        
        // Handle top-level scalars
        if t.hasPrefix("\"") {
            // Check if it's an unclosed string
            if !Self.isJSONComplete(t) {
                // Treat unclosed strings as partial
                self.storage = Storage(root: nil, partialRaw: t, isComplete: false, generationID: nil)
                return
            }
        }
        
        // Try to parse as a complete scalar value
        if let scalar = PartialJSON.extractTopLevelScalar(t) {
            self.storage = Storage(root: scalar, partialRaw: nil, isComplete: true, generationID: nil)
        } else {
            // If all parsing fails, treat as a partial string
            self.storage = Storage(root: nil, partialRaw: t, isComplete: false, generationID: nil)
        }
    }


    public func properties() throws -> [String: GeneratedContent] {
        switch kind {
        case .structure(let props, _): return props
        default:
            throw GeneratedContentError.dictionaryExpected
        }
    }

    public func elements() throws -> [GeneratedContent] {
        switch kind {
        case .array(let arr): return arr
        default:
            throw GeneratedContentError.arrayExpected
        }
    }

    public func value<Value>(_ type: Value.Type = Value.self) throws -> Value where Value: ConvertibleFromGeneratedContent {
        return try Value(self)
    }

    public func value<Value>(_ type: Value.Type = Value.self, forProperty property: String) throws -> Value where Value: ConvertibleFromGeneratedContent {
        let props = try properties()
        guard let c = props[property] else { 
            throw GeneratedContentError.missingProperty(property) 
        }
        return try Value(c)
    }

    public func value<Value>(_ type: Value?.Type = Value?.self, forProperty property: String) throws -> Value? where Value: ConvertibleFromGeneratedContent {
        let props = try properties()
        guard let c = props[property] else { return nil }
        return try Value(c)
    }


    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.storage = Storage(root: .null, partialRaw: nil, isComplete: true, generationID: nil)
        } else if let b = try? container.decode(Bool.self) {
            self.storage = Storage(root: .bool(b), partialRaw: nil, isComplete: true, generationID: nil)
        } else if let d = try? container.decode(Double.self) {
            self.storage = Storage(root: .number(d), partialRaw: nil, isComplete: true, generationID: nil)
        } else if let s = try? container.decode(String.self) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.hasPrefix("{") || t.hasPrefix("[") {
                if let data = s.data(using: .utf8),
                   let _ = try? JSONSerialization.jsonObject(with: data) {
                    if let parsed = try? GeneratedContent(json: s) {
                        self.storage = parsed.storage
                    } else {
                        self.storage = Storage(root: .string(s), partialRaw: nil, isComplete: true, generationID: nil)
                    }
                } else {
                    self.storage = Storage(root: nil, partialRaw: s, isComplete: false, generationID: nil)
                }
            } else {
                self.storage = Storage(root: .string(s), partialRaw: nil, isComplete: true, generationID: nil)
            }
        } else if let arr = try? container.decode([GeneratedContent].self) {
            self.storage = Storage(root: .array(arr.map { $0.asJSONValue() }), partialRaw: nil, isComplete: true, generationID: nil)
        } else if let dict = try? container.decode([String: GeneratedContent].self) {
            let ordered = Array(dict.keys)
            self.storage = Storage(root: .object(dict.mapValues { $0.asJSONValue() }, orderedKeys: ordered), partialRaw: nil, isComplete: true, generationID: nil)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode GeneratedContent")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch kind {
            case .null: try container.encodeNil()
            case .bool(let b): try container.encode(b)
            case .number(let d): try container.encode(d)
            case .string(let s): try container.encode(s)
            case .array(let a): try container.encode(a)
            case .structure(let props, _): try container.encode(props)
        }
    }


    internal var stringValue: String {
        switch kind {
        case .null: return "null"
        case .bool(let b): return b ? "true" : "false"
        case .number(let d): 
            if d.truncatingRemainder(dividingBy: 1) == 0 && d >= Double(Int.min) && d <= Double(Int.max) {
                return String(Int(d))
            } else {
                return String(d)
            }
        case .string(let s): return s
        case .array(let arr): return arr.map { $0.stringValue }.joined(separator: ", ")
        case .structure(let props, _): return "{" + props.keys.sorted().map { "\($0): \(props[$0]!.stringValue)" }.joined(separator: ", ") + "}"
        }
    }

    private func toJSONString() throws -> String {
        func toAny(_ v: JSONValue) -> Any {
            switch v {
            case .null: return NSNull()
            case .bool(let b): return b
            case .number(let d): return d
            case .string(let s): return s
            case .array(let arr): return arr.map { toAny($0) }
            case .object(let dict, let ordered):
                // Respect orderedKeys to maintain order
                var m: [String: Any] = [:]
                let keys = ordered.isEmpty ? Array(dict.keys) : ordered
                for k in keys { 
                    if let v = dict[k] { 
                        m[k] = toAny(v) 
                    }
                }
                return m
            }
        }
        
        let v = asJSONValue()
        let anyValue = toAny(v)
        
        // Use fragmentsAllowed for primitive values
        let options: JSONSerialization.WritingOptions
        switch v {
        case .array, .object:
            options = [.prettyPrinted]
        default:
            options = [.fragmentsAllowed]
        }
        
        let data = try JSONSerialization.data(withJSONObject: anyValue, options: options)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}


fileprivate enum JSONValue: Sendable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue], orderedKeys: [String])
}

extension GeneratedContent {
    fileprivate func asJSONValue() -> JSONValue {
        if let root = storage.root { return root }
        switch kind {
        case .null: return .null
        case .bool(let b): return .bool(b)
        case .number(let d): return .number(d)
        case .string(let s): return .string(s)
        case .array(let a): return .array(a.map { $0.asJSONValue() })
        case .structure(let props, let ordered): return .object(props.mapValues { $0.asJSONValue() }, orderedKeys: ordered)
        }
    }

    fileprivate func mapJSONValueToKind(_ v: JSONValue) -> Kind {
        switch v {
        case .null: return .null
        case .bool(let b): return .bool(b)
        case .number(let d): return .number(d)
        case .string(let s): return .string(s)
        case .array(let arr):
            let gc = arr.map { GeneratedContent(kind: mapJSONValueToKind($0)) }
            return .array(gc)
        case .object(let dict, let ordered):
            var m: [String: GeneratedContent] = [:]
            for (k, v) in dict { m[k] = GeneratedContent(kind: mapJSONValueToKind(v)) }
            return .structure(properties: m, orderedKeys: ordered)
        }
    }

    fileprivate static func mapKindToJSONValue(_ k: Kind) -> JSONValue {
        switch k {
        case .null: return .null
        case .bool(let b): return .bool(b)
        case .number(let d): return .number(d)
        case .string(let s): return .string(s)
        case .array(let arr): return .array(arr.map { $0.asJSONValue() })
        case .structure(let props, let ordered): return .object(props.mapValues { $0.asJSONValue() }, orderedKeys: ordered)
        }
    }
}


extension GeneratedContent {
    fileprivate static func decodeJSONObject(_ obj: Any) throws -> JSONValue {
        if obj is NSNull { return .null }
        if let n = obj as? NSNumber {
            let objCType = String(cString: n.objCType)
            if objCType == "c" || objCType == "B" {
                return .bool(n.boolValue)
            } else {
                return .number(n.doubleValue)
            }
        }
        if let s = obj as? String { return .string(s) }
        if let arr = obj as? [Any] { return .array(try arr.map { try decodeJSONObject($0) }) }
        if let dict = obj as? [String: Any] {
            var out: [String: JSONValue] = [:]
            var keys: [String] = []
            for (k, v) in dict { 
                out[k] = try decodeJSONObject(v)
                keys.append(k)  // Preserve insertion order
            }
            return .object(out, orderedKeys: keys)
        }
        throw GeneratedContentError.invalidJSON("Unsupported JSON type: \(type(of: obj))")
    }
}


fileprivate enum PartialJSON {
    struct ObjectResult { let properties: [String: GeneratedContent]; let orderedKeys: [String]; let complete: Bool }
    struct ArrayResult  { let elements: [GeneratedContent]; let complete: Bool }

    static func extractObject(_ json: String) -> ObjectResult {
        var i = json.startIndex
        skipWS(json, &i)
        guard peek(json, i) == "{" else { return .init(properties: [:], orderedKeys: [], complete: false) }
        bump(&i, in: json) // consume '{'

        var props: [String: GeneratedContent] = [:]
        var order: [String] = []
        var complete = false

        skipWS(json, &i)
        if peek(json, i) == "}" { complete = true; bump(&i, in: json); return .init(properties: props, orderedKeys: order, complete: complete) }

        parseMembers: while i < json.endIndex {
            skipWS(json, &i)
            guard let key = scanString(json, &i, allowPartial: false) else { break parseMembers }
            skipWS(json, &i)
            guard peek(json, i) == ":" else { break parseMembers }
            bump(&i, in: json)
            skipWS(json, &i)
            if let value = scanValue(json, &i) {
                props[key] = value
                order.append(key)
                skipWS(json, &i)
                if peek(json, i) == "," { bump(&i, in: json); continue parseMembers }
                if peek(json, i) == "}" { complete = true; bump(&i, in: json); break parseMembers }
                break parseMembers
            } else {
                break parseMembers
            }
        }
        return .init(properties: props, orderedKeys: order, complete: complete)
    }

    static func extractArray(_ json: String) -> ArrayResult {
        var i = json.startIndex
        skipWS(json, &i)
        guard peek(json, i) == "[" else { return .init(elements: [], complete: false) }
        bump(&i, in: json)

        var elems: [GeneratedContent] = []
        var complete = false

        skipWS(json, &i)
        if peek(json, i) == "]" { complete = true; bump(&i, in: json); return .init(elements: elems, complete: complete) }

        parseElems: while i < json.endIndex {
            if let v = scanValue(json, &i) {
                elems.append(v)
                skipWS(json, &i)
                if peek(json, i) == "," { bump(&i, in: json); continue parseElems }
                if peek(json, i) == "]" { complete = true; bump(&i, in: json); break parseElems }
                break parseElems
            } else {
                break parseElems
            }
        }
        return .init(elements: elems, complete: complete)
    }

    static func extractTopLevelScalar(_ json: String) -> JSONValue? {
        var i = json.startIndex
        if let v = scanValue(json, &i) { return v.asJSONValue() }
        return nil
    }


    private static func scanValue(_ s: String, _ i: inout String.Index) -> GeneratedContent? {
        skipWS(s, &i)
        guard let c = peek(s, i) else { return nil }
        switch c {
        case "\"":
            if let str = scanString(s, &i, allowPartial: true) { return GeneratedContent(kind: .string(str)) }
            return nil
        case "-", "0"..."9":
            if let (num, consumedTo) = scanNumberWithSafePrefix(s, i) { i = consumedTo; return GeneratedContent(kind: .number(num)) }
            return nil
        case "t":
            if scanLiteral(s, &i, "true") { return GeneratedContent(kind: .bool(true)) }
            return nil
        case "f":
            if scanLiteral(s, &i, "false") { return GeneratedContent(kind: .bool(false)) }
            return nil
        case "n":
            if scanLiteral(s, &i, "null") { return GeneratedContent(kind: .null) }
            return nil
        case "{":
            let start = i
            let obj = extractObject(String(s[start...]))
            i = advanceOverBalancedObject(s, from: start)
            return GeneratedContent(kind: .structure(properties: obj.properties, orderedKeys: obj.orderedKeys))
        case "[":
            let start = i
            let arr = extractArray(String(s[start...]))
            i = advanceOverBalancedArray(s, from: start)
            return GeneratedContent(kind: .array(arr.elements))
        default:
            return nil
        }
    }

    private static func scanString(_ s: String, _ i: inout String.Index, allowPartial: Bool) -> String? {
        guard peek(s, i) == "\"" else { return nil }
        bump(&i, in: s) // opening quote
        var out = String()
        while i < s.endIndex {
            let c = s[i]
            bump(&i, in: s)
            if c == "\"" { return out }
            if c == "\\" {
                guard i < s.endIndex else { return allowPartial ? out : nil }
                let e = s[i]
                bump(&i, in: s)
                switch e {
                case "\"", "\\", "/": out.append(e)
                case "b": out.append("\u{0008}")
                case "f": out.append("\u{000C}")
                case "n": out.append("\n")
                case "r": out.append("\r")
                case "t": out.append("\t")
                case "u":
                    var hex = ""
                    for _ in 0..<4 {
                        guard i < s.endIndex else { return allowPartial ? out : nil }
                        let h = s[i]; bump(&i, in: s); hex.append(h)
                    }
                    guard let scalar = UInt32(hex, radix: 16) else { return allowPartial ? out : nil }
                    if (0xD800...0xDBFF).contains(scalar) {
                        let save = i
                        guard i < s.endIndex, s[i] == "\\" else { return allowPartial ? out : nil }
                        bump(&i, in: s)
                        guard i < s.endIndex, s[i] == "u" else { i = save; return allowPartial ? out : nil }
                        bump(&i, in: s)
                        var hex2 = ""
                        for _ in 0..<4 {
                            guard i < s.endIndex else { return allowPartial ? out : nil }
                            let h = s[i]; bump(&i, in: s); hex2.append(h)
                        }
                        guard let scalar2 = UInt32(hex2, radix: 16), (0xDC00...0xDFFF).contains(scalar2) else { return allowPartial ? out : nil }
                        let high = scalar - 0xD800
                        let low  = scalar2 - 0xDC00
                        let uni = 0x10000 + (high << 10) + low
                        if let u = UnicodeScalar(uni) { out.append(Character(u)) } else { return allowPartial ? out : nil }
                    } else if let u = UnicodeScalar(scalar) {
                        out.append(Character(u))
                    } else {
                        return allowPartial ? out : nil
                    }
                default:
                    return allowPartial ? out : nil
                }
            } else {
                out.append(c)
            }
        }
        return allowPartial ? out : nil
    }

    private static func scanNumberWithSafePrefix(_ s: String, _ start: String.Index) -> (Double, String.Index)? {
        var i = start
        let begin = i
        if peek(s, i) == "-" { bump(&i, in: s) }
        guard let d0 = peek(s, i), d0.isDigit else { return nil }
        if d0 == "0" { bump(&i, in: s) } else { while let d = peek(s, i), d.isDigit { bump(&i, in: s) } }
        var lastValid = i
        if peek(s, i) == "." {
            let dot = i; bump(&i, in: s)
            guard let d = peek(s, i), d.isDigit else {
                if let val = Double(String(s[begin..<dot])) { return (val, dot) }
                return nil
            }
            while let d = peek(s, i), d.isDigit { bump(&i, in: s) }
            lastValid = i
        }
        if let e = peek(s, i), e == "e" || e == "E" {
            let epos = i; bump(&i, in: s)
            if let sign = peek(s, i), sign == "+" || sign == "-" { bump(&i, in: s) }
            guard let d = peek(s, i), d.isDigit else {
                if lastValid > begin, let val = Double(String(s[begin..<lastValid])) { return (val, lastValid) }
                if let val = Double(String(s[begin..<epos])) { return (val, epos) }
                return nil
            }
            while let d = peek(s, i), d.isDigit { bump(&i, in: s) }
            lastValid = i
        }
        let slice = String(s[begin..<lastValid])
        if let val = Double(slice) { return (val, lastValid) }
        return nil
    }

    private static func scanLiteral(_ s: String, _ i: inout String.Index, _ lit: String) -> Bool {
        var j = i
        for ch in lit { guard let c = peek(s, j), c == ch else { return false }; bump(&j, in: s) }
        i = j; return true
    }


    private static func peek(_ s: String, _ i: String.Index) -> Character? { i < s.endIndex ? s[i] : nil }
    private static func bump(_ i: inout String.Index, in s: String) { i = s.index(after: i) }
    private static func skipWS(_ s: String, _ i: inout String.Index) { while let c = peek(s, i), c.isJSONWhitespace { bump(&i, in: s) } }

    private static func advanceOverBalancedObject(_ s: String, from: String.Index) -> String.Index {
        var i = from
        var depth = 0
        var inString = false
        var escape = false
        while i < s.endIndex {
            let c = s[i]
            i = s.index(after: i)
            if inString {
                if escape { escape = false; continue }
                if c == "\\" { escape = true; continue }
                if c == "\"" { inString = false }
                continue
            }
            switch c {
            case "\"": inString = true
            case "{": depth += 1
            case "}": depth -= 1; if depth == 0 { return i }
            default: break
            }
        }
        return i
    }

    private static func advanceOverBalancedArray(_ s: String, from: String.Index) -> String.Index {
        var i = from
        var depth = 0
        var inString = false
        var escape = false
        while i < s.endIndex {
            let c = s[i]
            i = s.index(after: i)
            if inString {
                if escape { escape = false; continue }
                if c == "\\" { escape = true; continue }
                if c == "\"" { inString = false }
                continue
            }
            switch c {
            case "\"": inString = true
            case "[": depth += 1
            case "]": depth -= 1; if depth == 0 { return i }
            default: break
            }
        }
        return i
    }
}


extension GeneratedContent {
    internal static func isJSONComplete(_ json: String) -> Bool {
        var stack: [Character] = []
        var inString = false
        var escape = false
        for ch in json {
            if escape { escape = false; continue }
            if ch == "\\" { if inString { escape = true }; continue }
            if ch == "\"" { inString.toggle(); continue }
            if inString { continue }
            switch ch {
            case "{", "[": stack.append(ch)
            case "}": if stack.last == "{" { stack.removeLast() } else { return false }
            case "]": if stack.last == "[" { stack.removeLast() } else { return false }
            default: break
            }
        }
        return stack.isEmpty && !inString
    }
}


public enum GeneratedContentError: Error, Sendable {
    case invalidSchema
    case typeMismatch(expected: String, actual: String)
    case missingProperty(String)
    case invalidJSON(String)
    case arrayExpected
    case dictionaryExpected
    case partialContent
}


extension GeneratedContent: ConvertibleFromGeneratedContent, Generable {
    public init(_ content: GeneratedContent) throws { self = content }
    
    public static var generationSchema: GenerationSchema {
        // GeneratedContent is a dynamic type that can represent any JSON structure
        // Therefore, we return a schema that represents this flexibility
        return GenerationSchema(
            type: GeneratedContent.self,
            description: "A type that represents structured, generated content",
            properties: []
        )
    }
}

public extension GeneratedContent {
    var text: String { stringValue }
}


fileprivate extension Character {
    var isDigit: Bool { ("0"..."9").contains(self) }
    var isJSONWhitespace: Bool { self == " " || self == "\n" || self == "\r" || self == "\t" }
}
