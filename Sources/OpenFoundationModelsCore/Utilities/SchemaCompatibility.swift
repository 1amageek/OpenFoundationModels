
import Foundation

internal enum SchemaCompatibility {
    
    struct ValidationError: Error, CustomStringConvertible {
        let path: String
        
        let reason: String
        
        var description: String {
            "Schema validation failed at \(path): \(reason)"
        }
    }
    
    static func validate<T: Generable & Sendable>(
        _ type: T.Type,
        against saved: (root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema])
    ) throws {
        let current = DynamicGenerationSchema(type: type)
        
        var dependencyMap: [String: DynamicGenerationSchema] = [:]
        for dep in saved.dependencies {
            dependencyMap[dep.name] = dep
        }
        
        try compareSchemas(
            current: current,
            saved: saved.root,
            dependencies: dependencyMap,
            path: "$"
        )
    }
    
    private static func compareSchemas(
        current: DynamicGenerationSchema,
        saved: DynamicGenerationSchema,
        dependencies: [String: DynamicGenerationSchema],
        path: String
    ) throws {
        
        switch (current.schemaType, saved.schemaType) {
        case (.object(let currentProps), .object(let savedProps)):
            try compareObjectSchemas(
                currentProps: currentProps,
                savedProps: savedProps,
                dependencies: dependencies,
                path: path
            )
            
        case (.array(let currentOf, let currentMin, let currentMax),
              .array(let savedOf, let savedMin, let savedMax)):
            if currentMin != savedMin {
                throw ValidationError(
                    path: path,
                    reason: "Array minimum elements mismatch: expected \(currentMin ?? -1), got \(savedMin ?? -1)"
                )
            }
            if currentMax != savedMax {
                throw ValidationError(
                    path: path,
                    reason: "Array maximum elements mismatch: expected \(currentMax ?? -1), got \(savedMax ?? -1)"
                )
            }
            // Compare array element schemas
            try compareSchemas(
                current: currentOf,
                saved: savedOf,
                dependencies: dependencies,
                path: "\(path)[]"
            )
            
        case (.reference(let currentRef), .reference(let savedRef)):
            if currentRef != savedRef {
                throw ValidationError(
                    path: path,
                    reason: "Reference mismatch: expected '\(currentRef)', got '\(savedRef)'"
                )
            }
            
        case (.reference(let refName), _):
            guard let resolvedSchema = dependencies[refName] else {
                throw ValidationError(
                    path: path,
                    reason: "Unresolved reference: '\(refName)'"
                )
            }
            try compareSchemas(
                current: resolvedSchema,
                saved: saved,
                dependencies: dependencies,
                path: path
            )
            
        case (_, .reference(let refName)):
            guard let resolvedSchema = dependencies[refName] else {
                throw ValidationError(
                    path: path,
                    reason: "Unresolved reference in saved schema: '\(refName)'"
                )
            }
            try compareSchemas(
                current: current,
                saved: resolvedSchema,
                dependencies: dependencies,
                path: path
            )
            
        case (.anyOf(let currentSchemas), .anyOf(let savedSchemas)):
            // AnyOf schemas are now directly DynamicGenerationSchema
            try compareAnyOfSchemas(
                current: currentSchemas,
                saved: savedSchemas,
                dependencies: dependencies,
                path: path
            )
            
        case (.generic, _), (_, .generic):
            throw ValidationError(
                path: path,
                reason: "Generic schemas cannot be validated (contains runtime type information)"
            )
            
        default:
            throw ValidationError(
                path: path,
                reason: "Schema type mismatch: \(type(of: current.schemaType)) vs \(type(of: saved.schemaType))"
            )
        }
    }
    
    private static func compareObjectSchemas(
        currentProps: [DynamicGenerationSchema.Property],
        savedProps: [DynamicGenerationSchema.Property],
        dependencies: [String: DynamicGenerationSchema],
        path: String
    ) throws {
        if currentProps.count != savedProps.count {
            throw ValidationError(
                path: path,
                reason: "Property count mismatch: expected \(currentProps.count), got \(savedProps.count)"
            )
        }
        
        for (index, (currentProp, savedProp)) in zip(currentProps, savedProps).enumerated() {
            let propPath = "\(path).\(currentProp.name)"
            
            if currentProp.name != savedProp.name {
                throw ValidationError(
                    path: "\(path)[property \(index)]",
                    reason: "Property order/name mismatch: expected '\(currentProp.name)', got '\(savedProp.name)'"
                )
            }
            
            if currentProp.isOptional != savedProp.isOptional {
                throw ValidationError(
                    path: propPath,
                    reason: "Optionality mismatch: expected \(currentProp.isOptional ? "optional" : "required"), got \(savedProp.isOptional ? "optional" : "required")"
                )
            }
            
            // Compare property schemas
            try compareSchemas(
                current: currentProp.schema,
                saved: savedProp.schema,
                dependencies: dependencies,
                path: propPath
            )
        }
    }
    
    private static func compareAnyOfSchemas(
        current: [DynamicGenerationSchema],
        saved: [DynamicGenerationSchema],
        dependencies: [String: DynamicGenerationSchema],
        path: String
    ) throws {
        let currentIsEnum = current.allSatisfy { 
            if case .object(let props) = $0.schemaType {
                return props.isEmpty && $0.description == nil
            }
            return false
        }
        
        let savedIsEnum = saved.allSatisfy {
            if case .object(let props) = $0.schemaType {
                return props.isEmpty && $0.description == nil
            }
            return false
        }
        
        if currentIsEnum && savedIsEnum {
            let currentValues = current.map { $0.name }.sorted()
            let savedValues = saved.map { $0.name }.sorted()
            
            if currentValues != savedValues {
                throw ValidationError(
                    path: path,
                    reason: "Enumeration values mismatch: expected \(currentValues), got \(savedValues)"
                )
            }
        } else {
            if current.count != saved.count {
                throw ValidationError(
                    path: path,
                    reason: "Union type count mismatch: expected \(current.count), got \(saved.count)"
                )
            }
            
            for (index, (currentSchema, savedSchema)) in zip(current, saved).enumerated() {
                try compareSchemas(
                    current: currentSchema,
                    saved: savedSchema,
                    dependencies: dependencies,
                    path: "\(path)[anyOf:\(index)]"
                )
            }
        }
    }
    
    static func fingerprint(
        root: DynamicGenerationSchema,
        dependencies: [DynamicGenerationSchema]
    ) -> String {
        var hasher = Hasher()
        hasher.combine(root.name)
        hasher.combine(root.description)
        for dep in dependencies.sorted(by: { $0.name < $1.name }) {
            hasher.combine(dep.name)
        }
        return String(hasher.finalize())
    }
}