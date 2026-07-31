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
        // Clients import a single module, "BranchSDK".
        .library(
            name: "BranchSDK",
            targets: ["BranchSDK"]
        ),
    ],
    // SwiftPM does not support mixed-language targets, so the SDK is physically split into layered
    // targets: BranchObjCSDK (leaf Obj-C) <- BranchSwiftSDK (Swift) <- BranchCore (the main Obj-C SDK)
    // <- BranchSwiftAPI (Swift written on top of Core, e.g. the StoreKit 2 API).
    // "BranchSDK" is a thin Swift umbrella that @_exported-imports all four, so consumers only need
    // `import BranchSDK`. CocoaPods and the Xcode project still compile everything as one module.
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
            name: "BranchCore",
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
        .target(
            name: "BranchSwiftAPI",
            dependencies: ["BranchCore"], // Swift API layered on top of the main Obj-C SDK
            path: "Sources/BranchSDK_SwiftAPI",
            linkerSettings: [
                .linkedFramework("StoreKit"),
            ]
        ),
        .target(
            name: "BranchSDK",
            dependencies: ["BranchSwiftAPI", "BranchCore", "BranchSwiftSDK", "BranchObjCSDK"],
            path: "Sources/BranchUmbrella"
        ),
    ]
)
