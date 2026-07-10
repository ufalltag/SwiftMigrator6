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
    targets: [
        .target(name: "MigratorCore"),
        .executableTarget(
            name: "MigratorCLI",
            dependencies: ["MigratorCore"]
        ),
        .testTarget(
            name: "MigratorCoreTests",
            dependencies: ["MigratorCore"]
        ),
    ]
)
