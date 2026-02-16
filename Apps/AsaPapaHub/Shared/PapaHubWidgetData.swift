//
//  PapaHubWidgetData.swift
//  AsaPapaHub
//
//  アプリとWidget間で共有するウィジェットデータモデル
//

import Foundation

// MARK: - PapaHubWidgetData

/// Widget に表示するデータ
struct PapaHubWidgetData: Codable, Sendable {
    let date: Date
    let morningScore: Int
    let stepsCount: Int
    let sleepHours: Double
    let overallProgress: Double
    let briefingSummary: String?
    let domainScores: [DomainScore]
    let routineItems: [RoutineItemData]
    let currentRoutineItem: String?

    init(
        date: Date = Date(),
        morningScore: Int = 0,
        stepsCount: Int = 0,
        sleepHours: Double = 0.0,
        overallProgress: Double = 0.0,
        briefingSummary: String? = nil,
        domainScores: [DomainScore] = [],
        routineItems: [RoutineItemData] = [],
        currentRoutineItem: String? = nil
    ) {
        self.date = date
        self.morningScore = morningScore
        self.stepsCount = stepsCount
        self.sleepHours = sleepHours
        self.overallProgress = overallProgress
        self.briefingSummary = briefingSummary
        self.domainScores = domainScores
        self.routineItems = routineItems
        self.currentRoutineItem = currentRoutineItem
    }

    // MARK: - 保存・読み込み

    func save() {
        SharedDefaults.saveWidgetData(self)
    }

    static func load() -> PapaHubWidgetData? {
        SharedDefaults.loadWidgetData()
    }

    static let placeholder = PapaHubWidgetData(
        morningScore: 72,
        stepsCount: 6500,
        sleepHours: 7.0,
        overallProgress: 0.65,
        briefingSummary: "今日も素晴らしい朝を過ごしましょう！",
        domainScores: [
            DomainScore(domain: "朝活", icon: "sunrise.fill", score: 85),
            DomainScore(domain: "健康", icon: "heart.fill", score: 70),
            DomainScore(domain: "家族", icon: "figure.2.and.child.holdinghands", score: 60),
            DomainScore(domain: "資産", icon: "yensign.circle.fill", score: 75),
            DomainScore(domain: "地域", icon: "building.2.fill", score: 50),
            DomainScore(domain: "学習", icon: "book.fill", score: 65),
        ],
        routineItems: [
            RoutineItemData(title: "早起き", icon: "alarm.fill", isCompleted: true),
            RoutineItemData(title: "ストレッチ", icon: "figure.flexibility", isCompleted: true),
            RoutineItemData(title: "読書", icon: "book.fill", isCompleted: false),
            RoutineItemData(title: "コーディング", icon: "laptopcomputer", isCompleted: false),
        ]
    )
}

// MARK: - DomainScore

/// ドメインごとのスコア
struct DomainScore: Codable, Sendable, Identifiable {
    var id: String { domain }
    let domain: String
    let icon: String
    let score: Int
}

// MARK: - RoutineItemData

/// ルーティンアイテムデータ
struct RoutineItemData: Codable, Sendable, Identifiable {
    var id: String { title }
    let title: String
    let icon: String
    let isCompleted: Bool
}
