//
//  LearningProgressTests.swift
//  AsaLanguageLearnTests
//
//  学習進捗モデルのテスト
//

import Foundation
import Testing
@testable import AsaLanguageLearn

struct LearningProgressTests {
    // MARK: - Initial State Tests

    @Test("初期状態は未学習")
    func testInitialState() {
        let progress = LearningProgress()

        #expect(progress.correctCount == 0)
        #expect(progress.totalCount == 0)
        #expect(progress.streak == 0)
        #expect(progress.isStudied == false)
        #expect(progress.masteryLevel == .new)
    }

    @Test("初期状態では復習が必要")
    func testInitialNeedsReview() {
        let progress = LearningProgress()
        #expect(progress.needsReview == true)
    }

    // MARK: - Record Correct Tests

    @Test("正解記録で連続正解が増加")
    func testRecordCorrectIncrementsStreak() {
        let progress = LearningProgress()

        progress.recordCorrect(pronunciationScore: 0.9)

        #expect(progress.correctCount == 1)
        #expect(progress.totalCount == 1)
        #expect(progress.streak == 1)
        #expect(progress.isStudied == true)
    }

    @Test("連続正解で次回復習日が延長")
    func testRecordCorrectExtendsReviewDate() {
        let progress = LearningProgress()

        // 1回目: 1日後
        progress.recordCorrect(pronunciationScore: 0.9)
        let firstReview = progress.nextReviewDate

        // 2回目: 3日後
        progress.recordCorrect(pronunciationScore: 0.9)
        let secondReview = progress.nextReviewDate

        #expect(firstReview != nil)
        #expect(secondReview != nil)
        #expect(secondReview! > firstReview!)
    }

    @Test("連続正解で習熟レベルが上昇")
    func testMasteryLevelProgression() {
        let progress = LearningProgress()

        #expect(progress.masteryLevel == .new)

        progress.recordCorrect(pronunciationScore: 0.9)
        #expect(progress.masteryLevel == .learning)

        progress.recordCorrect(pronunciationScore: 0.9)
        #expect(progress.masteryLevel == .learning)

        progress.recordCorrect(pronunciationScore: 0.9)
        #expect(progress.masteryLevel == .review)

        progress.recordCorrect(pronunciationScore: 0.9)
        progress.recordCorrect(pronunciationScore: 0.9)
        progress.recordCorrect(pronunciationScore: 0.9)
        #expect(progress.masteryLevel == .mastered)
    }

    // MARK: - Record Incorrect Tests

    @Test("不正解記録で連続正解がリセット")
    func testRecordIncorrectResetsStreak() {
        let progress = LearningProgress()

        progress.recordCorrect(pronunciationScore: 0.9)
        progress.recordCorrect(pronunciationScore: 0.9)
        #expect(progress.streak == 2)

        progress.recordIncorrect(pronunciationScore: 0.3)
        #expect(progress.streak == 0)
        #expect(progress.totalCount == 3)
    }

    @Test("不正解後は翌日復習")
    func testRecordIncorrectSetsNextDayReview() {
        let progress = LearningProgress()

        progress.recordIncorrect(pronunciationScore: 0.3)

        let expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let actualDate = progress.nextReviewDate!

        // 同じ日かどうかをチェック
        let calendar = Calendar.current
        let expectedDay = calendar.startOfDay(for: expectedDate)
        let actualDay = calendar.startOfDay(for: actualDate)

        #expect(expectedDay == actualDay)
    }

    // MARK: - Correct Rate Tests

    @Test("正解率の計算が正しい")
    func testCorrectRate() {
        let progress = LearningProgress()

        progress.recordCorrect(pronunciationScore: 0.9)
        progress.recordCorrect(pronunciationScore: 0.8)
        progress.recordIncorrect(pronunciationScore: 0.3)
        progress.recordCorrect(pronunciationScore: 0.7)

        // 3/4 = 0.75
        #expect(progress.correctRate == 0.75)
    }

    @Test("回答なしの正解率は0")
    func testCorrectRateWithNoAnswers() {
        let progress = LearningProgress()
        #expect(progress.correctRate == 0.0)
    }

    // MARK: - Average Score Tests

    @Test("平均スコアの計算が正しい")
    func testAverageScore() {
        let progress = LearningProgress()

        progress.recordCorrect(pronunciationScore: 0.8)
        progress.recordCorrect(pronunciationScore: 0.9)
        progress.recordCorrect(pronunciationScore: 1.0)

        // (0.8 + 0.9 + 1.0) / 3 ≈ 0.9
        #expect(progress.averagePronunciationScore > 0.89)
        #expect(progress.averagePronunciationScore < 0.91)
    }

    // MARK: - Best Streak Tests

    @Test("最高連続正解数が記録される")
    func testBestStreak() {
        let progress = LearningProgress()

        // 3連続正解
        progress.recordCorrect(pronunciationScore: 0.9)
        progress.recordCorrect(pronunciationScore: 0.9)
        progress.recordCorrect(pronunciationScore: 0.9)
        #expect(progress.bestStreak == 3)

        // リセット
        progress.recordIncorrect(pronunciationScore: 0.3)
        #expect(progress.bestStreak == 3)
        #expect(progress.streak == 0)

        // 2連続（最高記録を超えない）
        progress.recordCorrect(pronunciationScore: 0.9)
        progress.recordCorrect(pronunciationScore: 0.9)
        #expect(progress.bestStreak == 3)
    }
}
