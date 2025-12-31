//
//  SmartTaskTests.swift
//  AsaSmartTodoTests
//
//  SmartTaskモデルのテスト
//  AI予測結果の適用、フィードバック処理、タスク操作を検証
//

import Testing
import Foundation
@testable import AsaSmartTodo

struct SmartTaskTests {

    // MARK: - 初期化テスト

    @Test("タスクが正しく初期化される")
    func testTaskInitialization() {
        let task = SmartTask(
            title: "テストタスク",
            description: "テスト用の説明",
            category: .work,
            userPriority: .high,
            dueDate: Date()
        )

        #expect(task.title == "テストタスク")
        #expect(task.taskDescription == "テスト用の説明")
        #expect(task.category == .work)
        #expect(task.userPriority == .high)
        #expect(task.finalPriority == .high) // 初期状態ではuserPriorityと同じ
        #expect(task.dueDate != nil)
        #expect(task.isCompleted == false)
        #expect(task.wasAIPredictionAccepted == nil) // 未判定
    }

    @Test("最小限のパラメータでタスクを作成")
    func testTaskMinimalInitialization() {
        let task = SmartTask(title: "シンプルタスク")

        #expect(task.title == "シンプルタスク")
        #expect(task.taskDescription == nil)
        #expect(task.category == .other)
        #expect(task.userPriority == .medium)
        #expect(task.dueDate == nil)
    }

    // MARK: - AI予測適用テスト

    @Test("AI予測結果を正しく適用できる")
    func testApplyPrediction() {
        let task = SmartTask(
            title: "タスク",
            userPriority: .medium
        )

        let prediction = PredictionResult(
            suggestedPriority: .high,
            confidenceScore: 0.85,
            reasons: [
                PredictionReason(emoji: "⏰", description: "期限が近い", weight: 0.35)
            ]
        )

        task.applyPrediction(prediction)

        #expect(task.aiPriority == .high)
        #expect(task.confidenceScore == 0.85)
        #expect(task.predictionReasons.count == 1)
        #expect(task.predictionReasons.first?.emoji == "⏰")
    }

    // MARK: - AI予測フィードバックテスト

    @Test("AI予測を採用すると最終優先度が更新される")
    func testAcceptAIPrediction() {
        let task = SmartTask(
            title: "タスク",
            userPriority: .medium
        )

        let prediction = PredictionResult(
            suggestedPriority: .high,
            confidenceScore: 0.85,
            reasons: []
        )
        task.applyPrediction(prediction)

        task.acceptAIPrediction()

        #expect(task.finalPriority == .high)
        #expect(task.wasAIPredictionAccepted == true)
    }

    @Test("AI予測を却下するとユーザー優先度が維持される")
    func testRejectAIPrediction() {
        let task = SmartTask(
            title: "タスク",
            userPriority: .medium
        )

        let prediction = PredictionResult(
            suggestedPriority: .high,
            confidenceScore: 0.85,
            reasons: []
        )
        task.applyPrediction(prediction)

        task.rejectAIPrediction()

        #expect(task.finalPriority == .medium)
        #expect(task.wasAIPredictionAccepted == false)
    }

    @Test("AI予測なしで却下を呼んでも影響なし")
    func testRejectAIPredictionWithoutPrediction() {
        let task = SmartTask(
            title: "タスク",
            userPriority: .medium
        )

        task.rejectAIPrediction()

        #expect(task.finalPriority == .medium)
        #expect(task.wasAIPredictionAccepted == false)
    }

    // MARK: - タスク完了テスト

    @Test("タスクを完了できる")
    func testCompleteTask() {
        let task = SmartTask(title: "タスク")

        task.complete()

        #expect(task.isCompleted == true)
        #expect(task.completedAt != nil)
    }

    @Test("タスクを未完了に戻せる")
    func testUncompleteTask() {
        let task = SmartTask(title: "タスク")

        task.complete()
        #expect(task.isCompleted == true)

        task.uncomplete()
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }

