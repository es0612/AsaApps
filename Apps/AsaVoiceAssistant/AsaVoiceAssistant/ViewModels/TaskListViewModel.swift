//
//  TaskListViewModel.swift
//  AsaVoiceAssistant
//
//  タスクリスト表示用ViewModel
//

import Foundation

/// タスクの並び替え基準
enum TaskSortOption: String, CaseIterable, Identifiable {
    case createdAt = "作成日"
    case dueDate = "期限"
    case priority = "優先度"
    case category = "カテゴリ"

    var id: String { rawValue }
}

/// タスクのフィルター
enum TaskFilter: Equatable, Identifiable {
    case all
    case active
    case completed
    case priority(PriorityLevel)
    case category(TaskCategory)
    case today
    case overdue

    var id: String {
        switch self {
        case .all: return "all"
        case .active: return "active"
        case .completed: return "completed"
        case .priority(let level): return "priority_\(level.rawValue)"
        case .category(let cat): return "category_\(cat.rawValue)"
        case .today: return "today"
        case .overdue: return "overdue"
        }
    }

    var displayName: String {
        switch self {
        case .all: return "すべて"
        case .active: return "未完了"
        case .completed: return "完了済み"
        case .priority(let level): return "\(level.displayName)優先度"
        case .category(let cat): return cat.displayName
        case .today: return "今日"
        case .overdue: return "期限切れ"
        }
    }
}

/// タスクリスト表示用ViewModel
///
/// タスクのフィルタリング、並び替え、検索機能を提供します。
@MainActor
@Observable
final class TaskListViewModel {
    // MARK: - Dependencies

    private let dataService: DataService

    // MARK: - State

    /// すべてのタスク
    private(set) var allTasks: [VoiceTask] = []

    /// 現在のフィルター
    var currentFilter: TaskFilter = .active {
        didSet { applyFilterAndSort() }
    }

    /// 現在の並び替え
    var currentSort: TaskSortOption = .createdAt {
        didSet { applyFilterAndSort() }
    }

    /// 昇順/降順
    var sortAscending: Bool = false {
        didSet { applyFilterAndSort() }
    }

    /// 検索テキスト
    var searchText: String = "" {
        didSet { applyFilterAndSort() }
    }

    /// フィルタリング・並び替え後のタスク
    private(set) var displayTasks: [VoiceTask] = []

    // MARK: - Computed Properties

    /// 未完了タスク数
    var activeTaskCount: Int {
        allTasks.filter { !$0.isCompleted }.count
    }

    /// 完了済みタスク数
    var completedTaskCount: Int {
        allTasks.filter { $0.isCompleted }.count
    }

    /// 今日期限のタスク数
    var todayTaskCount: Int {
        allTasks.filter { $0.isDueToday && !$0.isCompleted }.count
    }

    /// 期限切れタスク数
    var overdueTaskCount: Int {
        allTasks.filter { $0.isOverdue }.count
    }

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
    }

    // MARK: - Public Methods

    /// タスクを読み込み
    func loadTasks() {
        allTasks = dataService.fetchAllTasks()
        applyFilterAndSort()
    }

    /// タスクを読み込み（外部から渡す場合）
    func setTasks(_ tasks: [VoiceTask]) {
        allTasks = tasks
        applyFilterAndSort()
    }

    /// フィルターをリセット
    func resetFilter() {
        currentFilter = .active
        searchText = ""
    }

    // MARK: - Private Methods

    /// フィルターと並び替えを適用
    private func applyFilterAndSort() {
        var filtered = allTasks

        // フィルター適用
        switch currentFilter {
        case .all:
            break
        case .active:
            filtered = filtered.filter { !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        case .priority(let level):
            filtered = filtered.filter { $0.priority == level && !$0.isCompleted }
        case .category(let category):
            filtered = filtered.filter { $0.category == category && !$0.isCompleted }
        case .today:
            filtered = filtered.filter { $0.isDueToday && !$0.isCompleted }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue }
        }

        // 検索適用
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.taskDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // 並び替え適用
        filtered = sortTasks(filtered)

        displayTasks = filtered
    }

    /// タスクを並び替え
    private func sortTasks(_ tasks: [VoiceTask]) -> [VoiceTask] {
        tasks.sorted { task1, task2 in
            let comparison: Bool

            switch currentSort {
            case .createdAt:
                comparison = task1.createdAt > task2.createdAt

            case .dueDate:
                // 期限なしは最後に
                if task1.dueDate == nil && task2.dueDate == nil {
                    comparison = task1.createdAt > task2.createdAt
                } else if task1.dueDate == nil {
                    comparison = false
                } else if task2.dueDate == nil {
                    comparison = true
                } else {
                    comparison = task1.dueDate! < task2.dueDate!
                }

            case .priority:
                let priority1 = priorityOrder(task1.priority)
                let priority2 = priorityOrder(task2.priority)
                if priority1 == priority2 {
                    comparison = task1.createdAt > task2.createdAt
                } else {
                    comparison = priority1 > priority2
                }

            case .category:
                if task1.category.displayName == task2.category.displayName {
                    comparison = task1.createdAt > task2.createdAt
                } else {
                    comparison = task1.category.displayName < task2.category.displayName
                }
            }

            return sortAscending ? !comparison : comparison
        }
    }

    /// 優先度の順序（高→中→低）
    private func priorityOrder(_ priority: PriorityLevel) -> Int {
        switch priority {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
