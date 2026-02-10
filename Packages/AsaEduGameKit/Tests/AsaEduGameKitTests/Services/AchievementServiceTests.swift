import Testing
import Foundation
import SwiftData
@testable import AsaEduGameKit

// MARK: - AchievementService テスト

@Suite("AchievementService テスト")
struct AchievementServiceTests {

    @Test("初めての星バッジ")
    @MainActor
    func testFirstStarBadge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 3
        session.earnedStars = 3

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.firstStar))
    }

    @Test("パーフェクトバッジ")
    @MainActor
    func testPerfectBadge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 5
        session.earnedStars = 5

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.perfect))
    }

    @Test("コンボ5バッジ")
    @MainActor
    func testCombo5Badge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 5
        session.earnedStars = 5
        session.maxCombo = 5

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.combo5))
    }

    @Test("スーパーコンボバッジ")
    @MainActor
    func testSuperComboBadge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .hard, totalQuestions: 10
        )
        session.correctAnswers = 10
        session.earnedStars = 10
        session.maxCombo = 10

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.superCombo))
    }

    @Test("算数マスターバッジ")
    @MainActor
    func testMathMasterBadge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        // 算数で50問正解を累計で達成させる
        for _ in 0 ..< 10 {
            let s = try dataService.createSession(
                profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
            )
            s.correctAnswers = 5
        }

        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 1
        session.earnedStars = 1

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.mathMaster))
    }

    @Test("ひらがなヒーローバッジ")
    @MainActor
    func testHiraganaHeroBadge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        // ひらがなで50問正解
        for _ in 0 ..< 10 {
            let s = try dataService.createSession(
                profile: profile, gameMode: .hiraganaPractice, difficulty: .easy, totalQuestions: 5
            )
            s.correctAnswers = 5
        }

        let session = try dataService.createSession(
            profile: profile, gameMode: .hiraganaPractice, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 1
        session.earnedStars = 1

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.hiraganaHero))
    }

    @Test("図形はかせバッジ")
    @MainActor
    func testShapeExpertBadge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        // 図形で50問正解
        for _ in 0 ..< 10 {
            let s = try dataService.createSession(
                profile: profile, gameMode: .shapePuzzle, difficulty: .easy, totalQuestions: 5
            )
            s.correctAnswers = 5
        }

        let session = try dataService.createSession(
            profile: profile, gameMode: .shapePuzzle, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 1
        session.earnedStars = 1

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.shapeExpert))
    }

    @Test("論理てんさいバッジ")
    @MainActor
    func testLogicGeniusBadge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        // 論理で50問正解
        for _ in 0 ..< 10 {
            let s = try dataService.createSession(
                profile: profile, gameMode: .logicGame, difficulty: .easy, totalQuestions: 5
            )
            s.correctAnswers = 5
        }

        let session = try dataService.createSession(
            profile: profile, gameMode: .logicGame, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 1
        session.earnedStars = 1

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.logicGenius))
    }

    @Test("星100コレクターバッジ")
    @MainActor
    func testStarCollector100Badge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()
        profile.totalStars = 95

        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 5
        session.earnedStars = 5

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.starCollector100))
    }

    @Test("星500コレクターバッジ")
    @MainActor
    func testStarCollector500Badge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()
        profile.totalStars = 498

        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 5
        session.earnedStars = 5

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.starCollector500))
    }

    @Test("レベル3バッジ")
    @MainActor
    func testLevelThreeBadge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()
        // レベル3は150星以上
        profile.totalStars = 145

        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 5
        session.earnedStars = 10

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.levelThree))
    }

    @Test("全モード制覇バッジ")
    @MainActor
    func testAllModesBadge() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        // 3モードをプレイ済みにする
        _ = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        _ = try dataService.createSession(
            profile: profile, gameMode: .hiraganaPractice, difficulty: .easy, totalQuestions: 5
        )
        _ = try dataService.createSession(
            profile: profile, gameMode: .shapePuzzle, difficulty: .easy, totalQuestions: 5
        )

        // 4つ目のモード（logicGame）でセッション
        let session = try dataService.createSession(
            profile: profile, gameMode: .logicGame, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 1
        session.earnedStars = 1

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        #expect(badges.contains(.allModes))
    }

    @Test("重複解除なし")
    @MainActor
    func testNoDuplicateUnlock() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        let session1 = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session1.correctAnswers = 5
        session1.earnedStars = 5

        // 1回目: firstStar 解除
        let badges1 = try achievementService.checkAndUnlockAchievements(profile: profile, session: session1)
        #expect(badges1.contains(.firstStar))

        // 2回目: 同条件でも既に解除済みなので含まれない
        let session2 = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session2.correctAnswers = 5
        session2.earnedStars = 5

        let badges2 = try achievementService.checkAndUnlockAchievements(profile: profile, session: session2)
        #expect(!badges2.contains(.firstStar))
    }

    @Test("複数バッジ同時解除")
    @MainActor
    func testMultipleBadgesAtOnce() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        // 全問正解 + コンボ5 + 星獲得 → 複数バッジ同時解除
        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 5
        session.earnedStars = 5
        session.maxCombo = 5

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        // firstStar, perfect, combo5 が同時に解除されるはず
        #expect(badges.contains(.firstStar))
        #expect(badges.contains(.perfect))
        #expect(badges.contains(.combo5))
        #expect(badges.count >= 3)
    }

    @Test("条件未達でバッジなし")
    @MainActor
    func testNoUnlockWhenConditionNotMet() throws {
        let dataService = EduGameDataService(inMemory: true)
        let achievementService = AchievementService(dataService: dataService)
        let profile = try dataService.getOrCreateProfile()

        let session = try dataService.createSession(
            profile: profile, gameMode: .mathQuiz, difficulty: .easy, totalQuestions: 5
        )
        session.correctAnswers = 0
        session.earnedStars = 0
        session.maxCombo = 0

        let badges = try achievementService.checkAndUnlockAchievements(profile: profile, session: session)
        // 星0、コンボ0、不正解なので解除されるバッジなし
        #expect(!badges.contains(.firstStar))
        #expect(!badges.contains(.perfect))
        #expect(!badges.contains(.combo5))
    }
}
