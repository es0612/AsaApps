import Foundation
import SwiftData

// MARK: - SampleDataService

/// デモ動画撮影用のサンプルデータサービス
/// プロフィール + 14件のゲームセッション履歴 + 5つの実績バッジを投入
@MainActor
public final class SampleDataService {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Init

    public init(modelContainer: ModelContainer) {
        self.modelContext = modelContainer.mainContext
    }

    // MARK: - Public Methods

    /// サンプルデータを一括投入（既存プロフィールがある場合は何もしない）
    public func loadSampleData() throws {
        // 既存プロフィールがあれば何もしない
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try modelContext.fetch(descriptor).first, !existing.name.isEmpty {
            return
        }

        // 既存の空プロフィールを削除
        if let empty = try modelContext.fetch(descriptor).first {
            modelContext.delete(empty)
        }

        // 1. プロフィールを作成
        let profile = UserProfile(
            name: "はなちゃん",
            avatarEmoji: "🐰",
            age: 6
        )
        modelContext.insert(profile)

        // 2. 過去7日分のゲームセッション履歴を生成
        let sessions = createSampleSessions(profile: profile)
        for session in sessions {
            modelContext.insert(session)
        }

        // 3. 獲得した星の合計をプロフィールに反映
        let totalStars = sessions.reduce(0) { $0 + $1.earnedStars }
        profile.totalStars = totalStars
        profile.updateLevel()

        // 4. 実績バッジを解除
        let unlockedBadges: [BadgeDefinition] = [
            .firstStar,
            .mathMaster,
            .combo5,
            .perfect,
            .starCollector100,
        ]

        let calendar = Calendar.current
        let now = Date()
        for (index, badge) in unlockedBadges.enumerated() {
            let achievement = Achievement(
                badgeId: badge.rawValue,
                title: badge.title,
                achievementDescription: badge.badgeDescription,
                emoji: badge.emoji
            )
            achievement.profile = profile
            // 過去の日付に設定（1〜5日前）
            achievement.unlockedAt = calendar.date(
                byAdding: .day,
                value: -(unlockedBadges.count - index),
                to: now
            ) ?? now
            modelContext.insert(achievement)
        }

        // 5. 一括保存
        try modelContext.save()
    }

    // MARK: - Private Helpers

    /// 過去7日分のゲームセッションを生成
    private func createSampleSessions(profile: UserProfile) -> [GameSession] {
        let calendar = Calendar.current
        let now = Date()

        // 日ごとのゲーム履歴設定（dayAgo, mode, correctAnswers, totalQuestions, stars, combo）
        let sessionConfigs: [(Int, GameMode, Int, Int, Int, Int)] = [
            // 6日前
            (6, .mathQuiz, 7, 10, 3, 3),
            // 5日前
            (5, .hiraganaPractice, 8, 10, 4, 4),
            (5, .mathQuiz, 9, 10, 5, 5),
            // 4日前
            (4, .shapePuzzle, 6, 10, 3, 2),
            (4, .mathQuiz, 10, 10, 6, 7),
            // 3日前
            (3, .hiraganaPractice, 9, 10, 5, 5),
            (3, .logicGame, 7, 10, 4, 3),
            // 2日前
            (2, .mathQuiz, 10, 10, 6, 8),
            (2, .hiraganaPractice, 8, 10, 4, 4),
            (2, .shapePuzzle, 9, 10, 5, 5),
            // 1日前
            (1, .mathQuiz, 10, 10, 6, 9),
            (1, .logicGame, 8, 10, 5, 4),
            // 今日
            (0, .hiraganaPractice, 9, 10, 5, 6),
            (0, .shapePuzzle, 10, 10, 6, 7),
        ]

        return sessionConfigs.map { (dayAgo, mode, correct, total, stars, combo) in
            let startDate = calendar.date(
                byAdding: .day,
                value: -dayAgo,
                to: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: now) ?? now
            ) ?? now

            let session = GameSession(
                gameMode: mode,
                difficulty: .easy,
                totalQuestions: total
            )
            session.profile = profile
            session.correctAnswers = correct
            session.earnedStars = stars
            session.maxCombo = combo
            session.startedAt = startDate
            session.endedAt = startDate.addingTimeInterval(180) // 3分プレイ
            session.durationSeconds = 180
            return session
        }
    }
}
