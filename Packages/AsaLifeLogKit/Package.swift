// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AsaLifeLogKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "AsaLifeLogKit", targets: ["AsaLifeLogKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsaLifeLogKit",
            dependencies: [],
            path: "Sources/AsaLifeLogKit"
        ),
        .testTarget(
            name: "AsaLifeLogKitTests",
            dependencies: ["AsaLifeLogKit"],
            path: "Tests/AsaLifeLogKitTests"
        ),
    ]
)
