import Testing
import Foundation
@testable import AsaStudyPlanner

@Suite("SpacedRepetitionEngine テスト")
struct SpacedRepetitionEngineTests {

    let engine = SpacedRepetitionEngine()

    // MARK: - Review Quality Tests

    @Test("ReviewQuality.isSuccessfulが正しく判定される")
    func testReviewQualitySuccess() {
        #expect(SpacedRepetitionEngine.ReviewQuality.completeBlackout.isSuccessful == false)
        #expect(SpacedRepetitionEngine.ReviewQuality.incorrectButRemembered.isSuccessful == false)
        #expect(SpacedRepetitionEngine.ReviewQuality.incorrectEasyRecall.isSuccessful == false)
        #expect(SpacedRepetitionEngine.ReviewQuality.correctDifficult.isSuccessful == true)
        #expect(SpacedRepetitionEngine.ReviewQuality.correctHesitation.isSuccessful == true)
        #expect(SpacedRepetitionEngine.ReviewQuality.perfectRecall.isSuccessful == true)
    }

    @Test("セッション評価からReviewQualityを推定")
    func testReviewQualityFromSession() {
        // 最高評価
        let perfect = SpacedRepetitionEngine.ReviewQuality.from(focusLevel: 5, comprehensionLevel: 5)
        #expect(perfect == .perfectRecall)

        // 良好
        let good = SpacedRepetitionEngine.ReviewQuality.from(focusLevel: 4, comprehensionLevel: 4)
        #expect(good == .correctHesitation)

        // 普通
        let average = SpacedRepetitionEngine.ReviewQuality.from(focusLevel: 3, comprehensionLevel: 3)
        #expect(average == .correctDifficult)

        // 低評価
        let poor = SpacedRepetitionEngine.ReviewQuality.from(focusLevel: 1, comprehensionLevel: 1)
        #expect(poor == .incorrectButRemembered)
    }

    // MARK: - SM-2 Calculation Tests

    @Test("初回成功は1日後に復習")
    func testFirstSuccessfulReview() {
        let result = engine.calculateNextReview(
            quality: .perfectRecall,
            repetitionCount: 0,
            easeFactor: 2.5,
            lastInterval: 0
        )

        #expect(result.nextInterval == 1)
        #expect(result.newRepetitionCount == 1)
        #expect(result.wasSuccessful == true)
    }

    @Test("2回目成功は6日後に復習")
    func testSecondSuccessfulReview() {
        let result = engine.calculateNextReview(
            quality: .perfectRecall,
            repetitionCount: 1,
            easeFactor: 2.5,
            lastInterval: 1
        )

        #expect(result.nextInterval == 6)
        #expect(result.newRepetitionCount == 2)
        #expect(result.wasSuccessful == true)
    }

    @Test("3回目以降は前回間隔×EaseFactorで計算")
    func testSubsequentSuccessfulReview() {
        let result = engine.calculateNextReview(
            quality: .perfectRecall,
            repetitionCount: 2,
            easeFactor: 2.5,
            lastInterval: 6
        )

        // 6 × 2.5 = 15
        #expect(result.nextInterval == 15)
        #expect(result.newRepetitionCount == 3)
    }

    @Test("失敗時は連続回数リセットで翌日復習")
    func testFailedReview() {
        let result = engine.calculateNextReview(
            quality: .incorrectEasyRecall,
            repetitionCount: 5,
            easeFactor: 2.5,
            lastInterval: 30
        )

        #expect(result.nextInterval == 1)
        #expect(result.newRepetitionCount == 0)
        #expect(result.wasSuccessful == false)
    }

    @Test("完璧な復習でEaseFactorが上昇")
    func testEaseFactorIncrease() {
        let result = engine.calculateNextReview(
            quality: .perfectRecall,
            repetitionCount: 1,
            easeFactor: 2.5,
            lastInterval: 1
        )

        #expect(result.newEaseFactor > 2.5)
    }

