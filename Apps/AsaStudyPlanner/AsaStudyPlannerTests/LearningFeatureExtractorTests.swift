import Testing
import Foundation
@testable import AsaStudyPlanner

@Suite("LearningFeatureExtractor テスト")
struct LearningFeatureExtractorTests {

    let extractor = LearningFeatureExtractor()

    // MARK: - Target Date Score Tests

    @Test("期限なしは0.3スコア")
    func testNoTargetDate() {
        let score = extractor.calculateTargetDateScore(nil)
        #expect(score == 0.3)
    }

    @Test("期限切れは1.0スコア")
    func testOverdueTargetDate() {
        let score = extractor.calculateTargetDateScore(-1)
        #expect(score == 1.0)
    }

    @Test("今日が期限は0.95スコア")
    func testTodayTargetDate() {
        let score = extractor.calculateTargetDateScore(0)
        #expect(score == 0.95)
    }

    @Test("明日が期限は0.9スコア")
    func testTomorrowTargetDate() {
        let score = extractor.calculateTargetDateScore(1)
        #expect(score == 0.9)
    }

    @Test("2-3日後は0.7スコア")
    func testTwoThreeDaysTargetDate() {
        #expect(extractor.calculateTargetDateScore(2) == 0.7)
        #expect(extractor.calculateTargetDateScore(3) == 0.7)
    }

    @Test("1週間以内は0.5スコア")
    func testOneWeekTargetDate() {
        #expect(extractor.calculateTargetDateScore(4) == 0.5)
        #expect(extractor.calculateTargetDateScore(7) == 0.5)
    }

    @Test("2週間以内は0.4スコア")
    func testTwoWeeksTargetDate() {
        #expect(extractor.calculateTargetDateScore(8) == 0.4)
        #expect(extractor.calculateTargetDateScore(14) == 0.4)
    }

    @Test("1ヶ月以上先は0.3スコア")
    func testFarTargetDate() {
        #expect(extractor.calculateTargetDateScore(31) == 0.3)
        #expect(extractor.calculateTargetDateScore(100) == 0.3)
    }

    // MARK: - Time of Day Score Tests

    @Test("深朝活時間（5-7時）は0.9スコア")
    func testEarlyMorningTime() {
        #expect(extractor.calculateTimeOfDayScore(hour: 5) == 0.9)
        #expect(extractor.calculateTimeOfDayScore(hour: 6) == 0.9)
    }

    @Test("朝時間（7-9時）は0.7スコア")
    func testMorningTime() {
        #expect(extractor.calculateTimeOfDayScore(hour: 7) == 0.7)
        #expect(extractor.calculateTimeOfDayScore(hour: 8) == 0.7)
    }

    @Test("午前中（9-12時）は0.6スコア")
    func testLateMorningTime() {
        #expect(extractor.calculateTimeOfDayScore(hour: 9) == 0.6)
        #expect(extractor.calculateTimeOfDayScore(hour: 11) == 0.6)
    }

    @Test("昼時間（12-14時）は0.4スコア")
    func testNoonTime() {
        #expect(extractor.calculateTimeOfDayScore(hour: 12) == 0.4)
        #expect(extractor.calculateTimeOfDayScore(hour: 13) == 0.4)
    }

    @Test("午後（14-17時）は0.5スコア")
    func testAfternoonTime() {
        #expect(extractor.calculateTimeOfDayScore(hour: 14) == 0.5)
        #expect(extractor.calculateTimeOfDayScore(hour: 16) == 0.5)
    }

    @Test("夕方（17-21時）は0.55スコア")
    func testEveningTime() {
        #expect(extractor.calculateTimeOfDayScore(hour: 17) == 0.55)
        #expect(extractor.calculateTimeOfDayScore(hour: 20) == 0.55)
    }

    @Test("夜間（21-24時、0-5時）は0.3スコア")
    func testNightTime() {
        #expect(extractor.calculateTimeOfDayScore(hour: 21) == 0.3)
        #expect(extractor.calculateTimeOfDayScore(hour: 23) == 0.3)
        #expect(extractor.calculateTimeOfDayScore(hour: 0) == 0.3)
        #expect(extractor.calculateTimeOfDayScore(hour: 4) == 0.3)
    }

