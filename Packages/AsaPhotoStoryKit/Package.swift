// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsaPhotoStoryKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "AsaPhotoStoryKit",
            targets: ["AsaPhotoStoryKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsaPhotoStoryKit",
            dependencies: [],
            path: "Sources/AsaPhotoStoryKit"
        ),
        .testTarget(
            name: "AsaPhotoStoryKitTests",
            dependencies: ["AsaPhotoStoryKit"],
            path: "Tests/AsaPhotoStoryKitTests"
        ),
    ]
)
