import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - Achievement テスト

@Suite("Achievement テスト")
struct AchievementTests {

    @Test("デフォルト初期化")
    func testDefaultInit() {
        let achievement = Achievement()
        #expect(achievement.badgeId == "")
        #expect(achievement.title == "")
        #expect(achievement.achievementDescription == "")
        #expect(achievement.emoji == "⭐")
    }

    @Test("カスタム初期化")
    func testCustomInit() {
        let achievement = Achievement(
            badgeId: "first_star",
            title: "はじめてのほし",
            achievementDescription: "はじめてほしをゲット！",
            emoji: "⭐"
        )
        #expect(achievement.badgeId == "first_star")
        #expect(achievement.title == "はじめてのほし")
        #expect(achievement.achievementDescription == "はじめてほしをゲット！")
        #expect(achievement.emoji == "⭐")
    }

    @Test("BadgeDefinition全種類のタイトル")
    func testAllBadgeTitles() {
        // 13種全てにタイトルが設定されていること
        for badge in BadgeDefinition.allCases {
            #expect(!badge.title.isEmpty)
        }
        #expect(BadgeDefinition.allCases.count == 13)

        // 代表的なタイトルの確認
        #expect(BadgeDefinition.firstStar.title == "はじめてのほし")
        #expect(BadgeDefinition.mathMaster.title == "さんすうマスター")
        #expect(BadgeDefinition.perfect.title == "パーフェクト")
    }

    @Test("BadgeDefinition全種類の絵文字")
    func testAllBadgeEmojis() {
        // 13種全てに絵文字が設定されていること
        for badge in BadgeDefinition.allCases {
            #expect(!badge.emoji.isEmpty)
        }

        // 代表的な絵文字の確認
        #expect(BadgeDefinition.firstStar.emoji == "⭐")
        #expect(BadgeDefinition.mathMaster.emoji == "🔢")
        #expect(BadgeDefinition.perfect.emoji == "💯")
    }

    @Test("BadgeDefinition全種類の説明")
    func testAllBadgeDescriptions() {
        // 13種全てに説明文が設定されていること
        for badge in BadgeDefinition.allCases {
            #expect(!badge.badgeDescription.isEmpty)
        }

        // 代表的な説明の確認
        #expect(BadgeDefinition.firstStar.badgeDescription == "はじめてほしをゲット！")
        #expect(BadgeDefinition.combo5.badgeDescription == "5れんぞくせいかい！")
        #expect(BadgeDefinition.allModes.badgeDescription == "4つのモードぜんぶやった！")
    }
}
