// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Branch",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
    ],
    products: [
        .library(
            name: "Branch",
            targets: ["Branch"]),
    ],
    targets: [
        .target(
            name: "Branch",
            path: "Branch-SDK",
            publicHeadersPath: "."
        ),
    ]
)
