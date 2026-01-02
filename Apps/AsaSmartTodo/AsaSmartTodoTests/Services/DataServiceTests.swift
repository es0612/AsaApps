//
//  DataServiceTests.swift
//  AsaSmartTodoTests
//
//  DataServiceのテスト
//  SwiftDataの永続化とCRUD操作を検証
//

import Testing
import Foundation
import SwiftData
@testable import AsaSmartTodo

/// DataServiceのテストスイート
@MainActor
struct DataServiceTests {

    // MARK: - Helper Methods

    /// テスト用のin-memory DataServiceを作成
    func createTestDataService() -> DataService {
        return DataService(inMemory: true)
    }

    /// テスト用のSmartTaskを作成
    func createTestTask(
        title: String = "テストタスク",
        category: TaskCategory = .work,
        priority: PriorityLevel = .medium,
        dueDate: Date? = nil
    ) -> SmartTask {
        return SmartTask(
            title: title,
            description: "テスト説明",
            category: category,
            userPriority: priority,
            dueDate: dueDate
        )
    }

    // MARK: - タスクCRUD操作テスト (10テスト)

    @Test("タスク保存が正しく動作する")
    func testSaveTask() async {
        let dataService = createTestDataService()
        let task = createTestTask(title: "新しいタスク")

        dataService.saveTask(task)

        let tasks = dataService.fetchAllTasks()
        #expect(tasks.count == 1)
        #expect(tasks.first?.title == "新しいタスク")
    }

    @Test("複数タスクの保存が正しく動作する")
    func testSaveMultipleTasks() async {
        let dataService = createTestDataService()

        for i in 1...5 {
            let task = createTestTask(title: "タスク\(i)")
            dataService.saveTask(task)
        }

        let tasks = dataService.fetchAllTasks()
        #expect(tasks.count == 5)
    }

    @Test("すべてのタスク取得が正しく動作する")
    func testFetchAllTasks() async {
        let dataService = createTestDataService()

        // 初期状態は空
        let emptyTasks = dataService.fetchAllTasks()
        #expect(emptyTasks.isEmpty)

        // タスクを追加
        let task = createTestTask()
        dataService.saveTask(task)

        // 取得確認
        let tasks = dataService.fetchAllTasks()
        #expect(tasks.count == 1)
    }

    @Test("タスク削除が正しく動作する")
    func testDeleteTask() async {
        let dataService = createTestDataService()
        let task = createTestTask()

        dataService.saveTask(task)
        #expect(dataService.fetchAllTasks().count == 1)

        dataService.deleteTask(task)
        #expect(dataService.fetchAllTasks().isEmpty)
    }

    @Test("タスク更新が正しく動作する")
    func testUpdateTask() async {
        let dataService = createTestDataService()
        let task = createTestTask(title: "元のタイトル")

        dataService.saveTask(task)

        // タスクを更新
        task.updateDetails(title: "更新後のタイトル")
        dataService.save()

        let tasks = dataService.fetchAllTasks()
        #expect(tasks.first?.title == "更新後のタイトル")
    }

    @Test("タスク完了状態の変更が正しく動作する")
    func testToggleTaskCompletion() async {
        let dataService = createTestDataService()
        let task = createTestTask()

        dataService.saveTask(task)

        // 完了状態に変更
        task.complete()
        dataService.save()

        let tasks = dataService.fetchAllTasks()
        #expect(tasks.first?.isCompleted == true)
        #expect(tasks.first?.completedAt != nil)
    }

