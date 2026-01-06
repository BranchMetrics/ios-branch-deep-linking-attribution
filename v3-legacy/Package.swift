// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "BranchSDK",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
    ],
    products: [
        // Main product that clients will import
        .library(
            name: "BranchSDK",
            targets: ["BranchSDK", "BranchSwiftSDK"]),
    ],
    dependencies: [
        // Add external dependencies here if needed
        // .package(url: "https://github.com/google/GoogleUtilities.git", from: "7.0.0"),
        // .package(url: "https://github.com/firebase/nanopb.git", from: "2.30909.0"),
    ],
    targets: [
        // Main Objective-C SDK target
        .target(
            name: "BranchSDK",
            dependencies: [],
            path: "Sources/BranchSDK",
            publicHeadersPath: "Public",
            cSettings: [
                .headerSearchPath("Private"),
                .define("SWIFT_PACKAGE")
            ],
            linkerSettings: [
                .linkedFramework("CoreServices"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("WebKit", .when(platforms: [.iOS])),
                .linkedFramework("CoreSpotlight", .when(platforms: [.iOS])),
                .linkedFramework("AdServices", .when(platforms: [.iOS]))
            ]
        ),
        // Swift Concurrency layer (depends on main SDK)
        .target(
            name: "BranchSwiftSDK",
            dependencies: ["BranchSDK"],
            path: "Sources/BranchSwiftSDK",
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]
        )
    ]
)
