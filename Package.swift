// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Branch",
    products: [
        .library(name: "Branch", targets: ["Branch"])
    ],
    targets: [
        .target(
            name: "Branch",
            path: "Branch-SDK",
            publicHeadersPath: "."
        )
    ]
)

