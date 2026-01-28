import Testing
import Foundation
@testable import AsaStudyPlanner

@Suite("DifficultyLevel Enumテスト")
struct DifficultyLevelTests {

    // MARK: - 表示プロパティテスト

    @Test("すべての難易度が表示名を持つ")
    func testAllLevelsHaveDisplayName() {
        for level in DifficultyLevel.allCases {
            #expect(!level.displayName.isEmpty)
        }
    }

    @Test("すべての難易度がアイコンを持つ")
    func testAllLevelsHaveIcon() {
        for level in DifficultyLevel.allCases {
            #expect(!level.icon.isEmpty)
        }
    }

    // MARK: - 集中力要求度テスト

    @Test("集中力要求度が0.0から1.0の範囲内")
    func testConcentrationRequirementRange() {
        for level in DifficultyLevel.allCases {
            #expect(level.concentrationRequirement >= 0.0)
            #expect(level.concentrationRequirement <= 1.0)
        }
    }

    @Test("難易度が上がると集中力要求度も上がる")
    func testConcentrationIncreasesWithDifficulty() {
        #expect(DifficultyLevel.easy.concentrationRequirement < DifficultyLevel.medium.concentrationRequirement)
        #expect(DifficultyLevel.medium.concentrationRequirement < DifficultyLevel.hard.concentrationRequirement)
        #expect(DifficultyLevel.hard.concentrationRequirement < DifficultyLevel.expert.concentrationRequirement)
    }

    @Test("上級が最大の集中力要求度を持つ")
    func testExpertHasMaxConcentration() {
        #expect(DifficultyLevel.expert.concentrationRequirement == 1.0)
    }

    // MARK: - 朝活ボーナステスト

    @Test("朝活ボーナスが0.0から0.3の範囲内")
    func testMorningBonusRange() {
        for level in DifficultyLevel.allCases {
            #expect(level.morningBonus >= 0.0)
            #expect(level.morningBonus <= 0.3)
        }
    }

    @Test("難しい内容ほど朝活ボーナスが高い")
    func testMorningBonusIncreasesWithDifficulty() {
        #expect(DifficultyLevel.easy.morningBonus <= DifficultyLevel.medium.morningBonus)
        #expect(DifficultyLevel.medium.morningBonus <= DifficultyLevel.hard.morningBonus)
        #expect(DifficultyLevel.hard.morningBonus <= DifficultyLevel.expert.morningBonus)
    }

    // MARK: - 夜間ペナルティテスト

    @Test("夜間ペナルティが0.0から0.4の範囲内")
    func testEveningPenaltyRange() {
        for level in DifficultyLevel.allCases {
            #expect(level.eveningPenalty >= 0.0)
            #expect(level.eveningPenalty <= 0.4)
        }
    }

    @Test("難しい内容ほど夜間ペナルティが高い")
    func testEveningPenaltyIncreasesWithDifficulty() {
        #expect(DifficultyLevel.easy.eveningPenalty <= DifficultyLevel.medium.eveningPenalty)
        #expect(DifficultyLevel.medium.eveningPenalty <= DifficultyLevel.hard.eveningPenalty)
        #expect(DifficultyLevel.hard.eveningPenalty <= DifficultyLevel.expert.eveningPenalty)
    }

    // MARK: - 休憩間隔テスト

    @Test("推奨休憩間隔が妥当な範囲内")
    func testBreakIntervalRange() {
        for level in DifficultyLevel.allCases {
            #expect(level.recommendedBreakInterval >= 15)
            #expect(level.recommendedBreakInterval <= 60)
        }
    }

    @Test("難しい内容ほど休憩間隔が短い")
    func testBreakIntervalDecreasesWithDifficulty() {
        #expect(DifficultyLevel.easy.recommendedBreakInterval >= DifficultyLevel.medium.recommendedBreakInterval)
        #expect(DifficultyLevel.medium.recommendedBreakInterval >= DifficultyLevel.hard.recommendedBreakInterval)
        #expect(DifficultyLevel.hard.recommendedBreakInterval >= DifficultyLevel.expert.recommendedBreakInterval)
    }

    // MARK: - 数値インデックステスト

    @Test("数値インデックスが正しい順序")
    func testNumericValue() {
        #expect(DifficultyLevel.easy.numericValue == 0)
        #expect(DifficultyLevel.medium.numericValue == 1)
        #expect(DifficultyLevel.hard.numericValue == 2)
        #expect(DifficultyLevel.expert.numericValue == 3)
    }

    // MARK: - Codableテスト

    @Test("難易度がJSONエンコード・デコードできる")
    func testCodable() throws {
        let level = DifficultyLevel.hard

        let encoded = try JSONEncoder().encode(level)
        let decoded = try JSONDecoder().decode(DifficultyLevel.self, from: encoded)

        #expect(decoded == level)
    }

    // MARK: - Raw Valueテスト

    @Test("Raw Valueから正しく復元できる")
    func testRawValueInitialization() {
        #expect(DifficultyLevel(rawValue: "easy") == .easy)
        #expect(DifficultyLevel(rawValue: "medium") == .medium)
        #expect(DifficultyLevel(rawValue: "hard") == .hard)
        #expect(DifficultyLevel(rawValue: "expert") == .expert)
        #expect(DifficultyLevel(rawValue: "invalid") == nil)
    }
}
