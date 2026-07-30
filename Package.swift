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
            targets: ["BranchSDK", "BranchSwiftSDK", "BranchObjCSDK"]
        ),
    ],
    // SwiftPM does not support mixed-language targets, so the SDK is split into three
    // targets that layer bottom-up: BranchObjCSDK (leaf Obj-C) <- BranchSwiftSDK (Swift)
    // <- BranchSDK (the main Obj-C SDK). CocoaPods and the Xcode project still compile
    // everything as one mixed-language module.
    targets: [
        .target(
            name: "BranchObjCSDK",
            path: "Sources/BranchSDK_ObjC",
            publicHeadersPath: "Public"
        ),
        .target(
            name: "BranchSwiftSDK",
            dependencies: ["BranchObjCSDK"], // Swift code depends on the leaf Obj-C target
            path: "Sources/BranchSDK_Swift"
        ),
        .target(
            name: "BranchSDK",
            dependencies: ["BranchSwiftSDK"],
            path: "Sources/BranchSDK",
            publicHeadersPath: "Public",
            cSettings: [
                .headerSearchPath("Private"),
            ],
            linkerSettings: [
                .linkedFramework("CoreServices"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("WebKit", .when(platforms: [.iOS])),
                .linkedFramework("CoreSpotlight", .when(platforms: [.iOS])),
                .linkedFramework("AdServices", .when(platforms: [.iOS])),
            ]
        ),
    ]
)
