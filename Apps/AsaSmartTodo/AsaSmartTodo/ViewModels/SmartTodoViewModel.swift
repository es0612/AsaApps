import Foundation
import SwiftUI
import SwiftData
import AsaUIKit

@MainActor
class SmartTodoViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var tasks: [SmartTask] = []
    @Published var filteredTasks: [SmartTask] = []
    @Published var selectedTask: SmartTask?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentFilter: TaskFilter = .all
    @Published var searchText = ""

    // AI関連
    @Published var isPredicting = false
    @Published var lastPredictionResult: PredictionResult?
    @Published var showAIInsights = false

    // UI状態
    @Published var showingAddTask = false
    @Published var showingTaskDetail = false
    @Published var showingAnalytics = false

    // 統計情報
    @Published var todayAnalytics: TaskAnalytics?
    @Published var weeklyReport: WeeklyReport?

    // MARK: - Private Properties

    private var modelContext: ModelContext?
    private var taskPredictor: TaskPriorityPredictor?
    private var analyticsManager: AnalyticsManager?

    // MARK: - Computed Properties

    var todayCompletedCount: Int {
        tasks.filter { task in
            if let completedAt = task.completedAt {
                return Calendar.current.isDateInToday(completedAt)
            }
            return false
        }.count
    }

    var pendingTasksCount: Int {
        tasks.filter { $0.status == .todo }.count
    }

    var overdueTasksCount: Int {
        tasks.filter { $0.isOverdue }.count
    }

    var aiAccuracyRate: Double {
        let acceptedTasks = tasks.filter { $0.feedbackProvided && $0.priorityAccepted }
        let totalFeedback = tasks.filter { $0.feedbackProvided }
        guard !totalFeedback.isEmpty else { return 0 }
        return Double(acceptedTasks.count) / Double(totalFeedback.count)
    }

    // MARK: - Initialization

    init() {
        setupPredictor()
        setupAnalytics()
    }

    // MARK: - Setup Methods

    private func setupPredictor() {
        Task {
            taskPredictor = await TaskPriorityPredictor()
        }
    }

    private func setupAnalytics() {
        analyticsManager = AnalyticsManager()
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadTasks()
        loadTodayAnalytics()
    }

    // MARK: - Data Loading

    func loadTasks() {
        guard let modelContext = modelContext else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<SmartTask>(
                sortBy: [
                    SortDescriptor(\.createdAt, order: .reverse)
                ]
            )
            tasks = try modelContext.fetch(descriptor)
            applyFilter()
        } catch {
            errorMessage = "タスクの読み込みに失敗しました: \(error.localizedDescription)"
        }
    }

    func loadTodayAnalytics() {
        guard let modelContext = modelContext else { return }

        do {
            let today = Calendar.current.startOfDay(for: Date())
            let descriptor = FetchDescriptor<TaskAnalytics>(
                predicate: #Predicate<TaskAnalytics> { analytics in
                    analytics.date >= today
                }
            )

            if let analytics = try modelContext.fetch(descriptor).first {
                todayAnalytics = analytics
            } else {
                // 今日の分析データを作成
                let newAnalytics = TaskAnalytics(date: today)
                modelContext.insert(newAnalytics)
                todayAnalytics = newAnalytics
                try modelContext.save()
            }
        } catch {
            print("Analytics loading error: \(error)")
        }
    }

    // MARK: - Task Management

    func addTask(
        title: String,
        description: String?,
        category: TaskCategory,
        dueDate: Date?
    ) async {
        guard let modelContext = modelContext else { return }

        let newTask = SmartTask(
            title: title,
            description: description,
            category: category,
            dueDate: dueDate
        )

        // AI予測を実行
        if let predictor = taskPredictor {
            isPredicting = true
            defer { isPredicting = false }

            let prediction = await predictor.predictPriority(for: newTask)
            newTask.updatePrediction(prediction)
            lastPredictionResult = prediction
        }

        modelContext.insert(newTask)
        todayAnalytics?.recordTaskCreated()

        do {
            try modelContext.save()
            await MainActor.run {
                tasks.append(newTask)
                applyFilter()
                showAIInsights = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "タスクの追加に失敗しました: \(error.localizedDescription)"
            }
        }
    }

    func updateTask(_ task: SmartTask) async {
        guard let modelContext = modelContext else { return }

        // 再予測を実行
        if let predictor = taskPredictor {
            isPredicting = true
            defer { isPredicting = false }

            let prediction = await predictor.predictPriority(for: task)
            task.updatePrediction(prediction)
        }

        task.updatedAt = Date()

        do {
            try modelContext.save()
            await MainActor.run {
                loadTasks()
            }
        } catch {
            await MainActor.run {
                errorMessage = "タスクの更新に失敗しました: \(error.localizedDescription)"
            }
        }
    }

    func completeTask(_ task: SmartTask) {
        guard let modelContext = modelContext else { return }

        task.complete()
        todayAnalytics?.recordTaskCompleted(task: task)

        do {
            try modelContext.save()
            loadTasks()
        } catch {
            errorMessage = "タスクの完了処理に失敗しました: \(error.localizedDescription)"
        }
    }

    func deleteTask(_ task: SmartTask) {
        guard let modelContext = modelContext else { return }

        modelContext.delete(task)

        do {
            try modelContext.save()
            tasks.removeAll { $0.id == task.id }
            applyFilter()
        } catch {
            errorMessage = "タスクの削除に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - AI Feedback

    func acceptAIPriority(for task: SmartTask) {
        task.provideFeedback(accepted: true)
        todayAnalytics?.recordAIFeedback(accepted: true, confidenceScore: task.confidenceScore)
        saveContext()
    }

    func rejectAIPriority(for task: SmartTask) {
        task.provideFeedback(accepted: false)
        todayAnalytics?.recordAIFeedback(accepted: false, confidenceScore: task.confidenceScore)
        saveContext()
    }

    // MARK: - Filtering and Searching

    func applyFilter() {
        var filtered = tasks

        // フィルタリング
        switch currentFilter {
        case .all:
            break
        case .today:
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue }
        case .highPriority:
            filtered = filtered.filter { $0.userPriority == .high }
        case .aiSuggested:
            filtered = filtered.filter { $0.confidenceScore >= 0.7 }
        case .completed:
            filtered = filtered.filter { $0.status == .done }
        case .pending:
            filtered = filtered.filter { $0.status == .todo || $0.status == .inProgress }
        }

        // 検索
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.taskDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // 優先度でソート
        filtered.sort { first, second in
            if first.userPriority.rawValue != second.userPriority.rawValue {
                return first.userPriority.rawValue < second.userPriority.rawValue
            }
            return first.createdAt > second.createdAt
        }

        filteredTasks = filtered
    }

    func setFilter(_ filter: TaskFilter) {
        currentFilter = filter
        applyFilter()
    }

    // MARK: - Analytics

    func generateWeeklyReport() async {
        guard let modelContext = modelContext else { return }

        do {
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            let descriptor = FetchDescriptor<TaskAnalytics>(
                predicate: #Predicate<TaskAnalytics> { analytics in
                    analytics.date >= oneWeekAgo
                }
            )

            let weeklyAnalytics = try modelContext.fetch(descriptor)
            await MainActor.run {
                weeklyReport = TaskAnalytics.generateWeeklyReport(from: weeklyAnalytics)
                showingAnalytics = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "週次レポートの生成に失敗しました: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helper Methods

    private func saveContext() {
        guard let modelContext = modelContext else { return }

        do {
            try modelContext.save()
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Supporting Types

enum TaskFilter: String, CaseIterable {
    case all = "すべて"
    case today = "今日"
    case overdue = "期限切れ"
    case highPriority = "高優先度"
    case aiSuggested = "AI推奨"
    case completed = "完了済み"
    case pending = "未完了"
}

// Analytics Manager（簡易実装）
class AnalyticsManager {
    func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        // イベントトラッキング実装
        print("Event tracked: \(event)")
    }
}