//
//  TaskListViewModelTests.swift
//  AsaVoiceAssistantTests
//
//  TaskListViewModelのテスト
//

import Testing
import Foundation
@testable import AsaVoiceAssistant

/// TaskListViewModelのテストスイート
@MainActor
struct TaskListViewModelTests {
    // MARK: - Setup

    func makeViewModel() -> TaskListViewModel {
        let dataService = DataService(inMemory: true)
        return TaskListViewModel(dataService: dataService)
    }

    func createSampleTasks() -> [VoiceTask] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let task1 = VoiceTask(title: "高優先度タスク", priority: .high, category: .work, dueDate: today)
        let task2 = VoiceTask(title: "中優先度タスク", priority: .medium, category: .personal, dueDate: tomorrow)
        let task3 = VoiceTask(title: "低優先度タスク", priority: .low, category: .shopping)
        let task4 = VoiceTask(title: "期限切れタスク", priority: .medium, category: .work, dueDate: yesterday)
        let task5 = VoiceTask(title: "完了済みタスク", priority: .high, category: .work)
        task5.complete()

        return [task1, task2, task3, task4, task5]
    }

    // MARK: - Filter Tests

    @Test("フィルター - 未完了タスクのフィルタリング")
    func testActiveFilter() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())

        viewModel.currentFilter = .active

        #expect(viewModel.displayTasks.count == 4)
        #expect(viewModel.displayTasks.allSatisfy { !$0.isCompleted })
    }

    @Test("フィルター - 完了済みタスクのフィルタリング")
    func testCompletedFilter() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())

        viewModel.currentFilter = .completed

        #expect(viewModel.displayTasks.count == 1)
        #expect(viewModel.displayTasks.allSatisfy { $0.isCompleted })
    }

    @Test("フィルター - 今日期限のタスクのフィルタリング")
    func testTodayFilter() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())

        viewModel.currentFilter = .today

        #expect(viewModel.displayTasks.count == 1)
        #expect(viewModel.displayTasks.first?.title == "高優先度タスク")
    }

    @Test("フィルター - 期限切れタスクのフィルタリング")
    func testOverdueFilter() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())

        viewModel.currentFilter = .overdue

        #expect(viewModel.displayTasks.count == 1)
        #expect(viewModel.displayTasks.first?.title == "期限切れタスク")
    }

    @Test("フィルター - 優先度別フィルタリング")
    func testPriorityFilter() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())

        viewModel.currentFilter = .priority(.high)

        // 完了済みは除外されるので1件
        #expect(viewModel.displayTasks.count == 1)
        #expect(viewModel.displayTasks.first?.title == "高優先度タスク")
    }

    @Test("フィルター - カテゴリ別フィルタリング")
    func testCategoryFilter() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())

        viewModel.currentFilter = .category(.work)

        // 仕事カテゴリで未完了のもの
        #expect(viewModel.displayTasks.count == 2)
    }

    // MARK: - Search Tests

    @Test("検索 - タイトルで検索")
    func testSearch() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())
        viewModel.currentFilter = .all

        viewModel.searchText = "優先度"

        #expect(viewModel.displayTasks.count == 3)  // 高・中・低優先度
    }

    @Test("検索 - 検索結果なし")
    func testSearchNoResults() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())
        viewModel.currentFilter = .all

        viewModel.searchText = "存在しないタスク"

        #expect(viewModel.displayTasks.isEmpty)
    }

    // MARK: - Sort Tests

    @Test("ソート - 作成日順（デフォルト）")
    func testSortByCreatedAt() async {
        let viewModel = makeViewModel()
        let tasks = createSampleTasks()
        viewModel.setTasks(tasks)
        viewModel.currentFilter = .all

        viewModel.currentSort = .createdAt

        // 作成日が新しい順（デフォルトは降順）
        // 作成順序の最後のものが最初に来る
        #expect(viewModel.displayTasks.first?.title == "完了済みタスク")
    }

    @Test("ソート - 優先度順")
    func testSortByPriority() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())
        viewModel.currentFilter = .all

        viewModel.currentSort = .priority

        // 優先度が高い順
        #expect(viewModel.displayTasks.first?.priority == .high)
    }

    @Test("ソート - 昇順切り替え")
    func testSortAscending() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())
        viewModel.currentFilter = .all

        viewModel.currentSort = .priority
        viewModel.sortAscending = true

        // 優先度が低い順
        #expect(viewModel.displayTasks.first?.priority == .low)
    }

    // MARK: - Computed Properties Tests

    @Test("タスク数カウント - 各種タスク数が正しくカウントされる")
    func testTaskCounts() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())

        #expect(viewModel.activeTaskCount == 4)
        #expect(viewModel.completedTaskCount == 1)
        #expect(viewModel.todayTaskCount == 1)
        #expect(viewModel.overdueTaskCount == 1)
    }

    // MARK: - Reset Tests

    @Test("フィルターリセット - resetFilterでデフォルトに戻る")
    func testResetFilter() async {
        let viewModel = makeViewModel()
        viewModel.setTasks(createSampleTasks())

        viewModel.currentFilter = .completed
        viewModel.searchText = "テスト"

        viewModel.resetFilter()

        #expect(viewModel.currentFilter == .active)
        #expect(viewModel.searchText.isEmpty)
    }
}
