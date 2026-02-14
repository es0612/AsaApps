import Foundation

// MARK: - LifeLogDataServiceProtocol

/// ライフログデータ永続化プロトコル
///
/// SwiftData ModelContextを使ったCRUD操作を定義する。
/// テスト用にモック実装へ差し替え可能。
@MainActor
public protocol LifeLogDataServiceProtocol: Sendable {
    // MARK: - エントリー

    /// 指定日のエントリーを取得する
    func fetchEntries(for date: Date) async throws -> [LifeLogEntry]

    /// 日付範囲のエントリーを取得する
    func fetchEntries(from startDate: Date, to endDate: Date) async throws -> [LifeLogEntry]

    /// 指定データソースのエントリーを取得する
    func fetchEntries(source: DataSource) async throws -> [LifeLogEntry]

    /// エントリーを保存する
    func saveEntry(_ entry: LifeLogEntry) async throws

    /// エントリーを削除する
    func deleteEntry(_ entry: LifeLogEntry) async throws

    /// お気に入りを切り替える
    func toggleFavorite(_ entry: LifeLogEntry) async throws

    // MARK: - 日次サマリー

    /// 指定日のサマリーを取得する
    func fetchDailySummary(for date: Date) async throws -> DailySummary?

    /// 日次サマリーを保存する
    func saveDailySummary(_ summary: DailySummary) async throws

    // MARK: - 週次サマリー

    /// 指定週のサマリーを取得する
    func fetchWeeklySummary(for weekStart: Date) async throws -> WeeklySummary?

    /// 週次サマリーを保存する
    func saveWeeklySummary(_ summary: WeeklySummary) async throws

    // MARK: - 場所ログ

    /// 全ての場所ログを取得する
    func fetchPlaces() async throws -> [PlaceLog]

    /// 場所ログを保存する
    func savePlaceLog(_ place: PlaceLog) async throws

    // MARK: - ユーザー設定

    /// ユーザー設定を取得または初期作成する
    func fetchOrCreatePreferences() async throws -> UserPreferences

    /// ユーザー設定を保存する
    func savePreferences(_ preferences: UserPreferences) async throws
}
