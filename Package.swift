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
                "BranchSDK/Private/BNCContentDiscoveryManager.h",
                "BranchSDK/BNCContentDiscoveryManager.m",
	            "BranchSDK/Private/BNCUserAgentCollector.h",
	            "BranchSDK/BNCUserAgentCollector.m",
	            "BranchSDK/Private/BNCSpotlightService.h",
	            "BranchSDK/BNCSpotlightService.m",
	            "BranchSDK/Public/BranchActivityItemProvider.h",
	            "BranchSDK/BranchActivityItemProvider.m",
	            "BranchSDK/Public/BranchCSSearchableItemAttributeSet.h",
	            "BranchSDK/BranchCSSearchableItemAttributeSet.m",
	            "BranchSDK/Public/BranchShareLink.h",
                "BranchSDK/BranchShareLink.m",
	            "BranchSDK/Public/BranchPasteControl.h",
                "BranchSDK/BranchPasteControl.m"
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
