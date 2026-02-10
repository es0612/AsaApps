import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - UserProfile テスト

@Suite("UserProfile テスト")
struct UserProfileTests {

    @Test("デフォルト初期化")
    func testDefaultInit() {
        let profile = UserProfile()
        #expect(profile.name == "")
        #expect(profile.avatarEmoji == "🐱")
        #expect(profile.age == 5)
        #expect(profile.totalStars == 0)
        #expect(profile.currentLevel == 1)
    }

    @Test("カスタム初期化")
    func testCustomInit() {
        let profile = UserProfile(name: "たろう", avatarEmoji: "🐶", age: 7)
        #expect(profile.name == "たろう")
        #expect(profile.avatarEmoji == "🐶")
        #expect(profile.age == 7)
    }

    @Test("レベル計算 - レベル1")
    func testCalculateLevelOne() {
        // 0-49星 → Lv1
        #expect(UserProfile.calculateLevel(from: 0) == 1)
        #expect(UserProfile.calculateLevel(from: 25) == 1)
        #expect(UserProfile.calculateLevel(from: 49) == 1)
    }

    @Test("レベル計算 - レベル4")
    func testCalculateLevelFour() {
        // 300-499星 → Lv4
        #expect(UserProfile.calculateLevel(from: 300) == 4)
        #expect(UserProfile.calculateLevel(from: 400) == 4)
        #expect(UserProfile.calculateLevel(from: 499) == 4)
    }

    @Test("レベル計算 - レベル7")
    func testCalculateLevelSeven() {
        // 1000星以上 → Lv7
        #expect(UserProfile.calculateLevel(from: 1000) == 7)
        #expect(UserProfile.calculateLevel(from: 5000) == 7)
    }

    @Test("レベル更新")
    func testUpdateLevel() {
        let profile = UserProfile()
        profile.totalStars = 150
        profile.updateLevel()
        #expect(profile.currentLevel == 3)
    }

    @Test("次レベルまでの星数")
    func testStarsToNextLevel() {
        let profile = UserProfile()
        // Lv1 の閾値は50、totalStars=30 → 50-30=20
        profile.currentLevel = 1
        profile.totalStars = 30
        #expect(profile.starsToNextLevel == 20)
    }

    @Test("レベル表示名")
    func testLevelDisplayName() {
        let profile = UserProfile()
        profile.currentLevel = 3
        #expect(profile.levelDisplayName == "がんばりや")
    }
}
