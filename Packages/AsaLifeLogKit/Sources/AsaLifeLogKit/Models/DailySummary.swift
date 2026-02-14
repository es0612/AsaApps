import Foundation
import SwiftData

// MARK: - DailySummary

/// 日次サマリー
///
/// その日のライフログを集約し、歩数・気分・睡眠・活動パターンなどを要約する。
@Model
public final class DailySummary {
    @Attribute(.unique) public var id: UUID = UUID()
    public var date: Date = Date()
    public var entryCount: Int = 0
    public var moodAverage: Double?
    public var totalSteps: Int = 0
    public var totalDistanceKm: Double = 0.0
    public var sleepHours: Double?
    public var waterIntakeMl: Double?
    public var dominantActivityRawValue: String?
    public var visitedPlaces: [String] = []
    public var photoCount: Int = 0
    public var aiInsightText: String?
    public var highlightEntryId: UUID?

    // MARK: - Computed Properties

    /// 主要アクティビティ
    public var dominantActivity: ActivityType? {
        get {
            guard let raw = dominantActivityRawValue else { return nil }
            return ActivityType(rawValue: raw)
        }
        set { dominantActivityRawValue = newValue?.rawValue }
    }

    /// 朝活スコア（0〜100）
    ///
    /// エントリー数と気分平均を元にした簡易スコア。
    /// 詳細な朝活スコアは InsightsEngine で計算する。
    public var morningScore: Int {
        let entryScore = min(entryCount * 10, 50)
        let moodScore = Int((moodAverage ?? 3.0) * 10.0)
        return min(entryScore + moodScore, 100)
    }

    // MARK: - Init

    public init(
        date: Date = Date(),
        entryCount: Int = 0,
        moodAverage: Double? = nil,
        totalSteps: Int = 0,
        totalDistanceKm: Double = 0.0,
        sleepHours: Double? = nil,
        waterIntakeMl: Double? = nil,
        dominantActivity: ActivityType? = nil,
        visitedPlaces: [String] = [],
        photoCount: Int = 0,
        aiInsightText: String? = nil,
        highlightEntryId: UUID? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.entryCount = entryCount
        self.moodAverage = moodAverage
        self.totalSteps = totalSteps
        self.totalDistanceKm = totalDistanceKm
        self.sleepHours = sleepHours
        self.waterIntakeMl = waterIntakeMl
        self.dominantActivityRawValue = dominantActivity?.rawValue
        self.visitedPlaces = visitedPlaces
        self.photoCount = photoCount
        self.aiInsightText = aiInsightText
        self.highlightEntryId = highlightEntryId
    }
}
