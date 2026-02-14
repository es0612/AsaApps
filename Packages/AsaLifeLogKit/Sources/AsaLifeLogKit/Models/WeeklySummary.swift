import Foundation
import SwiftData

// MARK: - WeeklySummary

/// 週次サマリー
///
/// 1週間のライフログを集約し、トレンドや前週との比較を提供する。
@Model
public final class WeeklySummary {
    @Attribute(.unique) public var id: UUID = UUID()
    public var weekStartDate: Date = Date()
    public var weekEndDate: Date = Date()
    public var entryCount: Int = 0
    public var averageMood: Double?
    public var totalSteps: Int = 0
    public var averageSleepHours: Double?
    public var topTags: [String] = []
    public var trendInsight: String?
    public var comparisonWithPreviousWeek: String?

    // MARK: - Init

    public init(
        weekStartDate: Date = Date(),
        weekEndDate: Date = Date(),
        entryCount: Int = 0,
        averageMood: Double? = nil,
        totalSteps: Int = 0,
        averageSleepHours: Double? = nil,
        topTags: [String] = [],
        trendInsight: String? = nil,
        comparisonWithPreviousWeek: String? = nil
    ) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.entryCount = entryCount
        self.averageMood = averageMood
        self.totalSteps = totalSteps
        self.averageSleepHours = averageSleepHours
        self.topTags = topTags
        self.trendInsight = trendInsight
        self.comparisonWithPreviousWeek = comparisonWithPreviousWeek
    }
}
