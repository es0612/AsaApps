// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AsaUIKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AsaUIKit",
            targets: ["AsaUIKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsaUIKit",
            dependencies: [],
            path: "Sources/AsaUIKit"
        ),
        .testTarget(
            name: "AsaUIKitTests",
            dependencies: ["AsaUIKit"],
            path: "Tests/AsaUIKitTests"
        ),
    ]
)