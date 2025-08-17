
// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "OpenFoundationModels",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .macCatalyst(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "OpenFoundationModelsCore",
            targets: ["OpenFoundationModelsCore"]),
        .library(
            name: "OpenFoundationModels",
            targets: ["OpenFoundationModels"]),
        .library(
            name: "OpenFoundationModelsMacros",
            targets: ["OpenFoundationModelsMacros"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "OpenFoundationModelsCore",
            dependencies: []
        ),
        
        .target(
            name: "OpenFoundationModels",
            dependencies: [
                "OpenFoundationModelsCore",
                "OpenFoundationModelsMacros",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]
        ),
        
        .macro(
            name: "OpenFoundationModelsMacrosImpl",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        
        .target(
            name: "OpenFoundationModelsMacros",
            dependencies: [
                "OpenFoundationModelsMacrosImpl",
                "OpenFoundationModelsCore"
            ]
        ),
        
        .testTarget(
            name: "OpenFoundationModelsTests",
            dependencies: ["OpenFoundationModels"]
        )
    ]
)
