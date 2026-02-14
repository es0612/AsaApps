import Foundation

// MARK: - CommunityFeedServiceProtocol

/// バックエンド抽象化プロトコル（将来のCloudKit/API接続用）
@MainActor
public protocol CommunityFeedServiceProtocol {
    /// サーバーからの最新投稿を取得
    func fetchLatestPosts(since: Date?) async throws -> [CommunityPost]

    /// サーバーからの最新イベントを取得
    func fetchLatestEvents(since: Date?) async throws -> [CommunityEvent]

    /// サーバーからの安全アラートを取得
    func fetchSafetyAlerts() async throws -> [SafetyReport]

    /// 投稿をサーバーに送信
    func submitPost(_ post: CommunityPost) async throws

    /// イベントをサーバーに送信
    func submitEvent(_ event: CommunityEvent) async throws

    /// 安全レポートをサーバーに送信
    func submitSafetyReport(_ report: SafetyReport) async throws
}
