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
    dependencies: [
        .package(path: "../AsaUIKit"),
    ],
    targets: [
        .target(
            name: "AsaEduGameKit",
            dependencies: [
                .product(name: "AsaUIKit", package: "AsaUIKit"),
            ],
            path: "Sources/AsaEduGameKit"
        ),
        .testTarget(
            name: "AsaEduGameKitTests",
            dependencies: ["AsaEduGameKit"],
            path: "Tests/AsaEduGameKitTests"
        ),
    ]
)
