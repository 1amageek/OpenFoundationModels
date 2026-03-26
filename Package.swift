// swift-tools-version: 6.2

import PackageDescription

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
            name: "OpenFoundationModels",
            targets: ["OpenFoundationModels"]),
        .library(
            name: "OpenFoundationModelsExtra",
            targets: ["OpenFoundationModelsExtra"]),
    ],
    dependencies: [
        .package(url: "https://github.com/1amageek/swift-generation.git", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.1.1"),
        .package(url: "https://github.com/mattt/JSONSchema.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "OpenFoundationModels",
            dependencies: [
                .product(name: "Generation", package: "swift-generation"),
                .product(name: "GenerationMacros", package: "swift-generation"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]
        ),

        .target(
            name: "OpenFoundationModelsExtra",
            dependencies: [
                "OpenFoundationModels",
                .product(name: "JSONSchema", package: "JSONSchema"),
            ]
        ),

        .testTarget(
            name: "OpenFoundationModelsTests",
            dependencies: ["OpenFoundationModels"]
        ),

        .testTarget(
            name: "OpenFoundationModelsExtraTests",
            dependencies: [
                "OpenFoundationModelsExtra",
                "OpenFoundationModels",
                .product(name: "GenerationMacros", package: "swift-generation"),
            ]
        )
    ]
)
