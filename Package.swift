// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MigratorKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "MigratorCore", targets: ["MigratorCore"]),
        .executable(name: "migrator", targets: ["MigratorCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", exact: "603.0.2"),
        .package(url: "https://github.com/tuist/XcodeProj", from: "9.13.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
    ],
    targets: [
        .target(
            name: "MigratorCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "XcodeProj", package: "XcodeProj"),
            ]
        ),
        .executableTarget(
            name: "MigratorCLI",
            dependencies: [
                "MigratorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "MigratorCoreTests",
            dependencies: ["MigratorCore"],
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
