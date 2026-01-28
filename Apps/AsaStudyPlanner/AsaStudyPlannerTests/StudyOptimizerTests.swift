import Testing
import Foundation
@testable import AsaStudyPlanner

@Suite("StudyOptimizer テスト")
struct StudyOptimizerTests {

    // MARK: - Basic Optimization Tests

    @Test("空の項目リストは空の結果を返す")
    func testEmptyItems() {
        let optimizer = StudyOptimizer()
        let result = optimizer.optimizeStudyOrder(items: [])

        #expect(result.orderedItemIds.isEmpty)
        #expect(result.priorityScores.isEmpty)
        #expect(result.overallScore == 0.0)
    }

    @Test("単一項目の最適化が動作する")
    func testSingleItem() {
        let optimizer = StudyOptimizer()
        let item = StudyItem(title: "テスト", category: .programming)

        let result = optimizer.optimizeStudyOrder(items: [item])

        #expect(result.orderedItemIds.count == 1)
        #expect(result.orderedItemIds.first == item.id)
        #expect(result.priorityScores[item.id] != nil)
    }

    @Test("期限が近い項目が優先される")
    func testDeadlinePriority() {
        let optimizer = StudyOptimizer(weights: .deadlineFocused)

        let urgentItem = StudyItem(title: "緊急", category: .programming)
        urgentItem.targetDate = Date().addingTimeInterval(86400)  // 明日

        let laterItem = StudyItem(title: "余裕あり", category: .programming)
        laterItem.targetDate = Date().addingTimeInterval(86400 * 30)  // 30日後

        let result = optimizer.optimizeStudyOrder(items: [laterItem, urgentItem])

        #expect(result.orderedItemIds.first == urgentItem.id)
    }

    @Test("期限切れ項目が最優先される")
    func testOverdueItemPriority() {
        let optimizer = StudyOptimizer()

        let overdueItem = StudyItem(title: "期限切れ", category: .programming)
        overdueItem.targetDate = Date().addingTimeInterval(-86400)  // 昨日

        let normalItem = StudyItem(title: "通常", category: .programming)

        let result = optimizer.optimizeStudyOrder(items: [normalItem, overdueItem])

        #expect(result.orderedItemIds.first == overdueItem.id)
    }

    // MARK: - Priority Calculation Tests

    @Test("優先度スコアが0.0から1.0の範囲内")
    func testPriorityScoreRange() {
        let optimizer = StudyOptimizer()
        let item = StudyItem(
            title: "テスト",
            category: .certification,
            difficulty: .expert
        )

        let result = optimizer.calculatePriority(for: item)

        #expect(result.totalScore >= 0.0)
        #expect(result.totalScore <= 1.0)
    }

    @Test("コンポーネントスコアが計算される")
    func testComponentScores() {
        let optimizer = StudyOptimizer()
        let item = StudyItem(title: "テスト", category: .programming)

        let result = optimizer.calculatePriority(for: item)

        let components = result.componentScores
        #expect(components.asArray.count == 6)
        #expect(components.asArray.allSatisfy { $0 >= 0.0 })
    }

    @Test("理由が生成される")
    func testReasonGeneration() {
        let optimizer = StudyOptimizer()
        let item = StudyItem(title: "テスト", category: .programming)
        item.targetDate = Date()  // 今日が期限

        let result = optimizer.calculatePriority(for: item)

        #expect(!result.reasons.isEmpty)
    }

    // MARK: - Weight Configuration Tests

    @Test("デフォルト重みが有効")
    func testDefaultWeights() {
        let weights = OptimizationWeights.default
        #expect(weights.isValid)
    }

    @Test("期限重視モードの重みが有効")
    func testDeadlineFocusedWeights() {
        let weights = OptimizationWeights.deadlineFocused
        #expect(weights.isValid)
        #expect(weights.targetDateWeight > OptimizationWeights.default.targetDateWeight)
    }

