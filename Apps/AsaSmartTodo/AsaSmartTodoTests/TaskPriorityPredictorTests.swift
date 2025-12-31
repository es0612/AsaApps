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
        #expect(result.reasons.contains { $0.emoji == "❤️" })
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

        #expect(result.suggestedPriority != nil)
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
        #expect(result.reasons.contains { $0.emoji == "⏰" || $0.emoji == "📅" })
    }
}
