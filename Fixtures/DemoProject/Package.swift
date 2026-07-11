// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DemoProject",
    targets: [
        .target(name: "DemoCore"),
        .target(name: "DemoUI", dependencies: ["DemoCore"]),
    ]
)
