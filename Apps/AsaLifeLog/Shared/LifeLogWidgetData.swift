import Foundation

// MARK: - LifeLogWidgetData

/// Widgetに表示するデータ
struct LifeLogWidgetData: Codable, Sendable {
    let date: Date
    let entryCount: Int
    let morningScore: Int
    let totalSteps: Int
    let sleepHours: Double?
    let moodEmoji: String?
    let moodLabel: String?
    let recentEntries: [WidgetEntry]

    init(
        date: Date = Date(),
        entryCount: Int = 0,
        morningScore: Int = 0,
        totalSteps: Int = 0,
        sleepHours: Double? = nil,
        moodEmoji: String? = nil,
        moodLabel: String? = nil,
        recentEntries: [WidgetEntry] = []
    ) {
        self.date = date
        self.entryCount = entryCount
        self.morningScore = morningScore
        self.totalSteps = totalSteps
        self.sleepHours = sleepHours
        self.moodEmoji = moodEmoji
        self.moodLabel = moodLabel
        self.recentEntries = recentEntries
    }

    static let placeholder = LifeLogWidgetData(
        entryCount: 12,
        morningScore: 75,
        totalSteps: 8500,
        sleepHours: 7.5,
        moodEmoji: "😊",
        moodLabel: "良い",
        recentEntries: [
            WidgetEntry(title: "朝のジョギング", icon: "figure.run", time: "6:30"),
            WidgetEntry(title: "読書メモ", icon: "book", time: "7:00"),
            WidgetEntry(title: "ランチ", icon: "fork.knife", time: "12:00"),
        ]
    )
}

// MARK: - WidgetEntry

/// Widget表示用のエントリー要約
struct WidgetEntry: Codable, Sendable, Identifiable {
    var id: String { title + time }
    let title: String
    let icon: String
    let time: String
}
