//
//  DataService.swift
//  AsaVoiceAssistant
//
//  Swift Dataを使用したデータ永続化サービス
//

import Foundation
import SwiftData

/// Swift Dataを使用したデータ永続化サービス
///
/// VoiceTaskとVoiceSettingsのCRUD操作を一元管理します。
@MainActor
final class DataService {
    // MARK: - Properties

    let modelContainer: ModelContainer
    let modelContext: ModelContext

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        do {
            let schema = Schema([
                VoiceTask.self,
                VoiceSettings.self
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

    // MARK: - Task CRUD

    /// すべてのタスクを取得
    func fetchAllTasks() -> [VoiceTask] {
        let descriptor = FetchDescriptor<VoiceTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("タスクの取得に失敗: \(error)")
            return []
        }
    }

    /// 未完了タスクを取得
    func fetchActiveTasks() -> [VoiceTask] {
        let descriptor = FetchDescriptor<VoiceTask>(
            predicate: #Predicate<VoiceTask> { task in
                task.isCompleted == false
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("タスクの取得に失敗: \(error)")
            return []
        }
    }

    /// 完了済みタスクを取得
    func fetchCompletedTasks() -> [VoiceTask] {
        let descriptor = FetchDescriptor<VoiceTask>(
            predicate: #Predicate<VoiceTask> { task in
                task.isCompleted == true
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("タスクの取得に失敗: \(error)")
            return []
        }
    }

    /// 今日期限のタスクを取得
    func fetchTodayTasks() -> [VoiceTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<VoiceTask>(
            predicate: #Predicate<VoiceTask> { task in
                task.isCompleted == false &&
                task.dueDate != nil &&
                task.dueDate! >= startOfDay &&
                task.dueDate! < endOfDay
            },
            sortBy: [SortDescriptor(\.dueDate)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("タスクの取得に失敗: \(error)")
            return []
        }
    }

    /// 優先度でフィルタリングしてタスクを取得
    func fetchTasks(priority: PriorityLevel) -> [VoiceTask] {
        let priorityRaw = priority.rawValue

        let descriptor = FetchDescriptor<VoiceTask>(
            predicate: #Predicate<VoiceTask> { task in
                task.isCompleted == false &&
                task.priorityRawValue == priorityRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("タスクの取得に失敗: \(error)")
            return []
        }
    }

    /// カテゴリでフィルタリングしてタスクを取得
    func fetchTasks(category: TaskCategory) -> [VoiceTask] {
        let categoryRaw = category.rawValue

        let descriptor = FetchDescriptor<VoiceTask>(
            predicate: #Predicate<VoiceTask> { task in
                task.isCompleted == false &&
                task.categoryRawValue == categoryRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("タスクの取得に失敗: \(error)")
            return []
        }
    }

    /// タイトルで検索してタスクを取得
    func searchTasks(query: String) -> [VoiceTask] {
        let descriptor = FetchDescriptor<VoiceTask>(
            predicate: #Predicate<VoiceTask> { task in
                task.title.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("タスクの検索に失敗: \(error)")
            return []
        }
    }

    /// タスクを保存
    func saveTask(_ task: VoiceTask) {
        modelContext.insert(task)
        save()
    }

    /// タスクを削除
    func deleteTask(_ task: VoiceTask) {
        modelContext.delete(task)
        save()
    }

    /// 完了済みタスクをすべて削除
    func deleteCompletedTasks() {
        let completedTasks = fetchCompletedTasks()
        for task in completedTasks {
            modelContext.delete(task)
        }
        save()
    }

    // MARK: - Settings

    /// 設定を取得（存在しない場合は新規作成）
    func getSettings() -> VoiceSettings {
        let descriptor = FetchDescriptor<VoiceSettings>()

        do {
            let results = try modelContext.fetch(descriptor)
            if let existing = results.first {
                return existing
            }
        } catch {
            print("設定の取得に失敗: \(error)")
        }

        // 新規作成
        let newSettings = VoiceSettings()
        modelContext.insert(newSettings)
        save()
        return newSettings
    }

    /// 設定を更新
    func updateSettings(_ settings: VoiceSettings) {
        settings.update()
        save()
    }

    // MARK: - Utility

    /// 変更を保存
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("変更の保存に失敗: \(error)")
        }
    }
}
