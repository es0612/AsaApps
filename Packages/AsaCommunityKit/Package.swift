// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AsaCommunityKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "AsaCommunityKit", targets: ["AsaCommunityKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsaCommunityKit",
            dependencies: [],
            path: "Sources/AsaCommunityKit"
        ),
        .testTarget(
            name: "AsaCommunityKitTests",
            dependencies: ["AsaCommunityKit"],
            path: "Tests/AsaCommunityKitTests"
        ),
    ]
)
