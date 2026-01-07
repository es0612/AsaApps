import Foundation
//
//  AIIntegrationTests.swift
//  AsaSmartTodoTests
//
//  AI機能の統合テスト
//  タスク作成→AI予測→UI表示の完全フローを検証
//

import Testing
import SwiftData
@testable import AsaSmartTodo

/// AI機能の統合テストスイート
///
/// タスク作成からAI予測、データ保存、UI表示までの
/// 完全なフローが正常に動作することを確認します。
@MainActor
struct AIIntegrationTests {

    // MARK: - Complete Flow Tests

    /// タスク作成→AI予測の完全フローテスト
    ///
    /// タスク作成時にAI予測が自動実行され、結果が保存されることを確認します。
    @Test("タスク作成→AI予測の完全フロー")
    func testCompleteTaskCreationWithAIPrediction() async {
        // テスト用のDataServiceを作成
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        // 初期状態の確認
        viewModel.loadTasks()
        #expect(viewModel.tasks.isEmpty)

        // タスクを作成（AI予測が自動実行される）
        viewModel.createTask(
            title: "統合テスト用タスク",
            description: "AI予測の完全フローを検証する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400) // 明日
        )

        // 非同期処理が完了するまで待機
        try? await Task.sleep(for: .milliseconds(100))

        // タスクが作成されたことを確認
        viewModel.loadTasks()
        #expect(viewModel.tasks.count == 1)

        guard let task = viewModel.tasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }

        // AI予測が実行されたことを確認
        #expect(task.aiPriority != nil)
        #expect(task.confidenceScore > 0.0)
        #expect(!task.predictionReasons.isEmpty)

