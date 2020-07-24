// swift-tools-version:5.1

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

