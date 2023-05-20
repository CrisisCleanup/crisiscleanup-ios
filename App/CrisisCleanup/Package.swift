// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CrisisCleanup",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CrisisCleanup",
            targets: ["CrisisCleanup"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/uber/needle.git", .upToNextMajor(from: "0.0.23")),
    ],
    targets: [
        .target(
            name: "CrisisCleanup",
            dependencies: [
                .product(name: "NeedleFoundation", package: "needle"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "CrisisCleanupTests",
            dependencies: ["CrisisCleanup"]
        ),
    ]
)
