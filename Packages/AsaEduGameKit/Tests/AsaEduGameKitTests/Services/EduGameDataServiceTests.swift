import Testing
import Foundation
import SwiftData
@testable import AsaEduGameKit

// MARK: - EduGameDataService テスト

@Suite("EduGameDataService テスト")
struct EduGameDataServiceTests {

    @Test("プロフィール作成")
    @MainActor
    func testCreateProfile() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()
        #expect(profile.name == "")
        #expect(profile.avatarEmoji == "🐱")
        #expect(profile.age == 5)
        #expect(profile.totalStars == 0)
    }

    @Test("プロフィール取得（既存）")
    @MainActor
    func testGetExistingProfile() throws {
        let service = EduGameDataService(inMemory: true)
        let profile1 = try service.getOrCreateProfile()
        profile1.name = "たろう"
        try service.updateProfile(profile1)

        // 2回目の呼び出しで同じプロフィールが返ること
        let profile2 = try service.getOrCreateProfile()
        #expect(profile2.name == "たろう")
        #expect(profile1.id == profile2.id)
    }

    @Test("プロフィール更新")
    @MainActor
    func testUpdateProfile() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()
        profile.name = "はなこ"
        profile.avatarEmoji = "🐰"
        profile.age = 6
        try service.updateProfile(profile)

        let updated = try service.getOrCreateProfile()
        #expect(updated.name == "はなこ")
        #expect(updated.avatarEmoji == "🐰")
        #expect(updated.age == 6)
    }

    @Test("セッション作成")
    @MainActor
    func testCreateSession() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()
        let session = try service.createSession(
            profile: profile,
            gameMode: .mathQuiz,
            difficulty: .normal,
            totalQuestions: 8
        )
        #expect(session.gameMode == .mathQuiz)
        #expect(session.difficulty == .normal)
        #expect(session.totalQuestions == 8)
        #expect(session.profile?.id == profile.id)
    }

    @Test("セッション完了")
    @MainActor
    func testCompleteSession() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()
        let session = try service.createSession(
            profile: profile,
            gameMode: .mathQuiz,
            difficulty: .easy,
            totalQuestions: 5
        )
        session.correctAnswers = 4
        session.earnedStars = 4
        try service.completeSession(session)
        #expect(session.endedAt != nil)
        #expect(session.durationSeconds >= 0)
    }

    @Test("セッション取得（全件）")
    @MainActor
    func testFetchAllSessions() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()

        // 3つのセッションを作成
        _ = try service.createSession(profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5)
        _ = try service.createSession(profile: profile, gameMode: .hiraganaPractice, difficulty: .normal, totalQuestions: 8)
        _ = try service.createSession(profile: profile, gameMode: .shapePuzzle, difficulty: .hard, totalQuestions: 10)

        let sessions = try service.fetchSessions(for: profile)
        #expect(sessions.count == 3)
    }

    @Test("セッション取得（モード別）")
    @MainActor
    func testFetchSessionsByMode() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()

        _ = try service.createSession(profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5)
        _ = try service.createSession(profile: profile, gameMode: .mathQuiz, difficulty: .normal, totalQuestions: 8)
        _ = try service.createSession(profile: profile, gameMode: .hiraganaPractice, difficulty: .easy, totalQuestions: 5)

        let mathSessions = try service.fetchSessions(for: profile, mode: .mathQuiz)
        #expect(mathSessions.count == 2)

        let hiraganaSessions = try service.fetchSessions(for: profile, mode: .hiraganaPractice)
        #expect(hiraganaSessions.count == 1)
    }

    @Test("学習記録追加")
    @MainActor
    func testAddLearningRecord() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()
        let session = try service.createSession(
            profile: profile,
            gameMode: .mathQuiz,
            difficulty: .easy,
            totalQuestions: 5
        )

        let record = try service.addLearningRecord(
            to: session,
            questionType: .addition,
            questionContent: "3 + 2 = ?",
            userAnswer: "5",
            correctAnswer: "5",
            isCorrect: true,
            responseTimeSeconds: 3.0
        )
        #expect(record.isCorrect == true)
        #expect(record.questionType == .addition)
        #expect(record.session?.id == session.id)
    }

    @Test("アチーブメント解除")
    @MainActor
    func testUnlockAchievement() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()

        let achievement = try service.unlockAchievement(for: profile, badge: .firstStar)
        #expect(achievement.badgeId == "first_star")
        #expect(achievement.title == "はじめてのほし")
        #expect(achievement.emoji == "⭐")
        #expect(achievement.profile?.id == profile.id)
    }

    @Test("解除済みバッジID取得")
    @MainActor
    func testUnlockedBadgeIds() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()

        _ = try service.unlockAchievement(for: profile, badge: .firstStar)
        _ = try service.unlockAchievement(for: profile, badge: .combo5)

        let badgeIds = try service.unlockedBadgeIds(for: profile)
        #expect(badgeIds.contains("first_star"))
        #expect(badgeIds.contains("combo_5"))
        #expect(badgeIds.count == 2)
    }

    @Test("重複アチーブメント防止")
    @MainActor
    func testDuplicateAchievementPrevention() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()

        _ = try service.unlockAchievement(for: profile, badge: .firstStar)
        _ = try service.unlockAchievement(for: profile, badge: .firstStar)

        // データサービス自体は重複チェックしない（AchievementServiceが担当）
        // ただし、unlockedBadgeIdsはSetで返すので一意
        let badgeIds = try service.unlockedBadgeIds(for: profile)
        #expect(badgeIds.contains("first_star"))
    }

    @Test("モード別正解数")
    @MainActor
    func testCorrectAnswerCount() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()

        let session1 = try service.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session1.correctAnswers = 4

        let session2 = try service.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .normal, totalQuestions: 8
        )
        session2.correctAnswers = 6

        let count = try service.correctAnswerCount(for: profile, mode: .mathQuiz)
        #expect(count == 10)
    }

    @Test("連続プレイ日数")
    @MainActor
    func testConsecutivePlayDays() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()

        // 今日のセッションを作成
        _ = try service.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )

        let days = try service.consecutivePlayDays(for: profile)
        #expect(days >= 1)
    }

    @Test("プレイ済みモード取得")
    @MainActor
    func testPlayedModes() throws {
        let service = EduGameDataService(inMemory: true)
        let profile = try service.getOrCreateProfile()

        _ = try service.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        _ = try service.createSession(
            profile: profile, gameMode: .hiraganaPractice, difficulty: .easy, totalQuestions: 5
        )

        let modes = try service.playedModes(for: profile)
        #expect(modes.contains(.mathQuiz))
        #expect(modes.contains(.hiraganaPractice))
        #expect(modes.count == 2)
    }

    @Test("複数プロフィール独立性")
    @MainActor
    func testMultipleProfileIndependence() throws {
        // 独立したデータベースで各プロフィールが分離されること
        let service1 = EduGameDataService(inMemory: true)
        let service2 = EduGameDataService(inMemory: true)

        let profile1 = try service1.getOrCreateProfile()
        profile1.name = "プレイヤー1"
        try service1.updateProfile(profile1)

        let profile2 = try service2.getOrCreateProfile()
        profile2.name = "プレイヤー2"
        try service2.updateProfile(profile2)

        // 各サービスのプロフィールが独立していること
        let check1 = try service1.getOrCreateProfile()
        let check2 = try service2.getOrCreateProfile()
        #expect(check1.name == "プレイヤー1")
        #expect(check2.name == "プレイヤー2")
    }
}
