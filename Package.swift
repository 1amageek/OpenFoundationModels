// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "OpenFoundationModels",
    platforms: [
        // ✅ CONFIRMED: Apple Foundation Models requires iOS 26.0+/macOS 26.0+ Beta
        // Using closest available versions - will need update when 26.0 releases
        .macOS(.v15),         // Target: macOS 26.0+ Beta
        .iOS(.v18),           // Target: iOS 26.0+ Beta
        // Note: tvOS and watchOS not supported by Apple Foundation Models
        .macCatalyst(.v18),   // Target: Mac Catalyst 26.0+ Beta
        .visionOS(.v2)        // Target: visionOS 26.0+ Beta
    ],
    products: [
        // Main library
        .library(
            name: "OpenFoundationModels",
            targets: ["OpenFoundationModels"]),
        // Macro library
        .library(
            name: "OpenFoundationModelsMacros",
            targets: ["OpenFoundationModelsMacros"]),
    ],
    dependencies: [
        // Swift Syntax for macro implementation
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        // Async algorithms for streaming
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
    ],
    targets: [
        // Main library target
        .target(
            name: "OpenFoundationModels",
            dependencies: [
                "OpenFoundationModelsMacros",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]
        ),
        
        // Macro implementations
        .macro(
            name: "OpenFoundationModelsMacrosImpl",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        
        // Macro library
        .target(
            name: "OpenFoundationModelsMacros",
            dependencies: ["OpenFoundationModelsMacrosImpl"]
        ),
        
        // Tests
        .testTarget(
            name: "OpenFoundationModelsTests",
            dependencies: ["OpenFoundationModels"]
        ),
        
        // Macro tests
        .testTarget(
            name: "OpenFoundationModelsMacrosTests",
            dependencies: [
                "OpenFoundationModelsMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
