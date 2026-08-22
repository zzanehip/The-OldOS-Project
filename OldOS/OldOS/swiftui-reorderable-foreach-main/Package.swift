// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIReorderableForEach",
    platforms: [
        .iOS(.v16)
        ],
    products: [
        .library(
            name: "SwiftUIReorderableForEach",
            targets: ["SwiftUIReorderableForEach"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftUIReorderableForEach",
            dependencies: []),
    ]
)
