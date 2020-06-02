// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BranchSDK",
    platforms: [
        .iOS(.v8),
        .tvOS(.v9),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "BranchSDK",
            targets: ["BranchSDK"]),
    ],
    dependencies: [
        // SDK has no dependencies
    ],
    targets: [
        // Excluding the text target for now.  It has dependencies fulfilled by cocoapods
        .target(
            name: "BranchSDK",
            dependencies: [],
            cSettings: [
            .headerSearchPath("BranchSDK"),
            ]
        ),
    ]
)
