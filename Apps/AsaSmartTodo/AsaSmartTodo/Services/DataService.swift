//
//  DataService.swift
//  AsaSmartTodo
//
//  SwiftDataラッパーサービス
//  タスクと分析データの永続化を管理
//

import Foundation
import SwiftData

/// Swift Dataを使用したデータ永続化サービス
///
/// タスク、分析データ、ユーザー設定、カスタムカテゴリの
/// CRUD操作を一元管理します。
///
/// ## 管理対象モデル
/// - **SmartTask**: タスクデータ
/// - **TaskAnalytics**: 日別の生産性分析データ
/// - **UserSettings**: AI重み設定と通知設定
/// - **CustomCategory**: ユーザー定義カテゴリ
///
/// ## 使用例
/// ```swift
/// // 本番環境（ディスクに永続化）
/// let dataService = DataService()
///
/// // テスト環境（メモリ内のみ）
/// let testDataService = DataService(inMemory: true)
///
/// // タスク操作
/// let tasks = dataService.fetchAllTasks()
/// dataService.saveTask(newTask)
/// dataService.save() // 変更をコミット
/// ```
///
/// - Note: すべての操作は`@MainActor`で実行され、スレッドセーフです
/// - Warning: `save()`を呼び出さないと変更が永続化されません
@MainActor
final class DataService {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    init(inMemory: Bool = false) {
        do {
            // ModelContainerの作成
            let schema = Schema([
                SmartTask.self,
                TaskAnalytics.self,
                UserSettings.self,
                CustomCategory.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            modelContext = modelContainer.mainContext
        } catch {
            fatalError("SwiftDataの初期化に失敗しました: \(error)")
        }
    }

    // MARK: - タスク操作

    /// すべてのタスクを取得
    func fetchAllTasks() -> [SmartTask] {
        let descriptor = FetchDescriptor<SmartTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("タスクの取得に失敗: \(error)")
            return []
        }
    }

    /// 条件付きでタスクを取得
    func fetchTasks(
        isCompleted: Bool? = nil,
        category: TaskCategory? = nil,
        priority: PriorityLevel? = nil
    ) -> [SmartTask] {
        var predicate: Predicate<SmartTask>?

        // 完了状態でフィルタ
        if let isCompleted = isCompleted {
            predicate = #Predicate<SmartTask> { task in
                task.isCompleted == isCompleted
            }
        }

        // カテゴリでフィルタ（Raw Valueで比較）
        if let category = category {
            let categoryRaw = category.rawValue
            let categoryPredicate = #Predicate<SmartTask> { task in
                task.categoryRawValue == categoryRaw
            }

            predicate = predicate == nil ? categoryPredicate : predicate
        }

        let descriptor = FetchDescriptor<SmartTask>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("タスクの取得に失敗: \(error)")
            return []
        }
    }

    /// タスクを保存
    func saveTask(_ task: SmartTask) {
        modelContext.insert(task)

        do {
            try modelContext.save()
        } catch {
            print("タスクの保存に失敗: \(error)")
        }
    }

    /// タスクを削除
    func deleteTask(_ task: SmartTask) {
        modelContext.delete(task)

        do {
            try modelContext.save()
        } catch {
            print("タスクの削除に失敗: \(error)")
        }
    }

    /// 変更を保存
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("変更の保存に失敗: \(error)")
        }
    }

    // MARK: - 分析データ操作

    /// 今日の分析データを取得または作成
    func getTodayAnalytics() -> TaskAnalytics {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 今日の分析データを検索
        let descriptor = FetchDescriptor<TaskAnalytics>(
            predicate: #Predicate<TaskAnalytics> { analytics in
                analytics.date == today
            }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            if let existing = results.first {
                return existing
            }
        } catch {
            print("分析データの取得に失敗: \(error)")
        }

        // 存在しない場合は新規作成
        let newAnalytics = TaskAnalytics(date: today)
        modelContext.insert(newAnalytics)

        do {
            try modelContext.save()
        } catch {
            print("分析データの保存に失敗: \(error)")
        }

        return newAnalytics
    }

    /// 指定日の分析データを取得
    func getAnalytics(for date: Date) -> TaskAnalytics? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        let descriptor = FetchDescriptor<TaskAnalytics>(
            predicate: #Predicate<TaskAnalytics> { analytics in
                analytics.date == targetDate
            }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("分析データの取得に失敗: \(error)")
            return nil
        }
    }

    /// 期間内の分析データを取得
    func getAnalytics(from startDate: Date, to endDate: Date) -> [TaskAnalytics] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        let descriptor = FetchDescriptor<TaskAnalytics>(
            predicate: #Predicate<TaskAnalytics> { analytics in
                analytics.date >= start && analytics.date <= end
            },
            sortBy: [SortDescriptor(\.date)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("分析データの取得に失敗: \(error)")
            return []
        }
    }

    // MARK: - 設定操作

    /// ユーザー設定を取得（存在しない場合はnil）
    func getUserSettings() -> UserSettings? {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("設定の取得に失敗: \(error)")
            return nil
        }
    }

    /// ユーザー設定を保存
    func saveUserSettings(_ settings: UserSettings) {
        modelContext.insert(settings)

        do {
            try modelContext.save()
        } catch {
            print("設定の保存に失敗: \(error)")
        }
    }

    /// ユーザー設定を更新
    func updateUserSettings(_ settings: UserSettings) {
        do {
            try modelContext.save()
        } catch {
            print("設定の更新に失敗: \(error)")
        }
    }

    // MARK: - カスタムカテゴリ操作

    /// すべてのカスタムカテゴリを取得
    func getCustomCategories() -> [CustomCategory] {
        let descriptor = FetchDescriptor<CustomCategory>(
            sortBy: [SortDescriptor(\.createdAt)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("カスタムカテゴリの取得に失敗: \(error)")
            return []
        }
    }

    /// カスタムカテゴリを保存
    func saveCustomCategory(_ category: CustomCategory) {
        modelContext.insert(category)

        do {
            try modelContext.save()
        } catch {
            print("カスタムカテゴリの保存に失敗: \(error)")
        }
    }

    /// カスタムカテゴリを更新
    func updateCustomCategory(_ category: CustomCategory) {
        do {
            try modelContext.save()
        } catch {
            print("カスタムカテゴリの更新に失敗: \(error)")
        }
    }

    /// カスタムカテゴリを削除
    func deleteCustomCategory(_ category: CustomCategory) {
        modelContext.delete(category)

        do {
            try modelContext.save()
        } catch {
            print("カスタムカテゴリの削除に失敗: \(error)")
        }
    }
}
