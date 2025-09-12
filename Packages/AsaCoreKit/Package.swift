// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AsaCoreKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AsaCoreKit",
            targets: ["AsaCoreKit"]
        ),
    ],
    dependencies: [
        // 将来的にAsaUIKitへの依存を追加する可能性
        // .package(path: "../AsaUIKit")
    ],
    targets: [
        .target(
            name: "AsaCoreKit",
            dependencies: [],
            path: "Sources/AsaCoreKit"
        ),
        .testTarget(
            name: "AsaCoreKitTests",
            dependencies: ["AsaCoreKit"],
            path: "Tests/AsaCoreKitTests"
        ),
    ]
)