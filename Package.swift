// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BranchSDK",
    platforms: [
        // iOS 13+ required for Swift concurrency (async/await, actors)
        .iOS(.v13),
        .macOS(.v12),
        // tvOS 13+ required for Swift concurrency
        .tvOS(.v13),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        // Main SDK library
        .library(
            name: "BranchSDK",
            targets: ["BranchSDK"]
        ),
        // Test utilities for SDK integrators
        .library(
            name: "BranchSDKTestKit",
            targets: ["BranchSDKTestKit"]
        ),
    ],
    dependencies: [
        // No external dependencies - pure Swift implementation
    ],
    targets: [
        // MARK: - Main SDK Target

        .target(
            name: "BranchSDK",
            dependencies: [],
            path: "Sources/BranchSDK",
            swiftSettings: [
                // Swift 6 strict concurrency is enabled by default in Swift 6
                // Enable upcoming Swift features (not yet standard in Swift 6)
                .enableUpcomingFeature("ExistentialAny"),
                // Warnings as errors for production code
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release)),
            ]
        ),

        // MARK: - Test Kit Target (for SDK integrators)

        .target(
            name: "BranchSDKTestKit",
            dependencies: ["BranchSDK"],
            path: "Sources/BranchSDKTestKit"
        ),

        // MARK: - Unit Tests

        .testTarget(
            name: "BranchSDKTests",
            dependencies: ["BranchSDK", "BranchSDKTestKit"],
            path: "Tests/BranchSDKTests"
        ),

        // MARK: - Integration Tests

        .testTarget(
            name: "BranchSDKIntegrationTests",
            dependencies: ["BranchSDK", "BranchSDKTestKit"],
            path: "Tests/BranchSDKIntegrationTests"
        ),

        // MARK: - Performance Tests

        .testTarget(
            name: "BranchSDKPerformanceTests",
            dependencies: ["BranchSDK"],
            path: "Tests/BranchSDKPerformanceTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
