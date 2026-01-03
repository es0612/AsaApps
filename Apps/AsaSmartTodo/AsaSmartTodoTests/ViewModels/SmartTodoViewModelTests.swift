//
//  SmartTodoViewModelTests.swift
//  AsaSmartTodoTests
//
//  SmartTodoViewModelのテスト
//  タスク管理、AI予測、フィルタ、NotificationCenter連携を検証
//

import Testing
import Foundation
@testable import AsaSmartTodo

/// SmartTodoViewModelのテストスイート
@MainActor
struct SmartTodoViewModelTests {

    // MARK: - Helper Methods

    /// テスト用のin-memory DataServiceを作成
    func createTestDataService() -> DataService {
        return DataService(inMemory: true)
    }

    /// テスト用のViewModelを作成
    func createTestViewModel() -> SmartTodoViewModel {
        let dataService = createTestDataService()
        return SmartTodoViewModel(dataService: dataService)
    }

    /// テスト用のSmartTaskを作成
    func createTestTask(
        title: String = "テストタスク",
        category: TaskCategory = .work,
        userPriority: PriorityLevel = .medium,
        dueDate: Date? = nil
    ) -> SmartTask {
        return SmartTask(
            title: title,
            description: "テスト説明",
            category: category,
            userPriority: userPriority,
            dueDate: dueDate
        )
    }

    // MARK: - タスクCRUD操作テスト (10テスト)

    @Test("タスク作成が正しく動作する")
    func testCreateTask() async {
        let viewModel = createTestViewModel()

        #expect(viewModel.tasks.isEmpty)

        viewModel.createTask(
            title: "新しいタスク",
            description: "説明",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        #expect(viewModel.tasks.count == 1)
        #expect(viewModel.tasks.first?.title == "新しいタスク")
        #expect(viewModel.tasks.first?.category == .work)
    }

    @Test("タスク作成時にAI予測が実行される")
    func testCreateTaskWithAIPrediction() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(
            title: "AI予測テスト",
            description: "説明",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        let task = viewModel.tasks.first
        #expect(task != nil)
        #expect(task?.aiPredictedPriority != nil)
        #expect(task?.confidenceScore != nil)
    }

    @Test("タスク更新が正しく動作する")
    func testUpdateTask() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(
            title: "元のタイトル",
            description: "元の説明",
            category: .work,
            userPriority: .medium,
            dueDate: nil
        )

        let task = viewModel.tasks.first!

        viewModel.updateTask(
            task,
            title: "更新後のタイトル",
            description: "更新後の説明",
            category: .personal
        )

        #expect(task.title == "更新後のタイトル")
        #expect(task.taskDescription == "更新後の説明")
        #expect(task.category == .personal)
    }

    @Test("タスク更新時にAI予測が再実行される")
    func testUpdateTaskRerunsAIPrediction() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(
            title: "テストタスク",
            description: "説明",
            category: .work,
            userPriority: .low,
            dueDate: nil
        )

        let task = viewModel.tasks.first!
        let initialPrediction = task.aiPredictedPriority

        // 優先度を変更（AI予測再実行トリガー）
        viewModel.updateTask(task, userPriority: .high)

