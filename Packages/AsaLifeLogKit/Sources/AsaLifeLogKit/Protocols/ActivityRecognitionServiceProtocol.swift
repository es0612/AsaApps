import Foundation

// MARK: - ActivityRecognitionServiceProtocol

/// アクティビティ認識プロトコル
///
/// CoreMotion のラッパーとして、歩行・走行・自転車等のアクティビティ検出を提供する。
@MainActor
public protocol ActivityRecognitionServiceProtocol: Sendable {
    /// モーション＆フィットネスのアクセス許可をリクエストする
    func requestAuthorization() async -> Bool

    /// アクティビティモニタリングを開始する
    func startMonitoring()

    /// アクティビティモニタリングを停止する
    func stopMonitoring()

    /// 指定期間のアクティビティ記録を取得する
    func fetchActivities(from startDate: Date, to endDate: Date) async throws -> [ActivityRecord]
}
