// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsaFamilyTreeKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AsaFamilyTreeKit",
            targets: ["AsaFamilyTreeKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsaFamilyTreeKit",
            dependencies: [],
            path: "Sources/AsaFamilyTreeKit"
        ),
        .testTarget(
            name: "AsaFamilyTreeKitTests",
            dependencies: ["AsaFamilyTreeKit"],
            path: "Tests/AsaFamilyTreeKitTests"
        ),
    ]
)
