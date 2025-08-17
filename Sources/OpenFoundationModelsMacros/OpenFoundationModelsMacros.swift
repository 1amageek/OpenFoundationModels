import OpenFoundationModelsCore

@attached(extension, conformances: Generable, names: named(init(_:)), named(generatedContent))
@attached(member, names: arbitrary)
public macro Generable(description: String? = nil) = #externalMacro(module: "OpenFoundationModelsMacrosImpl", type: "GenerableMacro")

@attached(peer)
public macro Guide(description: String) = #externalMacro(module: "OpenFoundationModelsMacrosImpl", type: "GuideMacro")

@attached(peer)
public macro Guide<Value>(description: String, _ guides: GenerationGuide<Value>...) = #externalMacro(module: "OpenFoundationModelsMacrosImpl", type: "GuideMacro")

@attached(peer)
public macro Guide<RegexOutput>(
    description: String? = nil,
    _ guides: Regex<RegexOutput>
) = #externalMacro(module: "OpenFoundationModelsMacrosImpl", type: "GuideMacro")

public enum GuideConstraint {
    case range(ClosedRange<Int>)
    case count(Int)
    case enumValues([String])
    case pattern(String)
}