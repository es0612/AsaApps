//
//  SmartTodoViewModel.swift
//  AsaSmartTodo
//
//  メインViewModel
//  タスク管理、AI予測、分析データの統括
//

import Foundation
import SwiftUI

/// AsaSmartTodoアプリのメインViewModel
///
/// タスク管理、AI優先度予測、分析データの統括を担当します。
/// SwiftUIの`@Observable`マクロを使用した状態管理を実装しています。
///
/// ## 主要機能
/// - **タスクCRUD**: タスクの作成、読み込み、更新、削除
/// - **AI優先度予測**: `TaskPriorityPredictor`を使用した自動優先度提案
/// - **フィルタリング**: カテゴリ、優先度、完了状態によるタスクフィルタ
/// - **分析データ統合**: 今日のタスク作成・完了の記録
/// - **通知管理**: 期限前通知のスケジューリング
///
/// ## 使用例
/// ```swift
/// let viewModel = SmartTodoViewModel(dataService: DataService())
/// viewModel.loadTasks()
/// viewModel.createTask(
///     title: "重要な会議の準備",
///     description: "プレゼン資料を完成させる",
///     category: .work,
///     userPriority: .medium,
///     dueDate: Date().addingTimeInterval(86400)
/// )
/// ```
///
/// - Note: このクラスは`@MainActor`でマークされており、すべてのメソッドはメインスレッドで実行されます
/// - Warning: `DataService`は必須の依存関係です。`inMemory: true`でテスト用のインスタンスを作成できます
@MainActor
@Observable
final class SmartTodoViewModel {
    // MARK: - Dependencies

    private let dataService: DataService
    private let predictor: EnhancedPriorityPredictor
    private let notificationService: NotificationService

    // MARK: - State

    private(set) var tasks: [SmartTask] = []
    private(set) var todayAnalytics: TaskAnalytics?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - UI State

    var showingAddTask = false
    var selectedTask: SmartTask?
    var filterCategory: TaskCategory?
    var filterPriority: PriorityLevel?
    var filterCompleted: Bool?

    // MARK: - Computed Properties

    /// アクティブなタスク（未完了）
    var activeTasks: [SmartTask] {
        tasks.filter { !$0.isCompleted }
    }

    /// 完了済みタスク
    var completedTasks: [SmartTask] {
        tasks.filter { $0.isCompleted }
    }

    /// 期限切れタスク
    var overdueTasks: [SmartTask] {
        tasks.filter { $0.isOverdue }
    }

    /// 表示するタスク（フィルタ適用後）
    var displayTasks: [SmartTask] {
        var filtered = tasks

        if let completed = filterCompleted {
            filtered = filtered.filter { $0.isCompleted == completed }
        }

        if let category = filterCategory {
            filtered = filtered.filter { $0.category == category }
        }

        if let priority = filterPriority {
            filtered = filtered.filter { $0.finalPriority == priority }
        }

        return filtered
    }

    /// AI予測精度（採用率）
    var aiAcceptanceRate: Double {
        guard let analytics = todayAnalytics else { return 0.0 }
        return analytics.aiAcceptanceRate
    }

    // MARK: - Initializer

    init(dataService: DataService) {
        self.dataService = dataService
        self.predictor = EnhancedPriorityPredictor()
        self.notificationService = NotificationService.shared
    }

    // MARK: - Data Loading

    /// タスクを読み込み
    func loadTasks() {
        isLoading = true
        errorMessage = nil

        tasks = dataService.fetchAllTasks()
        todayAnalytics = dataService.getTodayAnalytics()

        isLoading = false
    }

    /// フィルタ付きでタスクを読み込み
    func loadFilteredTasks() {
        isLoading = true

        tasks = dataService.fetchTasks(
            isCompleted: filterCompleted,
            category: filterCategory,
            priority: filterPriority
        )

        isLoading = false
    }

    // MARK: - Task CRUD

