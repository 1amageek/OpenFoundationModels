// GeneratedContent.swift (complete zero-based implementation)
// OpenFoundationModels — Partial JSON parsing with Apple Foundation Models-compatible surface
//
// This file provides a full, copy‑pasteable implementation of GeneratedContent that:
//  - Preserves the public API surface (Kind, init(json:), isComplete, etc.)
//  - Adds robust, streaming-safe partial JSON extraction starting from Stage 1
//  - Uses a single internal representation (JSONValue) to avoid double-management bugs
//
// NOTE:
// - If your project already defines `GenerationID`, keep yours and remove the typealias below.
// - This file references protocols like ConvertibleToGeneratedContent / ConvertibleFromGeneratedContent
//   that are expected to exist in your project per Apple FM docs.

import Foundation

// MARK: - Optional shim (remove if you already define this)
// GenerationID is already defined in GenerationID.swift

// MARK: - GeneratedContent

public struct GeneratedContent: Sendable, Equatable, CustomDebugStringConvertible, Codable {
    // MARK: Public API — matches Apple FM surface (+ partial case for streaming)
    public enum Kind: Sendable, Equatable {
        case null
        case bool(Bool)
        case number(Double)
        case string(String)
        case array([GeneratedContent])
        case structure(properties: [String: GeneratedContent], orderedKeys: [String])
    }

    // MARK: Storage
    private struct Storage: Sendable, Equatable {
        var root: JSONValue?                // present when fully parsed
        var partialRaw: String?             // raw partial JSON text when not complete
        var isComplete: Bool
        var generationID: GenerationID?
    }

    private var storage: Storage

    // MARK: Public properties
    public var id: GenerationID? { storage.generationID }

    public var kind: Kind {
        if let root = storage.root { return mapJSONValueToKind(root) }
        if let raw = storage.partialRaw {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.hasPrefix("{") {
                let obj = PartialJSON.extractObject(t)
                // Always return structure, even if empty (for partial JSON)
                return .structure(properties: obj.properties, orderedKeys: obj.orderedKeys)
            } else if t.hasPrefix("[") {
                let arr = PartialJSON.extractArray(t)
                // Always return array, even if empty (for partial JSON)
                return .array(arr.elements)
            } else {
                if let scalar = PartialJSON.extractTopLevelScalar(t) {
                    return mapJSONValueToKind(scalar)
                }
                // For unparseable partial JSON, return empty string
                return .string("")
            }
        }
        return .null
    }

    public var isComplete: Bool { storage.isComplete }

    /// JSON string representation. For partial input, returns the raw partial string verbatim.
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

    // MARK: - Public initializers (Apple-compatible)

    public init(_ value: some ConvertibleToGeneratedContent) { self = value.generatedContent }

    public init(_ value: some ConvertibleToGeneratedContent, id: GenerationID) {
        self = value.generatedContent
        self.storage.generationID = id
    }

    public init<C: Collection>(elements: C, id: GenerationID? = nil) where C.Element: ConvertibleToGeneratedContent {
        let arr = elements.map { $0.generatedContent }
        self.storage = Storage(root: .array(arr.map { $0.asJSONValue() }), partialRaw: nil, isComplete: true, generationID: id)
    }

    public init(properties: KeyValuePairs<String, any ConvertibleToGeneratedContent>, id: GenerationID? = nil) {
        var dict: [String: JSONValue] = [:]
        var ordered: [String] = []
        for (k, v) in properties { dict[k] = v.generatedContent.asJSONValue(); ordered.append(k) }
        self.storage = Storage(root: .object(dict, orderedKeys: ordered), partialRaw: nil, isComplete: true, generationID: id)
    }

    public init<S: Sequence>(properties: S, id: GenerationID? = nil, uniquingKeysWith combine: (any ConvertibleToGeneratedContent, any ConvertibleToGeneratedContent) throws -> any ConvertibleToGeneratedContent) rethrows where S.Element == (String, any ConvertibleToGeneratedContent) {
        var map: [String: GeneratedContent] = [:]
        var ordered: [String] = []
        for (k, v) in properties {
            if let exist = map[k] { map[k] = try combine(exist, v).generatedContent } else { map[k] = v.generatedContent; ordered.append(k) }
        }
        self.storage = Storage(root: .object(map.mapValues { $0.asJSONValue() }, orderedKeys: ordered), partialRaw: nil, isComplete: true, generationID: id)
    }

    public init(kind: Kind, id: GenerationID? = nil) {
        self.storage = Storage(root: Self.mapKindToJSONValue(kind), partialRaw: nil, isComplete: true, generationID: id)
    }

