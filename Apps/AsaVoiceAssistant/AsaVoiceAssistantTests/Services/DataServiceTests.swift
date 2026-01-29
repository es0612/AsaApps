//
//  DataServiceTests.swift
//  AsaVoiceAssistantTests
//
//  DataServiceのテスト
//

import Testing
import Foundation
@testable import AsaVoiceAssistant

/// DataServiceのテストスイート
@MainActor
struct DataServiceTests {
    // MARK: - Setup

    /// テスト用のDataServiceを作成（インメモリ）
    func makeDataService() -> DataService {
        DataService(inMemory: true)
    }

    // MARK: - Task CRUD Tests

    @Test("タスク保存 - saveTaskでタスクが保存される")
    func testSaveTask() async {
        let dataService = makeDataService()
        let task = VoiceTask(title: "テストタスク", priority: .high, category: .work)

        dataService.saveTask(task)

        let tasks = dataService.fetchAllTasks()
        #expect(tasks.count == 1)
        #expect(tasks.first?.title == "テストタスク")
    }

    @Test("タスク取得 - fetchAllTasksで全タスクを取得")
    func testFetchAllTasks() async {
        let dataService = makeDataService()

        dataService.saveTask(VoiceTask(title: "タスク1"))
        dataService.saveTask(VoiceTask(title: "タスク2"))
        dataService.saveTask(VoiceTask(title: "タスク3"))

        let tasks = dataService.fetchAllTasks()
        #expect(tasks.count == 3)
    }

    @Test("未完了タスク取得 - fetchActiveTasksで未完了タスクのみ取得")
    func testFetchActiveTasks() async {
        let dataService = makeDataService()

        let activeTask = VoiceTask(title: "未完了")
        let completedTask = VoiceTask(title: "完了済み")
        completedTask.complete()

        dataService.saveTask(activeTask)
        dataService.saveTask(completedTask)

        let activeTasks = dataService.fetchActiveTasks()
        #expect(activeTasks.count == 1)
        #expect(activeTasks.first?.title == "未完了")
    }

    @Test("完了済みタスク取得 - fetchCompletedTasksで完了済みタスクのみ取得")
    func testFetchCompletedTasks() async {
        let dataService = makeDataService()

        let activeTask = VoiceTask(title: "未完了")
        let completedTask = VoiceTask(title: "完了済み")
        completedTask.complete()

        dataService.saveTask(activeTask)
        dataService.saveTask(completedTask)

        let completedTasks = dataService.fetchCompletedTasks()
        #expect(completedTasks.count == 1)
        #expect(completedTasks.first?.title == "完了済み")
    }

    @Test("タスク削除 - deleteTaskでタスクが削除される")
    func testDeleteTask() async {
        let dataService = makeDataService()
        let task = VoiceTask(title: "削除対象")

        dataService.saveTask(task)
        #expect(dataService.fetchAllTasks().count == 1)

        dataService.deleteTask(task)
        #expect(dataService.fetchAllTasks().isEmpty)
    }

    // MARK: - Filter Tests

    @Test("優先度フィルター - fetchTasks(priority:)で優先度別にフィルタリング")
    func testFetchTasksByPriority() async {
        let dataService = makeDataService()

        dataService.saveTask(VoiceTask(title: "高優先度", priority: .high))
        dataService.saveTask(VoiceTask(title: "中優先度", priority: .medium))
        dataService.saveTask(VoiceTask(title: "低優先度", priority: .low))

        let highTasks = dataService.fetchTasks(priority: .high)
        #expect(highTasks.count == 1)
        #expect(highTasks.first?.title == "高優先度")
    }

    @Test("カテゴリフィルター - fetchTasks(category:)でカテゴリ別にフィルタリング")
    func testFetchTasksByCategory() async {
        let dataService = makeDataService()

        dataService.saveTask(VoiceTask(title: "仕事タスク", category: .work))
        dataService.saveTask(VoiceTask(title: "個人タスク", category: .personal))
        dataService.saveTask(VoiceTask(title: "買い物タスク", category: .shopping))

        let workTasks = dataService.fetchTasks(category: .work)
        #expect(workTasks.count == 1)
        #expect(workTasks.first?.title == "仕事タスク")
    }

    @Test("タスク検索 - searchTasksでタイトルを検索")
    func testSearchTasks() async {
        let dataService = makeDataService()

        dataService.saveTask(VoiceTask(title: "報告書を作成"))
        dataService.saveTask(VoiceTask(title: "資料を準備"))
        dataService.saveTask(VoiceTask(title: "報告書を提出"))

        let results = dataService.searchTasks(query: "報告書")
        #expect(results.count == 2)
    }

    // MARK: - Settings Tests

    @Test("設定取得 - getSettingsで設定を取得（存在しない場合は新規作成）")
    func testGetSettings() async {
        let dataService = makeDataService()

        let settings = dataService.getSettings()

        #expect(settings.enableVoiceFeedback == true)  // デフォルト値
        #expect(settings.speechRate == 0.5)  // デフォルト値
    }

    @Test("設定更新 - updateSettingsで設定が更新される")
    func testUpdateSettings() async {
        let dataService = makeDataService()

        let settings = dataService.getSettings()
        settings.enableVoiceFeedback = false
        settings.speechRate = 0.8

        dataService.updateSettings(settings)

        let updatedSettings = dataService.getSettings()
        #expect(updatedSettings.enableVoiceFeedback == false)
        #expect(updatedSettings.speechRate == 0.8)
    }

    // MARK: - Cleanup Tests

    @Test("完了済みタスク一括削除 - deleteCompletedTasksで完了済みタスクのみ削除")
    func testDeleteCompletedTasks() async {
        let dataService = makeDataService()

        let activeTask = VoiceTask(title: "未完了")
        let completed1 = VoiceTask(title: "完了1")
        let completed2 = VoiceTask(title: "完了2")

        completed1.complete()
        completed2.complete()

        dataService.saveTask(activeTask)
        dataService.saveTask(completed1)
        dataService.saveTask(completed2)

        #expect(dataService.fetchAllTasks().count == 3)

        dataService.deleteCompletedTasks()

        let remaining = dataService.fetchAllTasks()
        #expect(remaining.count == 1)
        #expect(remaining.first?.title == "未完了")
    }
}
