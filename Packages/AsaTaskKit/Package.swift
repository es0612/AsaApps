// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AsaTaskKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AsaTaskKit",
            targets: ["AsaTaskKit"]
        ),
    ],
    dependencies: [
        .package(path: "../AsaUIKit")
    ],
    targets: [
        .target(
            name: "AsaTaskKit",
            dependencies: ["AsaUIKit"],
            path: "Sources/AsaTaskKit"
        ),
        .testTarget(
            name: "AsaTaskKitTests",
            dependencies: ["AsaTaskKit"],
            path: "Tests/AsaTaskKitTests"
        ),
    ]
)