    @Test("タスクの作成日時でソートされる")
    func testTasksSortedByCreatedAt() async {
        let dataService = createTestDataService()

        // 複数タスクを順番に作成
        for i in 1...3 {
            let task = createTestTask(title: "タスク\(i)")
            dataService.saveTask(task)
            // 少し待機して作成日時を異ならせる
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        let tasks = dataService.fetchAllTasks()
        // 最新のタスクが先頭（逆順）
        #expect(tasks.first?.title == "タスク3")
        #expect(tasks.last?.title == "タスク1")
    }

    @Test("大量のタスクを保存・取得できる")
    func testLargeNumberOfTasks() async {
        let dataService = createTestDataService()

        // 100タスク作成
        for i in 1...100 {
            let task = createTestTask(title: "タスク\(i)")
            dataService.saveTask(task)
        }

        let tasks = dataService.fetchAllTasks()
        #expect(tasks.count == 100)
    }

    @Test("タスクの変更保存が正しく動作する")
    func testSaveChanges() async {
        let dataService = createTestDataService()
        let task = createTestTask()

        dataService.saveTask(task)

        // タスクを変更
        task.updateDetails(description: "更新された説明")
        dataService.save()

        let tasks = dataService.fetchAllTasks()
        #expect(tasks.first?.taskDescription == "更新された説明")
    }

    @Test("タスクのプロパティが正しく永続化される")
    func testTaskPropertiesPersistence() async {
        let dataService = createTestDataService()
        let dueDate = Date().addingTimeInterval(86400) // 1日後
        let task = createTestTask(
            title: "重要なタスク",
            category: .health,
            priority: .high,
            dueDate: dueDate
        )

        dataService.saveTask(task)

        let tasks = dataService.fetchAllTasks()
        let savedTask = tasks.first

        #expect(savedTask?.title == "重要なタスク")
        #expect(savedTask?.category == .health)
        #expect(savedTask?.userPriority == .high)
        #expect(savedTask?.dueDate != nil)
    }

    // MARK: - フィルタ機能テスト (5テスト)

    @Test("完了状態でフィルタできる")
    func testFilterByCompletionStatus() async {
        let dataService = createTestDataService()

        // 完了タスクと未完了タスクを作成
        let completedTask = createTestTask(title: "完了タスク")
        completedTask.complete()
        dataService.saveTask(completedTask)

        let activeTask = createTestTask(title: "未完了タスク")
        dataService.saveTask(activeTask)

        // 完了タスクのみ取得
        let completedTasks = dataService.fetchTasks(isCompleted: true)
        #expect(completedTasks.count == 1)
        #expect(completedTasks.first?.title == "完了タスク")

        // 未完了タスクのみ取得
        let activeTasks = dataService.fetchTasks(isCompleted: false)
        #expect(activeTasks.count == 1)
        #expect(activeTasks.first?.title == "未完了タスク")
    }

    @Test("カテゴリでフィルタできる")
    func testFilterByCategory() async {
        let dataService = createTestDataService()

        // 異なるカテゴリのタスクを作成
        dataService.saveTask(createTestTask(title: "仕事1", category: .work))
        dataService.saveTask(createTestTask(title: "仕事2", category: .work))
        dataService.saveTask(createTestTask(title: "個人", category: .personal))
        dataService.saveTask(createTestTask(title: "健康", category: .health))

        // 仕事カテゴリのみ取得
        let workTasks = dataService.fetchTasks(category: .work)
        #expect(workTasks.count == 2)
        #expect(workTasks.allSatisfy { $0.category == .work })
    }

    @Test("優先度でフィルタできる")
    func testFilterByPriority() async {
        let dataService = createTestDataService()

        // 異なる優先度のタスクを作成
        let highTask = createTestTask(title: "高優先度", priority: .high)
        highTask.applyPrediction(PredictionResult(
            suggestedPriority: .high,
            confidenceScore: 0.9,
            reasons: []
        ))
        dataService.saveTask(highTask)

        let mediumTask = createTestTask(title: "中優先度", priority: .medium)
        mediumTask.applyPrediction(PredictionResult(
            suggestedPriority: .medium,
            confidenceScore: 0.7,
            reasons: []
        ))
        dataService.saveTask(mediumTask)

        // 高優先度のみ取得
        let highPriorityTasks = dataService.fetchTasks(priority: .high)
        #expect(highPriorityTasks.count == 1)
        #expect(highPriorityTasks.first?.finalPriority == .high)
    }

    @Test("複数条件でフィルタできる")
    func testFilterByMultipleConditions() async {
        let dataService = createTestDataService()

        // 様々なタスクを作成
        let task1 = createTestTask(title: "仕事・未完了", category: .work)
        dataService.saveTask(task1)

        let task2 = createTestTask(title: "仕事・完了", category: .work)
        task2.complete()
        dataService.saveTask(task2)

        let task3 = createTestTask(title: "個人・未完了", category: .personal)
        dataService.saveTask(task3)

        // 仕事カテゴリかつ未完了のタスクを取得
        let filteredTasks = dataService.fetchTasks(
            isCompleted: false,
            category: .work
        )

        #expect(filteredTasks.count == 1)
        #expect(filteredTasks.first?.title == "仕事・未完了")
    }

    @Test("フィルタなしで全タスク取得")
    func testFetchTasksWithoutFilter() async {
        let dataService = createTestDataService()

        // 様々なタスクを作成
        dataService.saveTask(createTestTask(title: "タスク1", category: .work))
        dataService.saveTask(createTestTask(title: "タスク2", category: .personal))
        dataService.saveTask(createTestTask(title: "タスク3", category: .health))

        // フィルタなしで取得
        let allTasks = dataService.fetchTasks()
        #expect(allTasks.count == 3)
    }

    // MARK: - UserSettings管理テスト (5テスト)

    @Test("UserSettings取得（存在しない場合）")
    func testGetUserSettingsWhenNotExists() async {
        let dataService = createTestDataService()

        let settings = dataService.getUserSettings()
        #expect(settings == nil)
    }

    @Test("UserSettings保存が正しく動作する")
    func testSaveUserSettings() async {
        let dataService = createTestDataService()
        let settings = UserSettings()
        settings.notificationsEnabled = true
        settings.notificationHour = 9

        dataService.saveUserSettings(settings)

        let savedSettings = dataService.getUserSettings()
        #expect(savedSettings != nil)
        #expect(savedSettings?.notificationsEnabled == true)
        #expect(savedSettings?.notificationHour == 9)
    }

    @Test("UserSettings更新が正しく動作する")
    func testUpdateUserSettings() async {
        let dataService = createTestDataService()
        let settings = UserSettings()
        settings.notificationsEnabled = false

        dataService.saveUserSettings(settings)

        // 設定を更新
        settings.notificationsEnabled = true
        settings.morningReminderEnabled = true
        dataService.updateUserSettings(settings)

        let updatedSettings = dataService.getUserSettings()
        #expect(updatedSettings?.notificationsEnabled == true)
        #expect(updatedSettings?.morningReminderEnabled == true)
    }

    @Test("AI予測重みの保存と取得")
    func testAIPredictionWeights() async {
        let dataService = createTestDataService()
        let settings = UserSettings()

        // カスタム重みを設定
        settings.dueDateWeight = 0.40
        settings.categoryWeight = 0.25
        settings.titleComplexityWeight = 0.15

        dataService.saveUserSettings(settings)

        let savedSettings = dataService.getUserSettings()
        #expect(savedSettings?.dueDateWeight == 0.40)
        #expect(savedSettings?.categoryWeight == 0.25)
        #expect(savedSettings?.titleComplexityWeight == 0.15)
    }

    @Test("通知設定の保存と取得")
    func testNotificationSettings() async {
        let dataService = createTestDataService()
        let settings = UserSettings()

        settings.notificationsEnabled = true
        settings.dueDayReminderEnabled = true
        settings.oneDayBeforeReminderEnabled = true
        settings.morningReminderEnabled = true
        settings.notificationHour = 7
        settings.notificationMinute = 30

        dataService.saveUserSettings(settings)

        let savedSettings = dataService.getUserSettings()
        #expect(savedSettings?.notificationsEnabled == true)
        #expect(savedSettings?.dueDayReminderEnabled == true)
        #expect(savedSettings?.oneDayBeforeReminderEnabled == true)
        #expect(savedSettings?.morningReminderEnabled == true)
        #expect(savedSettings?.notificationHour == 7)
        #expect(savedSettings?.notificationMinute == 30)
    }

    // MARK: - CustomCategory管理テスト (5テスト)

    @Test("CustomCategory保存が正しく動作する")
    func testSaveCustomCategory() async {
        let dataService = createTestDataService()
        let category = CustomCategory(
            name: "副業",
            icon: "briefcase.fill",
            colorHex: "#FF5733"
        )

        dataService.saveCustomCategory(category)

        let categories = dataService.getCustomCategories()
        #expect(categories.count == 1)
        #expect(categories.first?.name == "副業")
    }

    @Test("複数CustomCategoryの保存と取得")
    func testSaveMultipleCustomCategories() async {
        let dataService = createTestDataService()

        let category1 = CustomCategory(name: "副業", icon: "briefcase.fill", colorHex: "#FF5733")
        let category2 = CustomCategory(name: "趣味", icon: "paintbrush.fill", colorHex: "#33FF57")
        let category3 = CustomCategory(name: "家事", icon: "house.fill", colorHex: "#3357FF")

        dataService.saveCustomCategory(category1)
        dataService.saveCustomCategory(category2)
        dataService.saveCustomCategory(category3)

        let categories = dataService.getCustomCategories()
        #expect(categories.count == 3)
    }

    @Test("CustomCategory更新が正しく動作する")
    func testUpdateCustomCategory() async {
        let dataService = createTestDataService()
        let category = CustomCategory(name: "副業", icon: "briefcase.fill", colorHex: "#FF5733")

        dataService.saveCustomCategory(category)

        // カテゴリを更新
        category.name = "フリーランス"
        category.icon = "person.fill"
        dataService.updateCustomCategory(category)

        let categories = dataService.getCustomCategories()
        #expect(categories.first?.name == "フリーランス")
        #expect(categories.first?.icon == "person.fill")
    }

    @Test("CustomCategory削除が正しく動作する")
    func testDeleteCustomCategory() async {
        let dataService = createTestDataService()
        let category = CustomCategory(name: "副業", icon: "briefcase.fill", colorHex: "#FF5733")

        dataService.saveCustomCategory(category)
        #expect(dataService.getCustomCategories().count == 1)

        dataService.deleteCustomCategory(category)
        #expect(dataService.getCustomCategories().isEmpty)
    }

    @Test("CustomCategoryが作成日時でソートされる")
    func testCustomCategoriesSortedByCreatedAt() async {
        let dataService = createTestDataService()

        // 複数カテゴリを順番に作成
        for i in 1...3 {
            let category = CustomCategory(
                name: "カテゴリ\(i)",
                icon: "star.fill",
                colorHex: "#FF5733"
            )
            dataService.saveCustomCategory(category)
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        let categories = dataService.getCustomCategories()
        // 古い順にソート
        #expect(categories.first?.name == "カテゴリ1")
        #expect(categories.last?.name == "カテゴリ3")
    }
}
