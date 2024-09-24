// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VcWalletLibrary",
    platforms: [.macOS(.v13), .iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "VcWalletLibrary",
            targets: ["VcWalletLibrary"]),
    ],
    dependencies: [
            // Reference to your internal library
            .package(url: "https://github.com/airsidemobile/JOSESwift.git", from: "3.0.0")
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "VcWalletLibrary",
            dependencies: [
                    .product(name: "JOSESwift", package: "JOSESwift")
                ]
        ),
        .testTarget(
            name: "VcWalletLibraryTests",
            dependencies: [
                "VcWalletLibrary",
            ]
        ),
    ]
)
