// swift-tools-version: 5.9
//
//  Package.swift
//  AsaHealthKit
//
//  健康・フィットネス関連アプリ用共有ライブラリ
//  AsaWaterTracker、AsaSleepAnalyzer、AsaStepCounter、AsaFitnessGoal等で使用
//

import PackageDescription

let package = Package(
    name: "AsaHealthKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AsaHealthKit", 
            targets: ["AsaHealthKit"]
        )
    ],
    dependencies: [
        .package(path: "../AsaCoreKit")
    ],
    targets: [
        .target(
            name: "AsaHealthKit",
            dependencies: ["AsaCoreKit"],
            path: "Sources/AsaHealthKit"
        ),
        .testTarget(
            name: "AsaHealthKitTests",
            dependencies: ["AsaHealthKit"],
            path: "Tests/AsaHealthKitTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)