    /// Apple Official: init(json:) throws
    /// Fully valid JSON → parsed. Otherwise → partial (raw stored) with streaming-safe extraction available.
    public init(json: String) throws {
        let t = json.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { self.storage = Storage(root: .null, partialRaw: nil, isComplete: true, generationID: nil); return }
        if let obj = try? JSONSerialization.jsonObject(with: Data(t.utf8)) {
            let root = try Self.decodeJSONObject(obj)
            self.storage = Storage(root: root, partialRaw: nil, isComplete: true, generationID: nil)
            return
        }
        // Not fully parseable — keep raw, expose safe prefix via properties()/elements()/kind
        self.storage = Storage(root: nil, partialRaw: json, isComplete: false, generationID: nil)
    }

    // MARK: - Data access (Apple semantics + partial support)

    /// Reads the properties of a top level object. For partial JSON, returns the subset of properties whose values are safely determined.
    public func properties() throws -> [String: GeneratedContent] {
        switch kind {
        case .structure(let props, _): return props
        default:
            // Apple spec: Return empty dictionary instead of throwing for non-structure types
            return [:]
        }
    }

    /// Reads a top level array of content. For partial JSON, returns only the safely determined leading elements.
    public func elements() throws -> [GeneratedContent] {
        switch kind {
        case .array(let arr): return arr
        default:
            // Apple spec: Return empty array instead of throwing for non-array types
            return []
        }
    }

    /// Reads a top-level, concrete partially generable type.
    public func value<Value>(_ type: Value.Type) throws -> Value {
        switch kind {
        case .null:
            // Check if Value is Optional and return nil
            if String(describing: Value.self).contains("Optional") {
                return unsafeBitCast(Optional<Any>.none, to: Value.self)
            }
            throw GeneratedContentError.typeMismatch(expected: String(describing: type), actual: "Null")
        case .bool(let b):
            if type == Bool.self { return (b as Any) as! Value }
            throw GeneratedContentError.typeMismatch(expected: String(describing: type), actual: "Bool")
        case .number(let d):
            if type == Double.self { return (d as Any) as! Value }
            if type == Int.self, d.rounded() == d { return (Int(d) as Any) as! Value }
            throw GeneratedContentError.typeMismatch(expected: String(describing: type), actual: "Number")
        case .string(let s):
            if type == String.self { return (s as Any) as! Value }
            if type == Bool.self, let b = Bool(s) { return (b as Any) as! Value }
            if type == Int.self, let i = Int(s) { return (i as Any) as! Value }
            if type == Double.self, let d = Double(s) { return (d as Any) as! Value }
            if type == Float.self, let f = Float(s) { return (f as Any) as! Value }
            throw GeneratedContentError.typeMismatch(expected: String(describing: type), actual: "String")
        case .array:
            throw GeneratedContentError.typeMismatch(expected: String(describing: type), actual: "Array")
        case .structure:
            throw GeneratedContentError.typeMismatch(expected: String(describing: type), actual: "Dictionary")
        }
    }

    public func value<Value>(_ type: Value.Type, forProperty key: String) throws -> Value {
        let props = try properties()
        guard let c = props[key] else { throw GeneratedContentError.missingProperty(key) }
        return try c.value(type)
    }

