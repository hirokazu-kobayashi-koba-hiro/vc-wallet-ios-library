// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "VcWalletLibrary",
  platforms: [
    .iOS(.v16)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "VcWalletLibrary",
      targets: ["VcWalletLibrary"])
  ],
  dependencies: [
    // Reference to your internal library
    .package(url: "https://github.com/airsidemobile/JOSESwift.git", from: "3.0.0"),
    .package(
      url: "https://github.com/eu-digital-identity-wallet/eudi-lib-sdjwt-swift.git",
      .upToNextMajor(from: "0.1.0")),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "VcWalletLibrary",
      dependencies: [
        .product(name: "JOSESwift", package: "JOSESwift"),
        .product(name: "eudi-lib-sdjwt-swift", package: "eudi-lib-sdjwt-swift"),
      ]
    ),
    .testTarget(
      name: "VcWalletLibraryTests",
      dependencies: [
        "VcWalletLibrary"
      ]
    ),
  ]
)
