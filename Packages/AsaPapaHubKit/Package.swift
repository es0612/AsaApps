// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AsaPapaHubKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "AsaPapaHubKit", targets: ["AsaPapaHubKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsaPapaHubKit",
            dependencies: [],
            path: "Sources/AsaPapaHubKit"
        ),
        .testTarget(
            name: "AsaPapaHubKitTests",
            dependencies: ["AsaPapaHubKit"],
            path: "Tests/AsaPapaHubKitTests"
        ),
    ]
)