    @Test("朝活重視モードの重みが有効")
    func testMorningFocusedWeights() {
        let weights = OptimizationWeights.morningFocused
        #expect(weights.isValid)
        #expect(weights.timeOfDayWeight > OptimizationWeights.default.timeOfDayWeight)
    }

    @Test("復習重視モードの重みが有効")
    func testReviewFocusedWeights() {
        let weights = OptimizationWeights.reviewFocused
        #expect(weights.isValid)
        #expect(weights.reviewWeight > OptimizationWeights.default.reviewWeight)
    }

    @Test("重みの更新が動作する")
    func testWeightUpdate() {
        let optimizer = StudyOptimizer(weights: .default)
        optimizer.updateWeights(.deadlineFocused)

        let currentWeights = optimizer.currentWeights()
        #expect(currentWeights.targetDateWeight == OptimizationWeights.deadlineFocused.targetDateWeight)
    }

    // MARK: - Mastery Level Tests

    @Test("低習熟度の項目が高優先")
    func testLowMasteryPriority() {
        let optimizer = StudyOptimizer()

        let lowMastery = StudyItem(title: "未学習", category: .programming)
        lowMastery.masteryLevel = 0.1

        let highMastery = StudyItem(title: "マスター済み", category: .programming)
        highMastery.masteryLevel = 0.9

        let lowResult = optimizer.calculatePriority(for: lowMastery)
        let highResult = optimizer.calculatePriority(for: highMastery)

        // 習熟度要因のスコアは低習熟度が高い
        #expect(lowResult.componentScores.masteryScore > highResult.componentScores.masteryScore)
    }

    // MARK: - Review Priority Tests

    @Test("復習が必要な項目が優先される")
    func testReviewNeedsPriority() {
        let optimizer = StudyOptimizer(weights: .reviewFocused)

        let needsReview = StudyItem(title: "復習必要", category: .programming)
        needsReview.nextReviewDate = Date().addingTimeInterval(-86400)
        needsReview.sessionCount = 1

        let noReview = StudyItem(title: "復習不要", category: .programming)
        noReview.nextReviewDate = Date().addingTimeInterval(86400 * 7)

        let result = optimizer.optimizeStudyOrder(items: [noReview, needsReview])

        #expect(result.orderedItemIds.first == needsReview.id)
    }

    // MARK: - Optimization Result Tests

    @Test("最適化結果の信頼度が妥当な範囲")
    func testConfidenceScoreRange() {
        let optimizer = StudyOptimizer()
        let items = [
            StudyItem(title: "項目1", category: .programming),
            StudyItem(title: "項目2", category: .language),
            StudyItem(title: "項目3", category: .certification)
        ]

        let result = optimizer.optimizeStudyOrder(items: items)

        #expect(result.confidenceScore >= 0.0)
        #expect(result.confidenceScore <= 1.0)
    }

    @Test("最適化結果の全体スコアが妥当な範囲")
    func testOverallScoreRange() {
        let optimizer = StudyOptimizer()
        let items = [
            StudyItem(title: "項目1", category: .programming),
            StudyItem(title: "項目2", category: .language)
        ]

        let result = optimizer.optimizeStudyOrder(items: items)

        #expect(result.overallScore >= 0.0)
        #expect(result.overallScore <= 1.0)
    }

    @Test("使用された重みが結果に含まれる")
    func testWeightsInResult() {
        let customWeights = OptimizationWeights.morningFocused
        let optimizer = StudyOptimizer(weights: customWeights)

        let result = optimizer.optimizeStudyOrder(items: [StudyItem(title: "テスト")])

        #expect(result.weightsUsed == customWeights)
    }

    // MARK: - Convenience Method Tests

