//
//  SRSCalculatorTests.swift
//  AsaLanguageLearnTests
//
//  SRS計算ユーティリティのテスト
//

import Foundation
import Testing
@testable import AsaLanguageLearn

struct SRSCalculatorTests {
    // MARK: - Interval Calculation Tests

    @Test("連続正解0回は間隔0日")
    func testIntervalStreak0() {
        let interval = SRSCalculator.calculateInterval(streak: 0)
        #expect(interval == 0)
    }

    @Test("連続正解1回は間隔1日")
    func testIntervalStreak1() {
        let interval = SRSCalculator.calculateInterval(streak: 1)
        #expect(interval == 1)
    }

    @Test("連続正解2回は間隔3日")
    func testIntervalStreak2() {
        let interval = SRSCalculator.calculateInterval(streak: 2)
        #expect(interval == 3)
    }

    @Test("連続正解3回は間隔7日")
    func testIntervalStreak3() {
        let interval = SRSCalculator.calculateInterval(streak: 3)
        #expect(interval == 7)
    }

    @Test("連続正解4回は間隔14日")
    func testIntervalStreak4() {
        let interval = SRSCalculator.calculateInterval(streak: 4)
        #expect(interval == 14)
    }

    @Test("連続正解5回は間隔30日")
    func testIntervalStreak5() {
        let interval = SRSCalculator.calculateInterval(streak: 5)
        #expect(interval == 30)
    }

    @Test("連続正解6回は間隔90日（上限）")
    func testIntervalStreak6() {
        let interval = SRSCalculator.calculateInterval(streak: 6)
        #expect(interval == 90)
    }

    @Test("連続正解10回も間隔90日（上限維持）")
    func testIntervalStreak10() {
        let interval = SRSCalculator.calculateInterval(streak: 10)
        #expect(interval == 90)
    }

    // MARK: - Mastery Level Tests

    @Test("連続正解0回は新規レベル")
    func testMasteryLevelNew() {
        let level = SRSCalculator.calculateMasteryLevel(streak: 0)
        #expect(level == .new)
    }

    @Test("連続正解1回は学習中レベル")
    func testMasteryLevelLearning1() {
        let level = SRSCalculator.calculateMasteryLevel(streak: 1)
        #expect(level == .learning)
    }

    @Test("連続正解2回も学習中レベル")
    func testMasteryLevelLearning2() {
        let level = SRSCalculator.calculateMasteryLevel(streak: 2)
        #expect(level == .learning)
    }

    @Test("連続正解3回は復習レベル")
    func testMasteryLevelReview3() {
        let level = SRSCalculator.calculateMasteryLevel(streak: 3)
        #expect(level == .review)
    }

    @Test("連続正解5回も復習レベル")
    func testMasteryLevelReview5() {
        let level = SRSCalculator.calculateMasteryLevel(streak: 5)
        #expect(level == .review)
    }

    @Test("連続正解6回は習得済みレベル")
    func testMasteryLevelMastered() {
        let level = SRSCalculator.calculateMasteryLevel(streak: 6)
        #expect(level == .mastered)
    }

    // MARK: - Review Priority Tests

    @Test("復習日未設定は最優先")
    func testPriorityNoReviewDate() {
        let priority = SRSCalculator.calculateReviewPriority(
            nextReviewDate: nil,
            correctRate: 0.8
        )
        #expect(priority == 1.0)
    }

    @Test("復習日が未来なら優先度低い")
    func testPriorityFutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let priority = SRSCalculator.calculateReviewPriority(
            nextReviewDate: futureDate,
            correctRate: 0.8
        )
        #expect(priority < 0.5)
    }

    @Test("復習日が過去なら優先度高い")
    func testPriorityPastDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let priority = SRSCalculator.calculateReviewPriority(
            nextReviewDate: pastDate,
            correctRate: 0.8
        )
        #expect(priority > 0.3)
    }

    @Test("正解率が低いと優先度上昇")
    func testPriorityLowCorrectRate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let lowRatePriority = SRSCalculator.calculateReviewPriority(
            nextReviewDate: pastDate,
            correctRate: 0.3
        )
        let highRatePriority = SRSCalculator.calculateReviewPriority(
            nextReviewDate: pastDate,
            correctRate: 0.9
        )
        #expect(lowRatePriority > highRatePriority)
    }
}
