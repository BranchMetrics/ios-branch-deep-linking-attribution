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
        // Obj-C clients get everything from `@import BranchSDK;`. Swift clients get the same from
        // `import BranchSDK`, plus `import BranchSwiftAPI` for the Swift-only APIs.
        .library(
            name: "BranchSDK",
            targets: ["BranchSDK", "BranchSwiftAPI"]
        ),
    ],
    // SwiftPM cannot vend a single mixed-language module, so the SDK is physically split into layered
    // targets: BranchObjCSDK (leaf Obj-C) <- BranchSwiftSDK (Swift) <- BranchSDK (the main Obj-C SDK)
    // <- BranchSwiftAPI (Swift written on top of the main SDK, e.g. the StoreKit 2 API).
    //
    // The main Obj-C target keeps the "BranchSDK" module name so that `@import BranchSDK;` keeps
    // working for Obj-C consumers — a Swift umbrella cannot stand in for it, because `@_exported
    // import` only re-exports for Swift name lookup and leaves Clang's `@import` seeing an empty
    // module. Swift-only API therefore lives in BranchSwiftAPI and needs its own import; extensions
    // are only visible when their defining module is imported.
    //
    // CocoaPods and the Xcode project still compile everything as one module.
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
        .target(
            name: "BranchSwiftAPI",
            dependencies: ["BranchSDK"], // Swift API layered on top of the main Obj-C SDK
            path: "Sources/BranchSDK_SwiftAPI",
            linkerSettings: [
                .linkedFramework("StoreKit"),
            ]
        ),
    ]
)
