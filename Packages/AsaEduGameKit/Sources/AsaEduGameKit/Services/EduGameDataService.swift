import Foundation
import SwiftData

// MARK: - データサービス

/// SwiftDataベースのCRUD操作を提供するサービス
/// テスト時は inMemory: true で分離した環境を使用
@MainActor
public final class EduGameDataService: EduGameDataServiceProtocol {

    // MARK: - Properties

    public let modelContainer: ModelContainer
    private let modelContext: ModelContext

    // MARK: - Init

    public init(inMemory: Bool = false) {
        let schema = Schema([
            UserProfile.self,
            GameSession.self,
            LearningRecord.self,
            Achievement.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("ModelContainerの初期化に失敗: \(error)")
        }
        modelContext = modelContainer.mainContext
    }

    // MARK: - プロフィール操作

    /// プロフィールを取得（なければデフォルト作成）
    public func getOrCreateProfile() throws -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfile(name: "", avatarEmoji: "🐱", age: 5)
        modelContext.insert(profile)
        try modelContext.save()
        return profile
    }

    /// プロフィールを更新
    public func updateProfile(_ profile: UserProfile) throws {
        profile.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - セッション操作

    /// 新しいセッションを作成
    public func createSession(
        profile: UserProfile,
        gameMode: GameMode,
        difficulty: DifficultyLevel,
        totalQuestions: Int
    ) throws -> GameSession {
        let session = GameSession(
            gameMode: gameMode,
            difficulty: difficulty,
            totalQuestions: totalQuestions
        )
        session.profile = profile
        modelContext.insert(session)
        try modelContext.save()
        return session
    }

    /// セッションを完了
    public func completeSession(_ session: GameSession) throws {
        session.complete()
        try modelContext.save()
    }

    /// 全セッションを取得（開始日時の降順）
    public func fetchSessions(for profile: UserProfile) throws -> [GameSession] {
        let profileId = profile.id
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate { $0.profile?.id == profileId },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 特定モードのセッションを取得
    public func fetchSessions(
        for profile: UserProfile,
        mode: GameMode
    ) throws -> [GameSession] {
        let profileId = profile.id
        let modeRaw = mode.rawValue
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate {
                $0.profile?.id == profileId && $0.gameModeRawValue == modeRaw
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - 学習記録操作

    /// 学習記録を追加
    public func addLearningRecord(
        to session: GameSession,
        questionType: QuestionType,
        questionContent: String,
        userAnswer: String,
        correctAnswer: String,
        isCorrect: Bool,
        responseTimeSeconds: Double
    ) throws -> LearningRecord {
        let record = LearningRecord(
            questionType: questionType,
            questionContent: questionContent,
            userAnswer: userAnswer,
            correctAnswer: correctAnswer,
            isCorrect: isCorrect,
            responseTimeSeconds: responseTimeSeconds
        )
        record.session = session
        modelContext.insert(record)
        try modelContext.save()
        return record
    }

    // MARK: - アチーブメント操作

    /// アチーブメントを解除
    public func unlockAchievement(
        for profile: UserProfile,
        badge: BadgeDefinition
    ) throws -> Achievement {
        let achievement = Achievement(
            badgeId: badge.rawValue,
            title: badge.title,
            achievementDescription: badge.badgeDescription,
            emoji: badge.emoji
        )
        achievement.profile = profile
        modelContext.insert(achievement)
        try modelContext.save()
        return achievement
    }

    /// 解除済みバッジIDリストを取得
    public func unlockedBadgeIds(for profile: UserProfile) throws -> Set<String> {
        let profileId = profile.id
        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { $0.profile?.id == profileId }
        )
        let achievements = try modelContext.fetch(descriptor)
        return Set(achievements.map(\.badgeId))
    }

    // MARK: - 統計

    /// モード別の正解数を取得
    public func correctAnswerCount(for profile: UserProfile, mode: GameMode) throws -> Int {
        let sessions = try fetchSessions(for: profile, mode: mode)
        return sessions.reduce(0) { $0 + $1.correctAnswers }
    }

    /// 連続プレイ日数を取得
    public func consecutivePlayDays(for profile: UserProfile) throws -> Int {
        let sessions = try fetchSessions(for: profile)
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        // セッションの日付を一意にしてソート
        let playDates: [Date] = Array(
            Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        ).sorted(by: >)

        guard !playDates.isEmpty else { return 0 }

        // 今日からの連続日数をカウント
        let today = calendar.startOfDay(for: Date())
        guard let firstDate = playDates.first,
              calendar.isDate(firstDate, inSameDayAs: today)
                  || calendar.isDate(firstDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!)
        else {
            return 0
        }

        var consecutiveDays = 1
        for i in 1 ..< playDates.count {
            let expectedDate = calendar.date(byAdding: .day, value: -i, to: playDates[0])!
            if calendar.isDate(playDates[i], inSameDayAs: expectedDate) {
                consecutiveDays += 1
            } else {
                break
            }
        }
        return consecutiveDays
    }

    /// プレイ済みモードの一覧を取得
    public func playedModes(for profile: UserProfile) throws -> Set<GameMode> {
        let sessions = try fetchSessions(for: profile)
        return Set(sessions.map(\.gameMode))
    }
}
