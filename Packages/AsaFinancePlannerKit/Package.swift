// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AsaFinancePlannerKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "AsaFinancePlannerKit", targets: ["AsaFinancePlannerKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsaFinancePlannerKit",
            dependencies: [],
            path: "Sources/AsaFinancePlannerKit"
        ),
        .testTarget(
            name: "AsaFinancePlannerKitTests",
            dependencies: ["AsaFinancePlannerKit"],
            path: "Tests/AsaFinancePlannerKitTests"
        ),
    ]
)
