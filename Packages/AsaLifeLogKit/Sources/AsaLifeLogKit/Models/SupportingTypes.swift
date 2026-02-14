import Foundation

// MARK: - PhotoAssetInfo

/// 写真アセット情報
public struct PhotoAssetInfo: Sendable, Identifiable {
    public let id: String
    public let createdDate: Date?
    public let location: PhotoLocation?

    public init(id: String, createdDate: Date? = nil, location: PhotoLocation? = nil) {
        self.id = id
        self.createdDate = createdDate
        self.location = location
    }
}

// MARK: - PhotoLocation

/// 写真の位置情報
public struct PhotoLocation: Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - ActivityRecord

/// アクティビティ記録
public struct ActivityRecord: Sendable, Identifiable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let activityType: ActivityType
    public let confidence: Double

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        activityType: ActivityType,
        confidence: Double
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.activityType = activityType
        self.confidence = confidence
    }
}

// MARK: - DailyInsightResult

/// 日次インサイト結果
public struct DailyInsightResult: Sendable {
    public let date: Date
    public let summaryText: String
    public let morningScore: Int
    public let highlightEntryId: UUID?
    public let suggestions: [String]

    public init(
        date: Date,
        summaryText: String,
        morningScore: Int,
        highlightEntryId: UUID? = nil,
        suggestions: [String] = []
    ) {
        self.date = date
        self.summaryText = summaryText
        self.morningScore = morningScore
        self.highlightEntryId = highlightEntryId
        self.suggestions = suggestions
    }
}

// MARK: - WeeklyInsightResult

/// 週次インサイト結果
public struct WeeklyInsightResult: Sendable {
    public let weekStartDate: Date
    public let summaryText: String
    public let topTags: [String]
    public let moodTrend: String
    public let comparisonText: String?

    public init(
        weekStartDate: Date,
        summaryText: String,
        topTags: [String] = [],
        moodTrend: String = "",
        comparisonText: String? = nil
    ) {
        self.weekStartDate = weekStartDate
        self.summaryText = summaryText
        self.topTags = topTags
        self.moodTrend = moodTrend
        self.comparisonText = comparisonText
    }
}

// MARK: - PatternResult

/// パターン検出結果
public struct PatternResult: Sendable, Identifiable {
    public let id: UUID
    public let patternType: String
    public let description: String
    public let confidence: Double
    public let relatedTags: [String]

    public init(
        id: UUID = UUID(),
        patternType: String,
        description: String,
        confidence: Double,
        relatedTags: [String] = []
    ) {
        self.id = id
        self.patternType = patternType
        self.description = description
        self.confidence = confidence
        self.relatedTags = relatedTags
    }
}
