// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsaSmartReminderKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "AsaSmartReminderKit",
            targets: ["AsaSmartReminderKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsaSmartReminderKit",
            dependencies: [],
            path: "Sources/AsaSmartReminderKit"
        ),
        .testTarget(
            name: "AsaSmartReminderKitTests",
            dependencies: ["AsaSmartReminderKit"],
            path: "Tests/AsaSmartReminderKitTests"
        ),
    ]
)
