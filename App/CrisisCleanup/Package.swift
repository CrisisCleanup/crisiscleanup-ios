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
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.4")),
        .package(url: "https://github.com/auth0/JWTDecode.swift", .upToNextMajor(from: "3.0.1")),
        .package(url: "https://github.com/exyte/SVGView.git", .upToNextMajor(from: "1.0.4")),
        .package(url: "https://github.com/apple/swift-atomics.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "6.15.0")),
        .package(url: "https://github.com/albertbori/TestableCombinePublishers.git", .upToNextMajor(from: "1.2.0")),
    ],
    targets: [
        .target(
            name: "CrisisCleanup",
            dependencies: [
                .product(name: "NeedleFoundation", package: "needle"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "JWTDecode", package: "JWTDecode.swift"),
                .product(name: "SVGView", package: "SVGView"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "CrisisCleanupTests",
            dependencies: [
                "CrisisCleanup",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "TestableCombinePublishers", package: "TestableCombinePublishers"),
            ],
            resources: [
                .copy("TestResources"),
            ]
        ),
    ]
)
