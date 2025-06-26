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
                checksum: "23f2d42a54ed9c14e4bc1ec93c8b28f5c66c68b26988692a1c154efa1710d868"
            )
            
        ]
)
