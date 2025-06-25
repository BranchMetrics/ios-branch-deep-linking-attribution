// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ios-branch-deep-linking-attribution",
    platforms: [
            .iOS(.v13),
            .tvOS(.v13),
        ],
        products: [
            .library(
                name: "BranchSDK",
                targets: ["BranchSDKBinary"]
            ),
        ],
        targets: [
            .binaryTarget(
                name: "BranchSDKBinary",
                url: "https://github.com/NidhiDixit09/nidhidixit09.github.io/raw/refs/heads/main/Branch.zip",
                checksum: "ac2fe6717dda43cc2e9674f549937a6ab487447698451e4c2a823b6b26ce16ac"
            )
            
        ]
)
