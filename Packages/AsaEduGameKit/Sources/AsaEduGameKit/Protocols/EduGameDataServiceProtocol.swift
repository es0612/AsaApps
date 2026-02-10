import Foundation
import SwiftData

// MARK: - データサービスプロトコル

/// SwiftData CRUD操作のインターフェース（DI・テスト用）
@MainActor
public protocol EduGameDataServiceProtocol: Sendable {
    /// ModelContainer への参照
    var modelContainer: ModelContainer { get }

    // MARK: - プロフィール操作

    /// プロフィールを取得（なければデフォルト作成）
    func getOrCreateProfile() throws -> UserProfile

    /// プロフィールを更新
    func updateProfile(_ profile: UserProfile) throws

    // MARK: - セッション操作

    /// 新しいセッションを作成
    func createSession(
        profile: UserProfile,
        gameMode: GameMode,
        difficulty: DifficultyLevel,
        totalQuestions: Int
    ) throws -> GameSession

    /// セッションを完了
    func completeSession(_ session: GameSession) throws

    /// 全セッションを取得
    func fetchSessions(for profile: UserProfile) throws -> [GameSession]

    /// 特定モードのセッションを取得
    func fetchSessions(
        for profile: UserProfile,
        mode: GameMode
    ) throws -> [GameSession]

    // MARK: - 学習記録操作

    /// 学習記録を追加
    func addLearningRecord(
        to session: GameSession,
        questionType: QuestionType,
        questionContent: String,
        userAnswer: String,
        correctAnswer: String,
        isCorrect: Bool,
        responseTimeSeconds: Double
    ) throws -> LearningRecord

    // MARK: - アチーブメント操作

    /// アチーブメントを解除
    func unlockAchievement(
        for profile: UserProfile,
        badge: BadgeDefinition
    ) throws -> Achievement

    /// 解除済みバッジIDリストを取得
    func unlockedBadgeIds(for profile: UserProfile) throws -> Set<String>

    // MARK: - 統計

    /// モード別の正解数を取得
    func correctAnswerCount(for profile: UserProfile, mode: GameMode) throws -> Int

    /// 連続プレイ日数を取得
    func consecutivePlayDays(for profile: UserProfile) throws -> Int

    /// プレイ済みモードの一覧を取得
    func playedModes(for profile: UserProfile) throws -> Set<GameMode>
}
