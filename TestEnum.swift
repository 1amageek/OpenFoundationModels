import Foundation
import OpenFoundationModels
import OpenFoundationModelsCore
import OpenFoundationModelsMacros

@Generable
public enum TaskDifficulty: String, CaseIterable, Sendable {
    case trivial = "trivial"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
}

@Generable
public enum DependencyAction: String, Sendable {
    case add = "add"
    case remove = "remove"
}

print("TaskDifficulty schema: \(TaskDifficulty.generationSchema)")
print("DependencyAction schema: \(DependencyAction.generationSchema)")
print("✅ Enum @Generable macro test successful!")