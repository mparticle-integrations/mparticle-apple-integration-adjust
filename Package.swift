// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mparticle-apple-integration-adjust",
    platforms: [ .iOS(.v9), .tvOS(.v9) ],
    products: [
        .library(
            name: "mparticle-apple-integration-adjust",
            targets: ["mparticle-apple-integration-adjust"]),
    ],
    dependencies: [
      .package(name: "mParticle-Apple-SDK",
               url: "https://github.com/mParticle/mparticle-apple-sdk",
               .upToNextMajor(from: "8.0.0")),
      .package(name: "Adjust",
               url: "https://github.com/adjust/ios_sdk",
               .upToNextMajor(from: "4.20.0")),
    ],
    targets: [
        .target(
            name: "mparticle-apple-integration-adjust",
            dependencies: [
              .byName(name: "mParticle-Apple-SDK"),
              .byName(name: "Adjust")
            ]
        )
    ]
)
