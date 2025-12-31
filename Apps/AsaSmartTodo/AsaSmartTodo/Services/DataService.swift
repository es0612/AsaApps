//
//  DataService.swift
//  AsaSmartTodo
//
//  SwiftDataラッパーサービス
//  タスクと分析データの永続化を管理
//

import Foundation
import SwiftData

/// SwiftDataの永続化を管理するサービス
@MainActor
final class DataService {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    init() {
        do {
            // ModelContainerの作成
            let schema = Schema([
                SmartTask.self,
                TaskAnalytics.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
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
}