    @Test("朝活最適項目の取得が動作する")
    func testGetOptimalMorningItems() {
        let optimizer = StudyOptimizer()

        let hardItem = StudyItem(title: "難しい", category: .mathematics, difficulty: .expert)
        let easyItem = StudyItem(title: "簡単", category: .creative, difficulty: .easy)

        let morningItems = optimizer.getOptimalMorningItems([easyItem, hardItem], limit: 1)

        #expect(morningItems.count == 1)
    }

    @Test("復習優先項目の取得が動作する")
    func testGetReviewPriorityItems() {
        let optimizer = StudyOptimizer()

        let needsReview = StudyItem(title: "復習必要", category: .programming)
        needsReview.nextReviewDate = Date().addingTimeInterval(-86400)

        let noReview = StudyItem(title: "復習不要", category: .programming)

        let reviewItems = optimizer.getReviewPriorityItems([noReview, needsReview], limit: 1)

        #expect(reviewItems.first?.title == "復習必要")
    }

    @Test("期限優先項目の取得が動作する")
    func testGetDeadlinePriorityItems() {
        let optimizer = StudyOptimizer()

        let urgent = StudyItem(title: "緊急", category: .programming)
        urgent.targetDate = Date().addingTimeInterval(86400)

        let relaxed = StudyItem(title: "余裕", category: .programming)
        relaxed.targetDate = Date().addingTimeInterval(86400 * 30)

        let deadlineItems = optimizer.getDeadlinePriorityItems([relaxed, urgent], limit: 1)

        #expect(deadlineItems.first?.title == "緊急")
    }

    // MARK: - Item Update Tests

    @Test("最適化結果がアイテムに適用される")
    func testApplyOptimizationToItems() {
        let optimizer = StudyOptimizer()
        let item = StudyItem(title: "テスト", category: .programming)

        let result = optimizer.optimizeStudyOrder(items: [item])
        optimizer.applyOptimizationToItems([item], result: result)

        #expect(item.aiPriorityScore > 0.0)
        #expect(item.aiConfidenceScore > 0.0)
    }

    // MARK: - Edge Case Tests

    @Test("全項目が同じカテゴリでも最適化される")
    func testSameCategoryItems() {
        let optimizer = StudyOptimizer()
        let items = (1...5).map { StudyItem(title: "項目\($0)", category: .programming) }

        let result = optimizer.optimizeStudyOrder(items: items)

        #expect(result.orderedItemIds.count == 5)
    }

    @Test("極端に多い項目でも最適化される")
    func testManyItems() {
        let optimizer = StudyOptimizer()
        let items = (1...100).map { StudyItem(title: "項目\($0)", category: .programming) }

        let result = optimizer.optimizeStudyOrder(items: items)

        #expect(result.orderedItemIds.count == 100)
    }
}

// MARK: - OptimizationWeights Tests

@Suite("OptimizationWeights テスト")
struct OptimizationWeightsTests {

    @Test("すべてのプリセットが有効な重み合計を持つ")
    func testAllPresetsValid() {
        #expect(OptimizationWeights.default.isValid)
        #expect(OptimizationWeights.deadlineFocused.isValid)
        #expect(OptimizationWeights.morningFocused.isValid)
        #expect(OptimizationWeights.reviewFocused.isValid)
    }

    @Test("カスタム重みのCodableが動作する")
    func testWeightsCodable() throws {
        let weights = OptimizationWeights.morningFocused

        let encoded = try JSONEncoder().encode(weights)
        let decoded = try JSONDecoder().decode(OptimizationWeights.self, from: encoded)

        #expect(decoded == weights)
    }

    @Test("無効な重み合計を検出する")
    func testInvalidWeights() {
        let invalidWeights = OptimizationWeights(
            targetDateWeight: 0.5,
            difficultyTimeWeight: 0.5,
            masteryWeight: 0.5,
            reviewWeight: 0.5,
            timeOfDayWeight: 0.5,
            prerequisiteWeight: 0.5
        )

        #expect(invalidWeights.isValid == false)
    }
}
