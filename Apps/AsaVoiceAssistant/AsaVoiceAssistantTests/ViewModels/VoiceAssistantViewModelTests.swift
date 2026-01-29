//
//  VoiceAssistantViewModelTests.swift
//  AsaVoiceAssistantTests
//
//  VoiceAssistantViewModelのテスト
//

import Testing
import Foundation
@testable import AsaVoiceAssistant

/// VoiceAssistantViewModelのテストスイート
@MainActor
struct VoiceAssistantViewModelTests {
    // MARK: - Setup

    /// テスト用のViewModelを作成
    func makeViewModel() -> VoiceAssistantViewModel {
        let dataService = DataService(inMemory: true)
        return VoiceAssistantViewModel(dataService: dataService)
    }

    // MARK: - Initialization Tests

    @Test("初期化 - 初期状態が正しく設定される")
    func testInitialState() async {
        let viewModel = makeViewModel()

        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Task Management Tests

    @Test("タスク追加 - 手動でタスクを追加できる")
    func testAddTask() async {
        let viewModel = makeViewModel()

        viewModel.addTask(
            title: "テストタスク",
            priority: .high,
            category: .work,
            dueDate: nil
        )

        #expect(viewModel.tasks.count == 1)
        #expect(viewModel.tasks.first?.title == "テストタスク")
        #expect(viewModel.tasks.first?.priority == .high)
        #expect(viewModel.tasks.first?.category == .work)
    }

    @Test("タスク完了切り替え - toggleTaskCompletionで完了状態が切り替わる")
    func testToggleTaskCompletion() async {
        let viewModel = makeViewModel()

        viewModel.addTask(title: "テスト", priority: .medium, category: .personal, dueDate: nil)
        let task = viewModel.tasks.first!

        #expect(task.isCompleted == false)

        viewModel.toggleTaskCompletion(task)

        #expect(task.isCompleted == true)

        viewModel.toggleTaskCompletion(task)

        #expect(task.isCompleted == false)
    }

    @Test("タスク削除 - deleteTaskでタスクが削除される")
    func testDeleteTask() async {
        let viewModel = makeViewModel()

        viewModel.addTask(title: "削除対象", priority: .low, category: .other, dueDate: nil)

        #expect(viewModel.tasks.count == 1)

        let task = viewModel.tasks.first!
        viewModel.deleteTask(task)

        #expect(viewModel.tasks.isEmpty)
    }

    @Test("完了済みタスク全削除 - deleteAllCompletedTasksで完了済みタスクのみ削除")
    func testDeleteAllCompletedTasks() async {
        let viewModel = makeViewModel()

        viewModel.addTask(title: "未完了タスク", priority: .medium, category: .work, dueDate: nil)
        viewModel.addTask(title: "完了タスク", priority: .medium, category: .work, dueDate: nil)

        let completedTask = viewModel.tasks.last!
        completedTask.complete()

        viewModel.loadTasks()

        #expect(viewModel.tasks.count == 2)
        #expect(viewModel.completedTasks.count == 1)

        viewModel.deleteAllCompletedTasks()

        #expect(viewModel.tasks.count == 1)
        #expect(viewModel.tasks.first?.title == "未完了タスク")
    }

    // MARK: - Computed Properties Tests

    @Test("未完了タスク - activeTasksが正しくフィルタリングされる")
    func testActiveTasks() async {
        let viewModel = makeViewModel()

        viewModel.addTask(title: "未完了1", priority: .high, category: .work, dueDate: nil)
        viewModel.addTask(title: "未完了2", priority: .medium, category: .personal, dueDate: nil)
        viewModel.addTask(title: "完了済み", priority: .low, category: .other, dueDate: nil)

        viewModel.tasks.last!.complete()
        viewModel.loadTasks()

        #expect(viewModel.activeTasks.count == 2)
        #expect(viewModel.completedTasks.count == 1)
    }

    @Test("今日期限タスク - todayTasksが正しくフィルタリングされる")
    func testTodayTasks() async {
        let viewModel = makeViewModel()

        viewModel.addTask(title: "今日のタスク", priority: .high, category: .work, dueDate: Date())
        viewModel.addTask(title: "明日のタスク", priority: .medium, category: .work, dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()))
        viewModel.addTask(title: "期限なし", priority: .low, category: .work, dueDate: nil)

        #expect(viewModel.todayTasks.count == 1)
        #expect(viewModel.todayTasks.first?.title == "今日のタスク")
    }

    @Test("期限切れタスク - overdueTasksが正しくフィルタリングされる")
    func testOverdueTasks() async {
        let viewModel = makeViewModel()

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        viewModel.addTask(title: "期限切れ", priority: .high, category: .work, dueDate: yesterday)
        viewModel.addTask(title: "明日まで", priority: .medium, category: .work, dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        #expect(viewModel.overdueTasks.count == 1)
        #expect(viewModel.overdueTasks.first?.title == "期限切れ")
    }

    // MARK: - Command Execution Tests

    @Test("コマンド実行 - createTaskコマンドでタスクが作成される")
    func testExecuteCreateTaskCommand() async {
        let viewModel = makeViewModel()

        let command = VoiceCommand(
            intent: .createTask,
            taskTitle: "音声で作成したタスク",
            priority: .high,
            category: .work,
            dueDate: Date(),
            rawTranscription: "音声で作成したタスクを追加",
            confidence: 0.9
        )

        viewModel.executeCommand(command)

        // 少し待機（非同期処理のため）
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.tasks.count == 1)
        #expect(viewModel.tasks.first?.title == "音声で作成したタスク")
        #expect(viewModel.tasks.first?.createdByVoice == true)
    }

    // MARK: - Settings Tests

    @Test("設定 - skipConfirmationが設定に連動する")
    func testSkipConfirmation() async {
        let viewModel = makeViewModel()

        // デフォルトは確認ダイアログあり
        #expect(viewModel.skipConfirmation == false)

        viewModel.settings.showCommandConfirmation = false
        viewModel.updateSettings()

        #expect(viewModel.skipConfirmation == true)
    }
}