    @Test("難しかった復習でEaseFactorが低下")
    func testEaseFactorDecrease() {
        let result = engine.calculateNextReview(
            quality: .correctDifficult,
            repetitionCount: 1,
            easeFactor: 2.5,
            lastInterval: 1
        )

        #expect(result.newEaseFactor < 2.5)
    }

    @Test("EaseFactorは最小値1.3を下回らない")
    func testEaseFactorMinimum() {
        // 複数回低評価でもEaseFactorは下限を守る
        var easeFactor = 2.5
        for _ in 0..<10 {
            let result = engine.calculateNextReview(
                quality: .correctDifficult,
                repetitionCount: 1,
                easeFactor: easeFactor,
                lastInterval: 1
            )
            easeFactor = result.newEaseFactor
        }

        #expect(easeFactor >= SpacedRepetitionEngine.minimumEaseFactor)
    }

    @Test("EaseFactorは最大値3.0を超えない")
    func testEaseFactorMaximum() {
        var easeFactor = 2.5
        for _ in 0..<10 {
            let result = engine.calculateNextReview(
                quality: .perfectRecall,
                repetitionCount: 1,
                easeFactor: easeFactor,
                lastInterval: 1
            )
            easeFactor = result.newEaseFactor
        }

        #expect(easeFactor <= SpacedRepetitionEngine.maximumEaseFactor)
    }

    // MARK: - Item Filtering Tests

    @Test("復習が必要な項目をフィルタ")
    func testFilterItemsNeedingReview() {
        let item1 = StudyItem(title: "復習必要")
        item1.nextReviewDate = Date().addingTimeInterval(-86400)  // 昨日
        item1.sessionCount = 1

        let item2 = StudyItem(title: "まだ先")
        item2.nextReviewDate = Date().addingTimeInterval(86400)  // 明日

        let item3 = StudyItem(title: "未学習")
        // nextReviewDate = nil, sessionCount = 0

        let needsReview = engine.filterItemsNeedingReview([item1, item2, item3])

        #expect(needsReview.count == 1)
        #expect(needsReview.first?.title == "復習必要")
    }

    @Test("復習緊急度でソート")
    func testSortByReviewUrgency() {
        let item1 = StudyItem(title: "最優先")
        item1.nextReviewDate = Date().addingTimeInterval(-172800)  // 2日前

        let item2 = StudyItem(title: "次優先")
        item2.nextReviewDate = Date().addingTimeInterval(-86400)  // 昨日

        let item3 = StudyItem(title: "低優先")
        item3.nextReviewDate = Date().addingTimeInterval(86400)  // 明日

        let sorted = engine.sortByReviewUrgency([item2, item3, item1])

        #expect(sorted[0].title == "最優先")
        #expect(sorted[1].title == "次優先")
        #expect(sorted[2].title == "低優先")
    }

    // MARK: - Statistics Tests

    @Test("復習統計が正しく計算される")
    func testReviewStatistics() {
        let item1 = StudyItem(title: "項目1")
        item1.nextReviewDate = Date().addingTimeInterval(-86400)
        item1.easeFactor = 2.5

        let item2 = StudyItem(title: "項目2")
        item2.nextReviewDate = Date().addingTimeInterval(86400)
        item2.easeFactor = 2.0

        let stats = engine.calculateReviewStats(for: [item1, item2])

        #expect(stats.itemsNeedingReviewToday == 1)
        #expect(stats.totalItemsWithSchedule == 2)
        #expect(stats.averageEaseFactor == 2.25)
    }

    @Test("復習健全性スコアが正しく計算される")
    func testHealthScore() {
        // 全項目が期限内
        let item1 = StudyItem(title: "項目1")
        item1.nextReviewDate = Date().addingTimeInterval(86400)

        let stats1 = engine.calculateReviewStats(for: [item1])
        #expect(stats1.healthScore == 1.0)

        // 全項目が期限切れ
        let item2 = StudyItem(title: "項目2")
        item2.nextReviewDate = Date().addingTimeInterval(-86400)

        let stats2 = engine.calculateReviewStats(for: [item2])
        #expect(stats2.healthScore == 0.0)
    }
}