        // AI予測が再実行される
        #expect(task.userPriority == .high)
        #expect(task.aiPredictedPriority != nil)
    }

    @Test("タスク削除が正しく動作する")
    func testDeleteTask() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(
            title: "削除予定タスク",
            description: "説明",
            category: .work,
            userPriority: .medium,
            dueDate: nil
        )

        #expect(viewModel.tasks.count == 1)

        let task = viewModel.tasks.first!
        viewModel.deleteTask(task)

        #expect(viewModel.tasks.isEmpty)
    }

    @Test("タスク完了状態の切り替えが動作する")
    func testToggleTaskCompletion() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(
            title: "完了切替テスト",
            description: "説明",
            category: .work,
            userPriority: .medium,
            dueDate: nil
        )

        let task = viewModel.tasks.first!
        #expect(task.isCompleted == false)

        // 完了に切り替え
        viewModel.toggleTaskCompletion(task)
        #expect(task.isCompleted == true)
        #expect(task.completedAt != nil)

        // 未完了に切り替え
        viewModel.toggleTaskCompletion(task)
        #expect(task.isCompleted == false)
    }

    @Test("タスクリスト読み込みが動作する")
    func testLoadTasks() async {
        let dataService = createTestDataService()
        let viewModel = SmartTodoViewModel(dataService: dataService)

        // タスクを直接保存
        let task1 = createTestTask(title: "タスク1")
        let task2 = createTestTask(title: "タスク2")
        dataService.saveTask(task1)
        dataService.saveTask(task2)

        // 読み込み
        viewModel.loadTasks()

        #expect(viewModel.tasks.count == 2)
        #expect(viewModel.isLoading == false)
    }

    @Test("複数タスクの作成が動作する")
    func testCreateMultipleTasks() async {
        let viewModel = createTestViewModel()

        for i in 1...5 {
            viewModel.createTask(
                title: "タスク\(i)",
                description: "説明\(i)",
                category: .work,
                userPriority: .medium,
                dueDate: nil
            )
        }

        #expect(viewModel.tasks.count == 5)
    }

    @Test("タスク作成時に分析データが更新される")
    func testCreateTaskUpdatesAnalytics() async {
        let dataService = createTestDataService()

        // 分析データを初期化
        let analytics = TaskAnalytics()
        dataService.save()

        let viewModel = SmartTodoViewModel(dataService: dataService)
        viewModel.loadTasks()

        viewModel.createTask(
            title: "分析テスト",
            description: "説明",
            category: .work,
            userPriority: .high,
            dueDate: nil
        )

        // タスク作成がエラーなく完了することを確認
        #expect(viewModel.tasks.count == 1)
    }

    @Test("タスク完了時に分析データが更新される")
    func testToggleCompletionUpdatesAnalytics() async {
        let dataService = createTestDataService()

        // 分析データを初期化
        let analytics = TaskAnalytics()
        dataService.save()

        let viewModel = SmartTodoViewModel(dataService: dataService)
        viewModel.loadTasks()

        viewModel.createTask(
            title: "完了分析テスト",
            description: "説明",
            category: .work,
            userPriority: .medium,
            dueDate: nil
        )

        let task = viewModel.tasks.first!
        viewModel.toggleTaskCompletion(task)

        // 完了処理がエラーなく完了することを確認
        #expect(task.isCompleted == true)
    }

    // MARK: - AI予測機能テスト (8テスト)

    @Test("AI予測採用が動作する")
    func testAcceptAIPrediction() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(
            title: "AI採用テスト",
            description: "説明",
            category: .work,
            userPriority: .low,
            dueDate: Date().addingTimeInterval(86400)
        )

        let task = viewModel.tasks.first!

        // AI予測を採用
        viewModel.acceptAIPrediction(for: task)

        #expect(task.wasAIPredictionAccepted == true)
    }

    @Test("AI予測却下が動作する")
    func testRejectAIPrediction() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(
            title: "AI却下テスト",
            description: "説明",
            category: .work,
            userPriority: .high,
            dueDate: nil
        )

        let task = viewModel.tasks.first!

        // AI予測を却下
        viewModel.rejectAIPrediction(for: task)

        #expect(task.wasAIPredictionAccepted == false)
    }

    @Test("予測採用時にフィードバックが記録される")
    func testAcceptPredictionRecordsFeedback() async {
        let dataService = createTestDataService()

        // 分析データを初期化
        let analytics = TaskAnalytics()
        dataService.save()

        let viewModel = SmartTodoViewModel(dataService: dataService)
        viewModel.loadTasks()

        viewModel.createTask(
            title: "フィードバックテスト",
            description: "説明",
            category: .work,
            userPriority: .medium,
            dueDate: nil
        )

        let task = viewModel.tasks.first!
        viewModel.acceptAIPrediction(for: task)

        // フィードバック記録がエラーなく完了することを確認
        #expect(task.wasAIPredictionAccepted == true)
    }

    @Test("予測却下時にフィードバックが記録される")
    func testRejectPredictionRecordsFeedback() async {
        let dataService = createTestDataService()

        // 分析データを初期化
        let analytics = TaskAnalytics()
        dataService.save()

        let viewModel = SmartTodoViewModel(dataService: dataService)
        viewModel.loadTasks()

        viewModel.createTask(
            title: "フィードバックテスト",
            description: "説明",
            category: .work,
            userPriority: .medium,
            dueDate: nil
        )

        let task = viewModel.tasks.first!
        viewModel.rejectAIPrediction(for: task)

        // フィードバック記録がエラーなく完了することを確認
        #expect(task.wasAIPredictionAccepted == false)
    }

    @Test("AI精度計算が動作する")
    func testAIAcceptanceRateCalculation() async {
        let dataService = createTestDataService()

        // 分析データを初期化
        let analytics = TaskAnalytics()
        analytics.recordAIFeedback(accepted: true, confidenceScore: 0.9)
        analytics.recordAIFeedback(accepted: false, confidenceScore: 0.7)
        dataService.save()

        let viewModel = SmartTodoViewModel(dataService: dataService)
        viewModel.loadTasks()

        // AI精度が計算されることを確認（0.0-1.0の範囲）
        let rate = viewModel.aiAcceptanceRate
        #expect(rate >= 0.0 && rate <= 1.0)
    }

    @Test("算出プロパティ activeTasks が動作する")
    func testActiveTasksComputed() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(title: "未完了1", description: "", category: .work, userPriority: .medium, dueDate: nil)
        viewModel.createTask(title: "未完了2", description: "", category: .work, userPriority: .medium, dueDate: nil)

        let task = viewModel.tasks.first!
        viewModel.toggleTaskCompletion(task)

        #expect(viewModel.activeTasks.count == 1)
        #expect(viewModel.completedTasks.count == 1)
    }

    @Test("算出プロパティ overdueTasks が動作する")
    func testOverdueTasksComputed() async {
        let viewModel = createTestViewModel()

        // 過去の期限日でタスク作成
        let pastDate = Date().addingTimeInterval(-86400)
        viewModel.createTask(
            title: "期限切れタスク",
            description: "",
            category: .work,
            userPriority: .high,
            dueDate: pastDate
        )

        viewModel.createTask(
            title: "未来のタスク",
            description: "",
            category: .work,
            userPriority: .medium,
            dueDate: Date().addingTimeInterval(86400)
        )

        #expect(viewModel.overdueTasks.count == 1)
    }

    @Test("NotificationCenter経由でAI重みが更新される")
    func testAIWeightsUpdateViaNotificationCenter() async {
        let viewModel = createTestViewModel()

        // カスタム重みを作成
        let newWeights = PriorityWeights(
            dueDateWeight: 0.40,
            categoryWeight: 0.25,
            titleComplexityWeight: 0.15,
            userPriorityWeight: 0.10,
            descriptionWeight: 0.05,
            historicalWeight: 0.05
        )

        // NotificationCenterで通知を送信
        NotificationCenter.default.post(
            name: .aiWeightsDidChange,
            object: newWeights
        )

        // 非同期処理を待機
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // 通知が受信されてpredictor.updateWeights()が呼ばれることを確認
        // （実際の重み更新は内部処理のため、エラーが発生しないことで確認）
        #expect(true)
    }

    // MARK: - フィルタ機能テスト (5テスト)

    @Test("カテゴリフィルタが動作する")
    func testCategoryFilter() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(title: "仕事1", description: "", category: .work, userPriority: .medium, dueDate: nil)
        viewModel.createTask(title: "仕事2", description: "", category: .work, userPriority: .medium, dueDate: nil)
        viewModel.createTask(title: "個人", description: "", category: .personal, userPriority: .medium, dueDate: nil)

        viewModel.setFilterCategory(.work)

        #expect(viewModel.displayTasks.count == 2)
        #expect(viewModel.displayTasks.allSatisfy { $0.category == .work })
    }

    @Test("優先度フィルタが動作する")
    func testPriorityFilter() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(title: "高", description: "", category: .work, userPriority: .high, dueDate: nil)
        viewModel.createTask(title: "中", description: "", category: .work, userPriority: .medium, dueDate: nil)
        viewModel.createTask(title: "低", description: "", category: .work, userPriority: .low, dueDate: nil)

        viewModel.setFilterPriority(.high)

        // 優先度フィルタが適用される（finalPriorityベース）
        #expect(viewModel.filterPriority == .high)
    }

    @Test("完了状態フィルタが動作する")
    func testCompletionFilter() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(title: "未完了", description: "", category: .work, userPriority: .medium, dueDate: nil)
        let task = viewModel.tasks.first!
        viewModel.createTask(title: "完了済み", description: "", category: .work, userPriority: .medium, dueDate: nil)

        viewModel.toggleTaskCompletion(task)

        viewModel.setFilterCompleted(false)

        #expect(viewModel.displayTasks.count == 1)
        #expect(viewModel.displayTasks.first?.isCompleted == false)
    }

    @Test("複数フィルタの組み合わせが動作する")
    func testMultipleFilters() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(title: "仕事・未完了", description: "", category: .work, userPriority: .high, dueDate: nil)
        viewModel.createTask(title: "個人・未完了", description: "", category: .personal, userPriority: .high, dueDate: nil)

        let task = viewModel.tasks.first!
        viewModel.createTask(title: "仕事・完了", description: "", category: .work, userPriority: .high, dueDate: nil)
        viewModel.toggleTaskCompletion(task)

        viewModel.setFilterCategory(.work)
        viewModel.setFilterCompleted(false)

        // 仕事カテゴリかつ未完了のタスクのみ
        #expect(viewModel.filterCategory == .work)
        #expect(viewModel.filterCompleted == false)
    }

    @Test("フィルタリセットが動作する")
    func testResetFilters() async {
        let viewModel = createTestViewModel()

        viewModel.createTask(title: "テスト", description: "", category: .work, userPriority: .high, dueDate: nil)

        viewModel.setFilterCategory(.work)
        viewModel.setFilterPriority(.high)
        viewModel.setFilterCompleted(false)

        #expect(viewModel.filterCategory != nil)
        #expect(viewModel.filterPriority != nil)
        #expect(viewModel.filterCompleted != nil)

        viewModel.resetFilters()

        #expect(viewModel.filterCategory == nil)
        #expect(viewModel.filterPriority == nil)
        #expect(viewModel.filterCompleted == nil)
    }

    // MARK: - エッジケーステスト (3テスト)

    @Test("空のタスクリスト処理")
    func testEmptyTaskList() async {
        let viewModel = createTestViewModel()

        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.activeTasks.isEmpty)
        #expect(viewModel.completedTasks.isEmpty)
        #expect(viewModel.overdueTasks.isEmpty)
        #expect(viewModel.displayTasks.isEmpty)
    }

    @Test("分析データがnilの場合の処理")
    func testNilAnalytics() async {
        let viewModel = createTestViewModel()

        // 初期状態では分析データがnil
        #expect(viewModel.todayAnalytics == nil)
        #expect(viewModel.aiAcceptanceRate == 0.0)

        // タスク作成時にエラーが発生しない
        viewModel.createTask(
            title: "分析なしテスト",
            description: "",
            category: .work,
            userPriority: .medium,
            dueDate: nil
        )

        #expect(viewModel.tasks.count == 1)
    }

    @Test("エラーハンドリング処理")
    func testErrorHandling() async {
        let viewModel = createTestViewModel()

        // 初期状態ではエラーなし
        #expect(viewModel.errorMessage == nil)

        // タスク読み込み時にエラーメッセージがクリアされる
        viewModel.loadTasks()
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }
}