    // MARK: - Mastery Score Tests

    @Test("習熟度0.0は1.0スコア（未学習は高優先）")
    func testZeroMastery() {
        #expect(extractor.calculateMasteryScore(0.0) == 1.0)
    }

    @Test("習熟度0.5は0.5スコア")
    func testHalfMastery() {
        #expect(extractor.calculateMasteryScore(0.5) == 0.5)
    }

    @Test("習熟度1.0は0.0スコア（マスターは低優先）")
    func testFullMastery() {
        #expect(extractor.calculateMasteryScore(1.0) == 0.0)
    }

    // MARK: - Difficulty × Time Score Tests

    @Test("朝時間帯の難しい内容はボーナス")
    func testMorningHardDifficulty() {
        let score = extractor.calculateDifficultyTimeScore(difficulty: .expert, hour: 6)
        #expect(score > 0.9)  // 朝活ボーナス
    }

    @Test("夜時間帯の難しい内容はペナルティ")
    func testNightHardDifficulty() {
        let score = extractor.calculateDifficultyTimeScore(difficulty: .expert, hour: 23)
        #expect(score < 0.3)  // 夜間ペナルティ
    }

    @Test("朝時間帯の簡単な内容は通常スコア")
    func testMorningEasyDifficulty() {
        let score = extractor.calculateDifficultyTimeScore(difficulty: .easy, hour: 6)
        #expect(score >= 0.9 && score <= 1.0)
    }

    // MARK: - Prerequisite Score Tests

    @Test("前提知識なしは1.0スコア")
    func testNoPrerequisites() {
        let item = StudyItem(title: "テスト", prerequisiteItemIds: [])
        let score = extractor.calculatePrerequisiteScore(item)
        #expect(score == 1.0)
    }

    @Test("前提知識ありはスコア低下")
    func testWithPrerequisites() {
        let item = StudyItem(title: "テスト", prerequisiteItemIds: [UUID(), UUID()])
        let score = extractor.calculatePrerequisiteScore(item)
        #expect(score < 1.0)
        #expect(score >= 0.3)
    }

    // MARK: - Title Complexity Tests

    @Test("空のタイトルは0.0複雑度")
    func testEmptyTitleComplexity() {
        #expect(extractor.calculateTitleComplexity("") == 0.0)
    }

    @Test("短いタイトルは低い複雑度")
    func testShortTitleComplexity() {
        let complexity = extractor.calculateTitleComplexity("Swift")
        #expect(complexity > 0.0)
        #expect(complexity < 0.3)
    }

    @Test("長いタイトルは高い複雑度")
    func testLongTitleComplexity() {
        let complexity = extractor.calculateTitleComplexity(
            "Swift並行処理とasync awaitパターンの完全理解ガイド"
        )
        #expect(complexity > 0.5)
    }

    // MARK: - Feature Extraction Integration Tests

    @Test("特徴量抽出が全フィールドを返す")
    func testExtractFeatures() {
        let item = StudyItem(
            title: "テスト項目",
            category: .programming,
            difficulty: .hard,
            estimatedMinutes: 60
        )

        let features = extractor.extractFeatures(from: item)

        #expect(features.targetDateScore >= 0.0 && features.targetDateScore <= 1.0)
        #expect(features.difficultyTimeScore >= 0.0 && features.difficultyTimeScore <= 1.0)
        #expect(features.masteryScore >= 0.0 && features.masteryScore <= 1.0)
        #expect(features.reviewScore >= 0.0 && features.reviewScore <= 1.0)
        #expect(features.timeOfDayScore >= 0.0 && features.timeOfDayScore <= 1.0)
        #expect(features.prerequisiteScore >= 0.0 && features.prerequisiteScore <= 1.0)
        #expect(features.categoryImportance >= 0.0 && features.categoryImportance <= 1.0)
        #expect(features.estimatedMinutes == 60)
    }

    @Test("asArray配列が正しい長さ")
    func testFeaturesAsArray() {
        let item = StudyItem(title: "テスト")
        let features = extractor.extractFeatures(from: item)
        #expect(features.asArray.count == 6)
    }
}