    // MARK: - 期限切れ判定テスト

    @Test("期限切れタスクを正しく判定")
    func testIsOverdue() {
        let yesterday = Date().addingTimeInterval(-86400)
        let task = SmartTask(
            title: "期限切れタスク",
            dueDate: yesterday
        )

        #expect(task.isOverdue == true)
    }

    @Test("期限が未来のタスクは期限切れでない")
    func testIsNotOverdue() {
        let tomorrow = Date().addingTimeInterval(86400)
        let task = SmartTask(
            title: "未来の期限タスク",
            dueDate: tomorrow
        )

        #expect(task.isOverdue == false)
    }

    @Test("完了済みタスクは期限切れでない")
    func testCompletedTaskIsNotOverdue() {
        let yesterday = Date().addingTimeInterval(-86400)
        let task = SmartTask(
            title: "完了済みタスク",
            dueDate: yesterday
        )
        task.complete()

        #expect(task.isOverdue == false)
    }

    @Test("期限未設定タスクは期限切れでない")
    func testNoDueDateIsNotOverdue() {
        let task = SmartTask(
            title: "期限未設定タスク",
            dueDate: nil
        )

        #expect(task.isOverdue == false)
    }

    // MARK: - 期限までの日数テスト

    @Test("期限までの日数を正しく計算")
    func testDaysUntilDue() {
        let tomorrow = Date().addingTimeInterval(86400)
        let task = SmartTask(
            title: "タスク",
            dueDate: tomorrow
        )

        #expect(task.daysUntilDue == 1)
    }

    @Test("期限未設定の場合nilを返す")
    func testDaysUntilDueWithoutDueDate() {
        let task = SmartTask(
            title: "タスク",
            dueDate: nil
        )

        #expect(task.daysUntilDue == nil)
    }

    // MARK: - タスク更新テスト

    @Test("タスク情報を更新できる")
    func testUpdateDetails() {
        let task = SmartTask(
            title: "元のタイトル",
            description: "元の説明",
            category: .other,
            userPriority: .low,
            dueDate: nil
        )

        let newDate = Date().addingTimeInterval(86400)
        task.updateDetails(
            title: "新しいタイトル",
            description: "新しい説明",
            category: .work,
            userPriority: .high,
            dueDate: newDate
        )

        #expect(task.title == "新しいタイトル")
        #expect(task.taskDescription == "新しい説明")
        #expect(task.category == .work)
        #expect(task.userPriority == .high)
        #expect(task.dueDate == newDate)
    }

    @Test("優先度変更時にAI予測フィードバックがリセットされる")
    func testUpdatePriorityResetsAIFeedback() {
        let task = SmartTask(
            title: "タスク",
            userPriority: .medium
        )

        let prediction = PredictionResult(
            suggestedPriority: .high,
            confidenceScore: 0.85,
            reasons: []
        )
        task.applyPrediction(prediction)
        task.acceptAIPrediction()

        #expect(task.wasAIPredictionAccepted == true)

        // ユーザーが優先度を変更
        task.updateDetails(userPriority: .low)

        #expect(task.wasAIPredictionAccepted == nil) // リセットされる
    }

    // MARK: - Raw Value変換テスト

    @Test("優先度のRaw Value変換が正しく動作")
    func testPriorityRawValueConversion() {
        let task = SmartTask(
            title: "タスク",
            userPriority: .high
        )

        #expect(task.userPriorityRawValue == PriorityLevel.high.rawValue)
        #expect(task.userPriority == .high)
    }

    @Test("カテゴリのRaw Value変換が正しく動作")
    func testCategoryRawValueConversion() {
        let task = SmartTask(
            title: "タスク",
            category: .work
        )

        #expect(task.categoryRawValue == TaskCategory.work.rawValue)
        #expect(task.category == .work)
    }
}