    public func value<Value>(_ type: Value?.Type, forProperty key: String) throws -> Value? {
        let props = try properties()
        guard let c = props[key] else { return nil }
        return try c.value(Value.self)
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.storage = Storage(root: .null, partialRaw: nil, isComplete: true, generationID: nil)
        } else if let b = try? container.decode(Bool.self) {
            self.storage = Storage(root: .bool(b), partialRaw: nil, isComplete: true, generationID: nil)
        } else if let d = try? container.decode(Double.self) {
            self.storage = Storage(root: .number(d), partialRaw: nil, isComplete: true, generationID: nil)
        } else if let s = try? container.decode(String.self) {
            // Heuristic: detect partial JSON markers
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.hasPrefix("{") || t.hasPrefix("[") { self.storage = Storage(root: nil, partialRaw: s, isComplete: false, generationID: nil) }
            else { self.storage = Storage(root: .string(s), partialRaw: nil, isComplete: true, generationID: nil) }
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

    // MARK: - Helpers

    internal var stringValue: String {
        switch kind {
        case .null: return "null"
        case .bool(let b): return b ? "true" : "false"
        case .number(let d): 
            // Display integers without decimal point
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
            case .object(let dict, _):
                var m: [String: Any] = [:]
                for (k, v) in dict { m[k] = toAny(v) }
                return m
            }
        }
        let v = asJSONValue()
        let data = try JSONSerialization.data(withJSONObject: toAny(v), options: [.prettyPrinted])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - Internal single representation

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
        switch kind { // use computed kind for partial snapshot
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

// MARK: - Full JSON decode

extension GeneratedContent {
    fileprivate static func decodeJSONObject(_ obj: Any) throws -> JSONValue {
        if obj is NSNull { return .null }
        // NSNumber can represent both booleans and numbers
        // Check for NSNumber first and determine if it's a boolean
        if let n = obj as? NSNumber {
            // Check if this NSNumber is actually a boolean
            // Compare the objCType to determine the actual type
            let objCType = String(cString: n.objCType)
            if objCType == "c" || objCType == "B" {
                // "c" is for BOOL, "B" is for bool
                return .bool(n.boolValue)
            } else {
                return .number(n.doubleValue)
            }
        }
        if let s = obj as? String { return .string(s) }
        if let arr = obj as? [Any] { return .array(try arr.map { try decodeJSONObject($0) }) }
        if let dict = obj as? [String: Any] {
            var out: [String: JSONValue] = [:]
            let keys = dict.keys.sorted()
            for (k, v) in dict { out[k] = try decodeJSONObject(v) }
            return .object(out, orderedKeys: keys)
        }
        throw GeneratedContentError.invalidJSON("Unsupported JSON type: \(type(of: obj))")
    }
}

// MARK: - Partial JSON extractor

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
                // otherwise: partial tail
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
                // otherwise partial tail
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

    // MARK: - Scanners

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
            // Extract nested object safely
            let start = i
            let obj = extractObject(String(s[start...]))
            // advance i respecting strings/escapes
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

    // String scanner with escape + unicode handling; allowPartial trims to safe prefix
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
                    if (0xD800...0xDBFF).contains(scalar) { // high surrogate, expect low surrogate
                        // need \uXXXX next
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

    // Number scanner that returns the numeric value and the index consumed to a safe prefix
    private static func scanNumberWithSafePrefix(_ s: String, _ start: String.Index) -> (Double, String.Index)? {
        var i = start
        let begin = i
        // sign
        if peek(s, i) == "-" { bump(&i, in: s) }
        // int
        guard let d0 = peek(s, i), d0.isDigit else { return nil }
        if d0 == "0" { bump(&i, in: s) } else { while let d = peek(s, i), d.isDigit { bump(&i, in: s) } }
        // record last valid
        var lastValid = i
        // frac
        if peek(s, i) == "." {
            let dot = i; bump(&i, in: s)
            guard let d = peek(s, i), d.isDigit else {
                // rollback to before dot — integer is valid
                if let val = Double(String(s[begin..<dot])) { return (val, dot) }
                return nil
            }
            while let d = peek(s, i), d.isDigit { bump(&i, in: s) }
            lastValid = i
        }
        // exp
        if let e = peek(s, i), e == "e" || e == "E" {
            let epos = i; bump(&i, in: s)
            if let sign = peek(s, i), sign == "+" || sign == "-" { bump(&i, in: s) }
            guard let d = peek(s, i), d.isDigit else {
                // rollback to lastValid (after fraction if any)
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

    // MARK: - Cursor helpers

    private static func peek(_ s: String, _ i: String.Index) -> Character? { i < s.endIndex ? s[i] : nil }
    private static func bump(_ i: inout String.Index, in s: String) { i = s.index(after: i) }
    private static func skipWS(_ s: String, _ i: inout String.Index) { while let c = peek(s, i), c.isJSONWhitespace { bump(&i, in: s) } }

    // Advance over a possibly unbalanced object/array, respecting strings/escapes,
    // returning the index at closing bracket or end-of-string if partial.
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

// MARK: - Completeness check (utility if needed externally)

extension GeneratedContent {
    /// Fast completeness check for raw JSON text.
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

// MARK: - Errors

public enum GeneratedContentError: Error, Sendable {
    case invalidSchema
    case typeMismatch(expected: String, actual: String)
    case missingProperty(String)
    case invalidJSON(String)
    case arrayExpected
    case dictionaryExpected
    case partialContent
}

// MARK: - Protocol conformances

extension GeneratedContent: ConvertibleFromGeneratedContent {
    public init(_ content: GeneratedContent) throws { self = content }
}

extension GeneratedContent: ConvertibleToGeneratedContent {
    public var text: String { stringValue }
}

// MARK: - Character helpers

fileprivate extension Character {
    var isDigit: Bool { ("0"..."9").contains(self) }
    var isJSONWhitespace: Bool { self == " " || self == "\n" || self == "\r" || self == "\t" }
}