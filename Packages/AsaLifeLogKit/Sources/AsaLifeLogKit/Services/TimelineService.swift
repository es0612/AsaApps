import Foundation

// MARK: - TimelineService

/// タイムライン構築サービス
///
/// 複数ソース（手動入力、HealthKit、位置情報、写真、モーション）からの
/// エントリーを統合し、時系列タイムラインを構築する。
@MainActor
public final class TimelineService: TimelineServiceProtocol {
    // MARK: - Init

    public init() {}

    // MARK: - TimelineServiceProtocol

    /// 指定日のタイムラインを構築する
    public func buildTimeline(
        for date: Date,
        dataService: any LifeLogDataServiceProtocol
    ) async throws -> [LifeLogEntry] {
        let entries = try await dataService.fetchEntries(for: date)
        // タイムスタンプ順でソート（新しい順）
        return entries.sorted { $0.timestamp > $1.timestamp }
    }

    /// 全ソースからデータを取り込みリフレッシュする
    public func refreshFromAllSources(
        dataService: any LifeLogDataServiceProtocol,
        healthEntries: [LifeLogEntry],
        locationEntries: [LifeLogEntry],
        photoEntries: [LifeLogEntry],
        activityEntries: [LifeLogEntry]
    ) async throws {
        let allNewEntries = healthEntries + locationEntries + photoEntries + activityEntries
        for entry in allNewEntries {
            try await dataService.saveEntry(entry)
        }
    }
}
