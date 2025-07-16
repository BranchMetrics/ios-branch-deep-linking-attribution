// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ios-branch-deep-linking-attribution",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
    ],
    products: [
        .library(
            name: "BranchSDK",
            targets: ["BranchSDK", "BranchSwiftSDK", "BranchObjCSDK"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BranchObjCSDK",
            path: "Sources/BranchSDK_ObjC",
            publicHeadersPath: "Public"
        ),
        .target(
            name: "BranchSwiftSDK",
            dependencies: ["BranchObjCSDK"], // Swift code depends on Objective-C Constants
            path: "Sources/BranchSDK_Swift"
            
        ),
        .target(
            name: "BranchSDK",
            dependencies: ["BranchSwiftSDK"],
            path: "Sources/BranchSDK",
            publicHeadersPath: "Public",
            cSettings: [
                .headerSearchPath("Private")
            ],
            linkerSettings: [
                .linkedFramework("CoreServices"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("WebKit", .when(platforms: [.iOS])),
                .linkedFramework("CoreSpotlight", .when(platforms: [.iOS])),
                .linkedFramework("AdServices", .when(platforms: [.iOS]))
            ]
        )
    ]
)
