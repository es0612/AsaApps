import Foundation
import SwiftData

// MARK: - LifeLogEntry

/// ライフログの個別エントリー
///
/// 手動記録、ヘルスケア、位置情報、写真、アクティビティ、気分など
/// さまざまなソースからのログを統一的に管理する。
@Model
public final class LifeLogEntry {
    @Attribute(.unique) public var id: UUID = UUID()
    public var timestamp: Date = Date()
    public var entryTypeRawValue: String = EntryType.manual.rawValue
    public var title: String = ""
    public var content: String?
    public var moodScoreRawValue: String?
    public var tags: [String] = []
    public var latitude: Double?
    public var longitude: Double?
    public var locationName: String?
    public var photoAssetIdentifiers: [String] = []
    public var activityTypeRawValue: String?
    public var durationSeconds: Double?
    public var sourceRawValue: String = DataSource.manual.rawValue
    public var healthMetricTypeRawValue: String?
    public var healthMetricValue: Double?
    public var aiSummary: String?
    public var isFavorite: Bool = false
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    // MARK: - Computed Properties

    /// エントリー種別
    public var entryType: EntryType {
        get { EntryType(rawValue: entryTypeRawValue) ?? .manual }
        set { entryTypeRawValue = newValue.rawValue }
    }

    /// 気分スコア
    public var moodScore: MoodScore? {
        get {
            guard let raw = moodScoreRawValue else { return nil }
            return MoodScore(rawValue: raw)
        }
        set { moodScoreRawValue = newValue?.rawValue }
    }

    /// アクティビティ種別
    public var activityType: ActivityType? {
        get {
            guard let raw = activityTypeRawValue else { return nil }
            return ActivityType(rawValue: raw)
        }
        set { activityTypeRawValue = newValue?.rawValue }
    }

    /// データソース
    public var source: DataSource {
        get { DataSource(rawValue: sourceRawValue) ?? .manual }
        set { sourceRawValue = newValue.rawValue }
    }

    // MARK: - Init

    public init(
        timestamp: Date = Date(),
        entryType: EntryType = .manual,
        title: String = "",
        content: String? = nil,
        moodScore: MoodScore? = nil,
        tags: [String] = [],
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        photoAssetIdentifiers: [String] = [],
        activityType: ActivityType? = nil,
        durationSeconds: Double? = nil,
        source: DataSource = .manual,
        healthMetricTypeRawValue: String? = nil,
        healthMetricValue: Double? = nil,
        aiSummary: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.entryTypeRawValue = entryType.rawValue
        self.title = title
        self.content = content
        self.moodScoreRawValue = moodScore?.rawValue
        self.tags = tags
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.photoAssetIdentifiers = photoAssetIdentifiers
        self.activityTypeRawValue = activityType?.rawValue
        self.durationSeconds = durationSeconds
        self.sourceRawValue = source.rawValue
        self.healthMetricTypeRawValue = healthMetricTypeRawValue
        self.healthMetricValue = healthMetricValue
        self.aiSummary = aiSummary
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