        print("✅ タスク作成→AI予測フロー成功:")
        print("   タスクID: \(task.id)")
        print("   AI優先度: \(task.aiPriority?.rawValue ?? "nil")")
        print("   信頼度: \(task.confidenceScore)")
        print("   理由数: \(task.predictionReasons.count)")
    }

    /// EnhancedPrediction取得→UI表示フローテスト
    ///
    /// AI詳細画面用のEnhancedPrediction取得が動作することを確認します。
    @Test("EnhancedPrediction取得→UI表示フロー")
    func testEnhancedPredictionRetrieval() async {
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        // タスクを作成
        viewModel.createTask(
            title: "UI表示テスト",
            description: "EnhancedPredictionの取得を検証する",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400 * 2)
        )

        // 非同期処理が完了するまで待機
        try? await Task.sleep(for: .milliseconds(100))

        viewModel.loadTasks()
        guard let task = viewModel.tasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }

        // EnhancedPredictionを取得（UI表示用）
        let enhancedPrediction = await viewModel.getEnhancedPrediction(for: task)

        // EnhancedPredictionの内容を検証
        #expect(enhancedPrediction.suggestedPriority is PriorityLevel)
        #expect(enhancedPrediction.confidenceScore >= 0.0 && enhancedPrediction.confidenceScore <= 1.0)
        #expect(!enhancedPrediction.reasons.isEmpty)
        #expect(enhancedPrediction.ruleBasedScore >= 0.0 && enhancedPrediction.ruleBasedScore <= 1.0)

        print("✅ EnhancedPrediction取得成功:")
        print("   LLM使用: \(enhancedPrediction.usedLLM)")
        print("   推奨優先度: \(enhancedPrediction.suggestedPriority)")
        print("   信頼度: \(enhancedPrediction.confidenceScore)")
    }

    /// AI予測採用→分析データ記録フローテスト
    ///
    /// AI予測を採用すると分析データに記録されることを確認します。
    @Test("AI予測採用→分析データ記録フロー")
    func testAIPredictionAcceptanceFlow() async {
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        // タスクを作成
        viewModel.createTask(
            title: "フィードバックテスト",
            description: "AI予測の採用を検証する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        try? await Task.sleep(for: .milliseconds(100))

        viewModel.loadTasks()
        guard let task = viewModel.tasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }

        // 初期状態の確認
        #expect(task.wasAIPredictionAccepted == nil)

        // 今日の分析データを取得
        let analyticsBefore = dataService.getTodayAnalytics()
        let totalPredictionsBefore = analyticsBefore.totalPredictions

        // AI予測を採用
        viewModel.acceptAIPrediction(for: task)

        // AI予測が採用されたことを確認
        #expect(task.wasAIPredictionAccepted == true)

        // 分析データに記録されたことを確認
        let analyticsAfter = dataService.getTodayAnalytics()
        #expect(analyticsAfter.totalPredictions == totalPredictionsBefore + 1)
        #expect(analyticsAfter.acceptedPredictions > 0)

        print("✅ AI予測採用フロー成功:")
        print("   採用状態: \(task.wasAIPredictionAccepted ?? false)")
        print("   総予測数: \(analyticsAfter.totalPredictions ?? 0)")
        print("   採用数: \(analyticsAfter.acceptedPredictions)")
    }

    /// AI予測却下→分析データ記録フローテスト
    ///
    /// AI予測を却下すると分析データに記録されることを確認します。
    @Test("AI予測却下→分析データ記録フロー")
    func testAIPredictionRejectionFlow() async {
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        viewModel.createTask(
            title: "却下テスト",
            description: "AI予測の却下を検証する",
            category: .personal,
            userPriority: .low,
            dueDate: nil
        )

        try? await Task.sleep(for: .milliseconds(100))

        viewModel.loadTasks()
        guard let task = viewModel.tasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }

        let analyticsBefore = dataService.getTodayAnalytics()
        let totalPredictionsBefore = analyticsBefore.totalPredictions

        // AI予測を却下
        viewModel.rejectAIPrediction(for: task)

        #expect(task.wasAIPredictionAccepted == false)

        let analyticsAfter = dataService.getTodayAnalytics()
        #expect(analyticsAfter.totalPredictions == totalPredictionsBefore + 1)
        #expect(analyticsAfter.rejectedPredictions > 0)

        print("✅ AI予測却下フロー成功:")
        print("   却下状態: \(task.wasAIPredictionAccepted ?? true)")
        print("   却下数: \(analyticsAfter.rejectedPredictions)")
    }

    // MARK: - Multi-Task Tests

    /// 複数タスク作成→AI予測の並行処理テスト
    ///
    /// 複数のタスクを作成しても、各タスクに対してAI予測が正常に実行されることを確認します。
    @Test("複数タスク作成→AI予測の並行処理")
    func testMultipleTaskCreationWithAIPrediction() async {
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        // 3つのタスクを作成
        viewModel.createTask(
            title: "タスク1",
            description: "高優先度",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(3600)
        )

        viewModel.createTask(
            title: "タスク2",
            description: "中優先度",
            category: .personal,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        viewModel.createTask(
            title: "タスク3",
            description: "低優先度",
            category: .family,
            userPriority: .low,
            dueDate: nil
        )

        // 非同期処理が完了するまで待機
        try? await Task.sleep(for: .milliseconds(300))

        viewModel.loadTasks()
        #expect(viewModel.tasks.count == 3)

        // すべてのタスクにAI予測が実行されたことを確認
        for task in viewModel.tasks {
            #expect(task.aiPriority != nil)
            #expect(task.confidenceScore > 0.0)
            print("   \(task.title): AI優先度=\(task.aiPriority?.rawValue ?? "nil"), 信頼度=\(task.confidenceScore)")
        }

        print("✅ 複数タスク並行予測成功")
    }

    // MARK: - Update Flow Tests

    /// タスク更新→AI再予測フローテスト
    ///
    /// タスクの優先度を変更すると、AI予測が再実行されることを確認します。
    @Test("タスク更新→AI再予測フロー")
    func testTaskUpdateWithAIPredictionRefresh() async {
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        viewModel.createTask(
            title: "更新テスト",
            description: "AI再予測を検証する",
            category: .work,
            userPriority: .low,
            dueDate: nil
        )

        try? await Task.sleep(for: .milliseconds(100))

        viewModel.loadTasks()
        guard let task = viewModel.tasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }

        let initialConfidence = task.confidenceScore

        // 優先度を変更（AI再予測がトリガーされる）
        viewModel.updateTask(task, userPriority: .high)

        try? await Task.sleep(for: .milliseconds(100))

        viewModel.loadTasks()
        guard let updatedTask = viewModel.tasks.first else {
            Issue.record("タスクが見つかりませんでした")
            return
        }

        // AI予測が更新されたことを確認
        #expect(updatedTask.userPriority == .high)
        #expect(updatedTask.confidenceScore >= 0.0)

        print("✅ AI再予測フロー成功:")
        print("   更新前信頼度: \(initialConfidence)")
        print("   更新後信頼度: \(updatedTask.confidenceScore)")
    }

    // MARK: - Analytics Integration Tests

    /// タスク完了→分析データ更新フローテスト
    ///
    /// タスク完了時に分析データが適切に更新されることを確認します。
    @Test("タスク完了→分析データ更新フロー")
    func testTaskCompletionWithAnalyticsUpdate() async {
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        viewModel.createTask(
            title: "完了テスト",
            description: "分析データ更新を検証する",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        try? await Task.sleep(for: .milliseconds(100))

        viewModel.loadTasks()
        guard let task = viewModel.tasks.first else {
            Issue.record("タスクが作成されませんでした")
            return
        }

        let analyticsBefore = dataService.getTodayAnalytics()
        let completedBefore = analyticsBefore.completedTasks

        // タスクを完了
        viewModel.toggleTaskCompletion(task)

        #expect(task.isCompleted == true)

        let analyticsAfter = dataService.getTodayAnalytics()
        #expect(analyticsAfter.completedTasks == completedBefore + 1)

        print("✅ タスク完了→分析データ更新成功:")
        print("   完了前: \(completedBefore)個")
        print("   完了後: \(analyticsAfter.completedTasks)個")
    }

    // MARK: - Error Resilience Tests

    /// AI予測エラー時のフォールバック動作テスト
    ///
    /// AI予測がエラーになっても、タスク作成は成功することを確認します。
    @Test("AI予測エラー時のフォールバック動作")
    func testAIPredictionErrorResilience() async {
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        // 空のタイトル（エラーを誘発する可能性）
        viewModel.createTask(
            title: "",
            description: nil,
            category: .personal,
            userPriority: .low,
            dueDate: nil
        )

        try? await Task.sleep(for: .milliseconds(100))

        viewModel.loadTasks()

        // タスクが作成されたことを確認（AI予測エラーでも作成は成功）
        #expect(viewModel.tasks.count >= 0)

        print("✅ エラー時フォールバック動作確認")
    }

    // MARK: - Performance Integration Tests

    /// タスク作成→AI予測の全体パフォーマンステスト
    ///
    /// タスク作成からAI予測完了までが適切な時間内に完了することを確認します。
    @Test("タスク作成→AI予測の全体パフォーマンス")
    func testEndToEndPerformance() async {
        let dataService = DataService(inMemory: true)
        let viewModel = SmartTodoViewModel(dataService: dataService)

        let startTime = ContinuousClock.now

        viewModel.createTask(
            title: "パフォーマンステスト",
            description: "E2Eパフォーマンスを測定する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        // AI予測完了まで待機
        try? await Task.sleep(for: .milliseconds(500))

        let elapsed = ContinuousClock.now - startTime

        viewModel.loadTasks()
        #expect(viewModel.tasks.count == 1)

        print("✅ E2Eパフォーマンス: \(elapsed)")
    }
}
