// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AsaEduGameKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "AsaEduGameKit",
            targets: ["AsaEduGameKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsaEduGameKit",
            dependencies: [],
            path: "Sources/AsaEduGameKit"
        ),
        .testTarget(
            name: "AsaEduGameKitTests",
            dependencies: ["AsaEduGameKit"],
            path: "Tests/AsaEduGameKitTests"
        ),
    ]
)
