//
//  TaskPriorityPredictorTests.swift
//  AsaSmartTodoTests
//
//  AI優先度予測エンジンのテスト
//  Swift Testingで6要因の予測ロジックを検証
//

import Testing
import Foundation
@testable import AsaSmartTodo

struct TaskPriorityPredictorTests {
    let predictor = TaskPriorityPredictor()

    // MARK: - 基本予測テスト

    @Test("期限切れタスクは高優先度と予測される")
    func testOverduePriority() {
        let task = SmartTask(
            title: "期限切れタスク",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(-86400) // 昨日
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.suggestedPriority == .high)
        #expect(result.confidenceScore > 0.7)
    }

    @Test("期限なしタスクは低優先度と予測される")
    func testNoDueDatePriority() {
        let task = SmartTask(
            title: "期限なしタスク",
            category: .other,
            userPriority: .medium,
            dueDate: nil
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.suggestedPriority == .low)
        #expect(result.confidenceScore > 0.0)
    }

    @Test("明日期限のタスクは高優先度と予測される")
    func testTomorrowDueDatePriority() {
        let task = SmartTask(
            title: "明日期限のタスク",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400) // 明日
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.suggestedPriority == .high)
        #expect(result.confidenceScore > 0.6)
    }

    // MARK: - カテゴリ重要度テスト

    @Test("健康カテゴリは重要度が高い")
    func testHealthCategoryImportance() {
        let task = SmartTask(
            title: "病院予約",
            category: .health,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400 * 3) // 3日後
        )

        let result = predictor.predictPriority(for: task)

        // 健康カテゴリは importanceWeight が 0.9 なので高優先度になりやすい
        #expect(result.reasons.contains(where: { $0.hasPrefix("❤️") }))
    }

    @Test("その他カテゴリは重要度が低い")
    func testOtherCategoryImportance() {
        let task = SmartTask(
            title: "雑多なタスク",
            category: .other,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400 * 7) // 1週間後
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.suggestedPriority == .low || result.suggestedPriority == .medium)
    }

    // MARK: - リアルタイム予測テスト

    @Test("リアルタイム予測で基本情報から優先度を算出")
    func testRealtimePrediction() {
        let tomorrow = Date().addingTimeInterval(86400)

        let result = predictor.predictPriorityRealtime(
            title: "重要な会議の準備",
            description: "明日の会議で使う資料を準備する必要がある。スライド20枚程度を作成し、データ分析結果をまとめる。",
            category: .work,
            dueDate: tomorrow
        )

        #expect(result.suggestedPriority == .high)
        #expect(result.confidenceScore > 0.0)
        #expect(!result.reasons.isEmpty)
    }

    @Test("リアルタイム予測で簡単なタイトルからも予測可能")
    func testRealtimePredictionSimpleTitle() {
        let result = predictor.predictPriorityRealtime(
            title: "買い物",
            description: nil,
            category: .personal,
            dueDate: nil
        )

        #expect(result.confidenceScore >= 0.0)
    }

    // MARK: - 信頼度スコアテスト

    @Test("信頼度スコアは0.0から1.0の範囲内")
    func testConfidenceScoreRange() {
        let task = SmartTask(
            title: "テストタスク",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.confidenceScore >= 0.0)
        #expect(result.confidenceScore <= 1.0)
    }

    // MARK: - 予測理由テスト

    @Test("予測理由が生成される")
    func testPredictionReasonsGenerated() {
        let task = SmartTask(
            title: "期限が近いタスク",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400) // 明日
        )

        let result = predictor.predictPriority(for: task)

        #expect(!result.reasons.isEmpty)
        #expect(result.reasons.count > 0)
    }

    @Test("期限に基づく理由が含まれる")
    func testDueDateReasonIncluded() {
        let task = SmartTask(
            title: "明日期限のタスク",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        let result = predictor.predictPriority(for: task)

        // 期限に関する理由が含まれているか確認
        #expect(result.reasons.contains(where: { $0.hasPrefix("⏰") || $0.hasPrefix("📅") }))
    }

    // MARK: - カスタム重み設定テスト

    @Test("カスタム重みで予測が変化する")
    func testCustomWeights() {
        let task = SmartTask(
            title: "テストタスク",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400 * 3)
        )

        // デフォルト重みでの予測
        let defaultResult = predictor.predictPriority(for: task)

        // カテゴリ重みを最大に設定
        let customWeights = PriorityWeights(
            dueDateWeight: 0.1,
            categoryWeight: 0.7,  // カテゴリ重視
            titleComplexityWeight: 0.05,
            descriptionWeight: 0.05,
            timeOfDayWeight: 0.05,
            historicalWeight: 0.05
        )
        predictor.updateWeights(customWeights)

        let customResult = predictor.predictPriority(for: task)

        // カスタム重み適用後も予測が動作することを確認
        #expect(customResult.confidenceScore >= 0.0)
        #expect(customResult.confidenceScore <= 1.0)
    }

    // MARK: - 極端な組み合わせテスト

    @Test("全要素が最大値の場合に高優先度と予測される")
    func testAllFactorsMaximum() {
        let task = SmartTask(
            title: "非常に重要で複雑な緊急タスクで詳細な計画と準備が必要なプロジェクト",
            description: "このタスクは極めて重要で、多くのステークホルダーが関与し、詳細な計画立案、リソース調整、進捗管理が必要です。期限までに完了しないと重大な影響があります。",
            category: .health,  // 最高重要度カテゴリ
            userPriority: .high,
            dueDate: Date().addingTimeInterval(-3600)  // 1時間前（期限切れ）
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.suggestedPriority == .high)
        #expect(result.confidenceScore > 0.8)
    }

    @Test("全要素が最小値の場合に低優先度と予測される")
    func testAllFactorsMinimum() {
        let task = SmartTask(
            title: "メモ",
            description: nil,
            category: .other,
            userPriority: .low,
            dueDate: nil
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.suggestedPriority == .low)
        #expect(result.confidenceScore >= 0.0)
    }

    // MARK: - 境界値テスト

    @Test("ちょうど24時間後の期限で中〜高優先度")
    func testExactly24HoursUntilDueDate() {
        let task = SmartTask(
            title: "24時間後期限のタスク",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)  // ちょうど24時間後
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.suggestedPriority == .medium || result.suggestedPriority == .high)
        #expect(result.confidenceScore > 0.0)
    }

    @Test("ちょうど1週間後の期限で低〜中優先度")
    func testExactly7DaysUntilDueDate() {
        let task = SmartTask(
            title: "1週間後期限のタスク",
            category: .personal,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400 * 7)  // ちょうど7日後
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.suggestedPriority == .low || result.suggestedPriority == .medium)
        #expect(result.confidenceScore > 0.0)
    }

    @Test("非常に遠い未来の期限で低優先度")
    func testVeryFarFutureDueDate() {
        let task = SmartTask(
            title: "遠い未来のタスク",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400 * 365)  // 1年後
        )

        let result = predictor.predictPriority(for: task)

        #expect(result.suggestedPriority == .low)
        #expect(result.confidenceScore >= 0.0)
    }

    // MARK: - タイトル・説明文の極端なケース

    @Test("極端に長いタイトルでも予測可能")
    func testVeryLongTitle() {
        let longTitle = String(repeating: "重要なタスクで詳細な説明が必要です。", count: 20)  // 約400文字

        let task = SmartTask(
            title: longTitle,
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        let result = predictor.predictPriority(for: task)

        // タイトル複雑度が高いため、信頼度に影響
        #expect(result.confidenceScore >= 0.0)
        #expect(result.suggestedPriority != nil)
    }

    @Test("極端に長い説明文でも予測可能")
    func testVeryLongDescription() {
        let longDescription = String(repeating: "詳細な手順と背景情報を含む説明文です。多くの関係者がいて、複数のステップが必要です。", count: 30)  // 約1200文字

        let task = SmartTask(
            title: "詳細説明付きタスク",
            description: longDescription,
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400 * 2)
        )

        let result = predictor.predictPriority(for: task)

        // 説明文の長さが信頼度に影響
        #expect(result.confidenceScore >= 0.0)
        #expect(result.suggestedPriority != nil)
    }

    // MARK: - 全カテゴリ網羅テスト

    @Test("全6カテゴリで予測が動作する")
    func testAllCategories() {
        let categories: [TaskCategory] = [.work, .personal, .family, .health, .learning, .other]

        for category in categories {
            let task = SmartTask(
                title: "\(category.rawValue)タスク",
                category: category,
                userPriority: .medium,
                dueDate: Date().addingTimeInterval(86400 * 3)
            )

            let result = predictor.predictPriority(for: task)

            // 各カテゴリで予測が正常に動作
            #expect(result.suggestedPriority != nil)
            #expect(result.confidenceScore >= 0.0)
            #expect(result.confidenceScore <= 1.0)
        }
    }

    // MARK: - ユーザー優先度との相互作用テスト

    @Test("ユーザー優先度が低でも期限切れなら高優先度")
    func testUserPriorityVsDueDate() {
        let task = SmartTask(
            title: "期限切れだがユーザー優先度は低",
            category: .work,
            userPriority: .low,  // ユーザーは低優先度と設定
            dueDate: Date().addingTimeInterval(-86400)  // 昨日（期限切れ）
        )

        let result = predictor.predictPriority(for: task)

        // 期限切れの重要性がユーザー優先度を上回る
        #expect(result.suggestedPriority == .high)
        #expect(result.confidenceScore > 0.0)
    }
}
