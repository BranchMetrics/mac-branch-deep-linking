// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Branch",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .library(
            name: "Branch",
            targets: ["Branch"]),
    ],
    targets: [
        .target(
            name: "Branch",
            path: "Branch",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("../"),
                ]
        ),
    ]
)

