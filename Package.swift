// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "BranchSDK",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
    ],
    products: [
        .library(
            name: "BranchSDK",
            targets: ["BranchSDK"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BranchSDK",
            path: "Sources",
            exclude: [
                "Sources/BranchSDK/Private/BNCContentDiscoveryManager.h",
                "Sources/BranchSDK/BNCContentDiscoveryManager.m",
	            "Sources/BranchSDK/Private/BNCUserAgentCollector.h",
	            "Sources/BranchSDK/BNCUserAgentCollector.m",
	            "Sources/BranchSDK/Private/BNCSpotlightService.h",
	            "Sources/BranchSDK/BNCSpotlightService.m",
	            "Sources/BranchSDK/Public/BranchActivityItemProvider.h",
	            "Sources/BranchSDK/BranchActivityItemProvider.m",
	            "Sources/BranchSDK/Public/BranchCSSearchableItemAttributeSet.h",
	            "Sources/BranchSDK/BranchCSSearchableItemAttributeSet.m",
	            "Sources/BranchSDK/Public/BranchShareLink.h",
                "Sources/BranchSDK/BranchShareLink.m",
	            "Sources/BranchSDK/Public/BranchPasteControl.h",
                "Sources/BranchSDK/BranchPasteControl.m"
            ],
            sources: [
                "BranchSDK/"
            ],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy"),
            ],
            publicHeadersPath: "BranchSDK/Public/",
            cSettings: [
                .headerSearchPath("BranchSDK/Private"),
            ],
            linkerSettings: [
                .linkedFramework("CoreServices"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("WebKit", .when(platforms: [.iOS])),
                .linkedFramework("CoreSpotlight", .when(platforms: [.iOS])),
                .linkedFramework("AdServices", .when(platforms: [.iOS]))
            ]
        ),
    ]
)
