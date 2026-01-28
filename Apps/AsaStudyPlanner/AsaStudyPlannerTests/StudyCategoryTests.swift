import Testing
import Foundation
@testable import AsaStudyPlanner

@Suite("StudyCategory Enumテスト")
struct StudyCategoryTests {

    // MARK: - 表示プロパティテスト

    @Test("すべてのカテゴリが表示名を持つ")
    func testAllCategoriesHaveDisplayName() {
        for category in StudyCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    @Test("すべてのカテゴリがアイコンを持つ")
    func testAllCategoriesHaveIcon() {
        for category in StudyCategory.allCases {
            #expect(!category.icon.isEmpty)
        }
    }

    @Test("すべてのカテゴリが絵文字を持つ")
    func testAllCategoriesHaveEmoji() {
        for category in StudyCategory.allCases {
            #expect(!category.emoji.isEmpty)
        }
    }

    // MARK: - 重要度スコアテスト

    @Test("基本重要度スコアが0.0から1.0の範囲内")
    func testBaseImportanceScoreRange() {
        for category in StudyCategory.allCases {
            #expect(category.baseImportanceScore >= 0.0)
            #expect(category.baseImportanceScore <= 1.0)
        }
    }

    @Test("資格カテゴリが最も高い重要度を持つ")
    func testCertificationHasHighestImportance() {
        let maxCategory = StudyCategory.allCases.max { $0.baseImportanceScore < $1.baseImportanceScore }
        #expect(maxCategory == .certification)
    }

    @Test("その他カテゴリが最も低い重要度を持つ")
    func testOtherHasLowestImportance() {
        let minCategory = StudyCategory.allCases.min { $0.baseImportanceScore < $1.baseImportanceScore }
        #expect(minCategory == .other)
    }

    // MARK: - 朝活適性テスト

    @Test("集中力を要するカテゴリは朝活最適")
    func testMorningOptimalCategories() {
        #expect(StudyCategory.certification.isMorningOptimal == true)
        #expect(StudyCategory.mathematics.isMorningOptimal == true)
        #expect(StudyCategory.programming.isMorningOptimal == true)
        #expect(StudyCategory.science.isMorningOptimal == true)
    }

    @Test("軽い学習カテゴリは朝活最適でない")
    func testNonMorningOptimalCategories() {
        #expect(StudyCategory.language.isMorningOptimal == false)
        #expect(StudyCategory.business.isMorningOptimal == false)
        #expect(StudyCategory.creative.isMorningOptimal == false)
        #expect(StudyCategory.other.isMorningOptimal == false)
    }

    // MARK: - 推奨セッション時間テスト

    @Test("推奨セッション時間が妥当な範囲内")
    func testRecommendedSessionMinutesRange() {
        for category in StudyCategory.allCases {
            #expect(category.recommendedSessionMinutes >= 20)
            #expect(category.recommendedSessionMinutes <= 60)
        }
    }

    @Test("クリエイティブカテゴリが最長セッション時間")
    func testCreativeHasLongestSession() {
        let maxCategory = StudyCategory.allCases.max { $0.recommendedSessionMinutes < $1.recommendedSessionMinutes }
        #expect(maxCategory == .creative)
    }

    // MARK: - Codableテスト

    @Test("カテゴリがJSONエンコード・デコードできる")
    func testCodable() throws {
        let category = StudyCategory.programming

        let encoded = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(StudyCategory.self, from: encoded)

        #expect(decoded == category)
    }

    // MARK: - Raw Valueテスト

    @Test("Raw Valueから正しく復元できる")
    func testRawValueInitialization() {
        #expect(StudyCategory(rawValue: "programming") == .programming)
        #expect(StudyCategory(rawValue: "language") == .language)
        #expect(StudyCategory(rawValue: "invalid") == nil)
    }
}
