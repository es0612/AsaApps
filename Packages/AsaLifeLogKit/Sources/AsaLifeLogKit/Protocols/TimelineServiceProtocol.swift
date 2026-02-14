import Foundation

// MARK: - TimelineServiceProtocol

/// タイムライン構築プロトコル
///
/// 複数ソースからのエントリーを統合し、時系列のタイムラインを構築する。
@MainActor
public protocol TimelineServiceProtocol: Sendable {
    /// 指定日のタイムラインを構築する
    func buildTimeline(
        for date: Date,
        dataService: any LifeLogDataServiceProtocol
    ) async throws -> [LifeLogEntry]

    /// 全ソースからデータを取り込みリフレッシュする
    func refreshFromAllSources(
        dataService: any LifeLogDataServiceProtocol,
        healthEntries: [LifeLogEntry],
        locationEntries: [LifeLogEntry],
        photoEntries: [LifeLogEntry],
        activityEntries: [LifeLogEntry]
    ) async throws
}
