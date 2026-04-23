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
            name: "OpenFoundationModelsCore",
            targets: ["OpenFoundationModelsCore"]),
        .library(
            name: "OpenFoundationModels",
            targets: ["OpenFoundationModels"]),
        .library(
            name: "OpenFoundationModelsExtra",
            targets: ["OpenFoundationModelsExtra"]),
    ],
    dependencies: [
        .package(url: "https://github.com/1amageek/swift-generation.git", from: "0.5.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.1.1"),
        .package(url: "https://github.com/mattt/JSONSchema.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "OpenFoundationModelsCore",
            dependencies: [
                .product(
                    name: "SwiftGeneration",
                    package: "swift-generation"
                ),
            ]
        ),
        .target(
            name: "OpenFoundationModels",
            dependencies: [
                "OpenFoundationModelsCore",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]
        ),

        .target(
            name: "OpenFoundationModelsExtra",
            dependencies: [
                "OpenFoundationModels",
                "OpenFoundationModelsCore",
                .product(name: "JSONSchema", package: "JSONSchema"),
            ]
        ),

        .testTarget(
            name: "OpenFoundationModelsTests",
            dependencies: [
                "OpenFoundationModels",
                "OpenFoundationModelsExtra",
                "OpenFoundationModelsCore",
            ]
        ),

        .testTarget(
            name: "OpenFoundationModelsExtraTests",
            dependencies: [
                "OpenFoundationModelsExtra",
                "OpenFoundationModels",
                "OpenFoundationModelsCore",
            ]
        )
    ]
)
