import Foundation

// MARK: - 進捗ダッシュボードViewModel

/// 学習進捗の統計表示を管理
@Observable
@MainActor
public final class ProgressViewModel {

    // MARK: - Dependencies

    /// データサービス（DI）
    private let dataService: EduGameDataServiceProtocol

    // MARK: - Properties

    /// ユーザープロフィール
    public var profile: UserProfile?

    /// 最近のゲームセッション一覧
    public var recentSessions: [GameSession] = []

    /// ゲームモード別の統計データ
    public var modeStats: [GameMode: ModeStatistics] = [:]

    /// 読み込み中フラグ
    public var isLoading: Bool = false

    // MARK: - 統計データ構造体

    /// ゲームモード別の統計情報
    public struct ModeStatistics: Sendable {
        /// 総セッション数
        public let totalSessions: Int
        /// 総正解数
        public let totalCorrect: Int
        /// 総出題数
        public let totalQuestions: Int
        /// 平均正答率
        public let averageAccuracy: Double
        /// 最高コンボ数
        public let bestCombo: Int

        public init(
            totalSessions: Int,
            totalCorrect: Int,
            totalQuestions: Int,
            averageAccuracy: Double,
            bestCombo: Int
        ) {
            self.totalSessions = totalSessions
            self.totalCorrect = totalCorrect
            self.totalQuestions = totalQuestions
            self.averageAccuracy = averageAccuracy
            self.bestCombo = bestCombo
        }
    }

    // MARK: - Init

    public init(dataService: EduGameDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    /// 進捗データを読み込み、統計を計算する
    public func loadProgress() {
        isLoading = true

        do {
            // プロフィール取得
            let loadedProfile = try dataService.getOrCreateProfile()
            profile = loadedProfile

            // 全セッション取得
            let allSessions = try dataService.fetchSessions(for: loadedProfile)

            // 最近のセッション（新しい順に最大20件）
            recentSessions = allSessions
                .sorted { $0.startedAt > $1.startedAt }
                .prefix(20)
                .map { $0 }

            // モード別統計を計算
            calculateModeStats(sessions: allSessions)
        } catch {
            // エラー時は空状態にリセット
            recentSessions = []
            modeStats = [:]
        }

        isLoading = false
    }

    /// セッション一覧からモード別統計を計算
    func calculateModeStats(sessions: [GameSession]) {
        var stats: [GameMode: ModeStatistics] = [:]

        for mode in GameMode.allCases {
            let modeSessions = sessions.filter { $0.gameMode == mode }

            guard !modeSessions.isEmpty else {
                stats[mode] = ModeStatistics(
                    totalSessions: 0,
                    totalCorrect: 0,
                    totalQuestions: 0,
                    averageAccuracy: 0.0,
                    bestCombo: 0
                )
                continue
            }

            let totalCorrect = modeSessions.reduce(0) { $0 + $1.correctAnswers }
            let totalQuestions = modeSessions.reduce(0) { $0 + $1.totalQuestions }
            let bestCombo = modeSessions.map(\.maxCombo).max() ?? 0

            let averageAccuracy: Double
            if totalQuestions > 0 {
                averageAccuracy = Double(totalCorrect) / Double(totalQuestions)
            } else {
                averageAccuracy = 0.0
            }

            stats[mode] = ModeStatistics(
                totalSessions: modeSessions.count,
                totalCorrect: totalCorrect,
                totalQuestions: totalQuestions,
                averageAccuracy: averageAccuracy,
                bestCombo: bestCombo
            )
        }

        modeStats = stats
    }
}
