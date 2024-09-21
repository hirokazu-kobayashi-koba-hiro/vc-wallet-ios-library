// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vc-wallet-ios-library",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "vc-wallet-ios-library",
            targets: ["vc-wallet-ios-library"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "vc-wallet-ios-library"),
        .testTarget(
            name: "vc-wallet-ios-libraryTests",
            dependencies: ["vc-wallet-ios-library"]),
    ]
)