    /// 新しいタスクを作成し、AI優先度予測を実行します
    ///
    /// タスク作成時に以下の処理を自動実行します：
    /// - ハイブリッドAI優先度予測の実行と適用（iOS 18ではLLM統合、iOS 17以下はルールベースのみ）
    /// - 分析データへのタスク作成記録
    /// - 期限通知のスケジューリング
    ///
    /// - Parameters:
    ///   - title: タスクのタイトル（必須）
    ///   - description: タスクの詳細説明（オプション）
    ///   - category: タスクのカテゴリ（work, personal, family等）
    ///   - userPriority: ユーザーが指定する優先度
    ///   - dueDate: タスクの期限（オプション）
    ///
    /// - Note: AI予測は`EnhancedPriorityPredictor`によりハイブリッド分析（ルールベース40% + LLM60%）で実行されます
    func createTask(
        title: String,
        description: String?,
        category: TaskCategory,
        userPriority: PriorityLevel,
        dueDate: Date?
    ) {
        let task = SmartTask(
            title: title,
            description: description,
            category: category,
            userPriority: userPriority,
            dueDate: dueDate
        )

        // AI予測を非同期実行（LLM分析は300-500ms）
        Task {
            let enhancedPrediction = await predictor.predictPriority(for: task)

            // EnhancedPredictionResultをPredictionResultに変換
            let prediction = PredictionResult(
                suggestedPriority: enhancedPrediction.suggestedPriority,
                confidenceScore: enhancedPrediction.confidenceScore,
                reasons: enhancedPrediction.reasons
            )

            task.applyPrediction(prediction)

            // タスクを保存
            dataService.saveTask(task)

            // 分析データを更新
            if let analytics = todayAnalytics {
                let hour = Calendar.current.component(.hour, from: Date())
                analytics.recordTaskCreation(at: hour, category: category)
                dataService.save()
            }

            // 通知をスケジュール
            if let settings = dataService.getUserSettings(), task.dueDate != nil {
                await notificationService.scheduleTaskNotification(for: task, settings: settings)
            }

            // リストを再読み込み
            loadTasks()
        }
    }

    /// タスクを更新
    func updateTask(
        _ task: SmartTask,
        title: String? = nil,
        description: String? = nil,
        category: TaskCategory? = nil,
        userPriority: PriorityLevel? = nil,
        dueDate: Date? = nil
    ) {
        task.updateDetails(
            title: title,
            description: description,
            category: category,
            userPriority: userPriority,
            dueDate: dueDate
        )

        // 優先度が変更された場合、AI予測を再実行（非同期）
        if userPriority != nil {
            Task {
                let enhancedPrediction = await predictor.predictPriority(for: task)
                let prediction = PredictionResult(
                    suggestedPriority: enhancedPrediction.suggestedPriority,
                    confidenceScore: enhancedPrediction.confidenceScore,
                    reasons: enhancedPrediction.reasons
                )
                task.applyPrediction(prediction)
                dataService.save()
            }
        } else {
            dataService.save()
        }

        // 期限が変更された場合、通知を再スケジュール
        if dueDate != nil, let settings = dataService.getUserSettings() {
            Task {
                await notificationService.scheduleTaskNotification(for: task, settings: settings)
            }
        }

        loadTasks()
    }

    /// タスクを削除
    func deleteTask(_ task: SmartTask) {
        // 通知をキャンセル
        Task {
            await notificationService.cancelNotification(for: task.id)
        }

        dataService.deleteTask(task)
        loadTasks()
    }

    /// タスクの完了状態を切り替え
    func toggleTaskCompletion(_ task: SmartTask) {
        if task.isCompleted {
            task.uncomplete()
        } else {
            task.complete()

            // 完了時に分析データを更新
            if let analytics = todayAnalytics {
                let hour = Calendar.current.component(.hour, from: Date())
                analytics.recordTaskCompletion(at: hour, category: task.category)
                dataService.save()
            }
        }

        dataService.save()
        loadTasks()
    }

    // MARK: - AI Prediction

    /// タスクのAI予測を再実行して結果を取得
    ///
    /// AI分析詳細画面で表示するために、ハイブリッドAI予測を実行します。
    ///
    /// - Parameter task: 分析対象のSmartTask
    /// - Returns: EnhancedPredictionResult（ハイブリッド予測結果）
    func getEnhancedPrediction(for task: SmartTask) async -> EnhancedPredictionResult {
        return await predictor.predictPriority(for: task)
    }

    /// AI予測を採用
    func acceptAIPrediction(for task: SmartTask) {
        task.acceptAIPrediction()

        // 分析データにフィードバックを記録
        if let analytics = todayAnalytics {
            analytics.recordAIFeedback(accepted: true, confidenceScore: task.confidenceScore)
            dataService.save()
        }

        dataService.save()
        loadTasks()
    }

    /// AI予測を却下
    func rejectAIPrediction(for task: SmartTask) {
        task.rejectAIPrediction()

        // 分析データにフィードバックを記録
        if let analytics = todayAnalytics {
            analytics.recordAIFeedback(accepted: false, confidenceScore: task.confidenceScore)
            dataService.save()
        }

        dataService.save()
        loadTasks()
    }

    // MARK: - Filters

    /// フィルタをリセット
    func resetFilters() {
        filterCategory = nil
        filterPriority = nil
        filterCompleted = nil
        loadTasks()
    }

    /// カテゴリフィルタを設定
    func setFilterCategory(_ category: TaskCategory?) {
        filterCategory = category
        loadFilteredTasks()
    }

    /// 優先度フィルタを設定
    func setFilterPriority(_ priority: PriorityLevel?) {
        filterPriority = priority
        loadFilteredTasks()
    }

    /// 完了状態フィルタを設定
    func setFilterCompleted(_ completed: Bool?) {
        filterCompleted = completed
        loadFilteredTasks()
    }
}
