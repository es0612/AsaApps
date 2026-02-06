import Foundation
import SwiftData

// MARK: - データサービス

/// SwiftDataベースのCRUD操作を提供するサービス
/// テスト時は inMemory: true で分離した環境を使用
@MainActor
public final class ReminderDataService {
    public let modelContainer: ModelContainer
    private let modelContext: ModelContext

    // MARK: - Init

    public init(inMemory: Bool = false) {
        let schema = Schema([
            ReminderLocation.self,
            LocationReminder.self,
            UserLocationSettings.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("ModelContainerの初期化に失敗: \(error)")
        }
        modelContext = modelContainer.mainContext
    }

    // MARK: - 場所操作

    /// 全場所を取得（更新日時の降順）
    public func fetchAllLocations() throws -> [ReminderLocation] {
        let descriptor = FetchDescriptor<ReminderLocation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// カテゴリで場所をフィルタ取得
    public func fetchLocations(category: LocationCategory) throws -> [ReminderLocation] {
        let rawValue = category.rawValue
        let descriptor = FetchDescriptor<ReminderLocation>(
            predicate: #Predicate { $0.categoryRawValue == rawValue },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// IDで場所を取得
    public func fetchLocation(id: UUID) throws -> ReminderLocation? {
        let descriptor = FetchDescriptor<ReminderLocation>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// 場所を保存
    public func saveLocation(_ location: ReminderLocation) throws {
        modelContext.insert(location)
        try modelContext.save()
    }

    /// 場所を削除（紐付くリマインダーもカスケード削除）
    public func deleteLocation(_ location: ReminderLocation) throws {
        modelContext.delete(location)
        try modelContext.save()
    }

    // MARK: - リマインダー操作

    /// 全リマインダーを取得
    public func fetchAllReminders() throws -> [LocationReminder] {
        let descriptor = FetchDescriptor<LocationReminder>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// アクティブなリマインダーのみ取得
    public func fetchActiveReminders() throws -> [LocationReminder] {
        let descriptor = FetchDescriptor<LocationReminder>(
            predicate: #Predicate { $0.isActive && !$0.isCompleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 完了したリマインダーを取得
    public func fetchCompletedReminders() throws -> [LocationReminder] {
        let descriptor = FetchDescriptor<LocationReminder>(
            predicate: #Predicate { $0.isCompleted },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 特定場所のリマインダーを取得
    public func fetchReminders(for locationID: UUID) throws -> [LocationReminder] {
        let allReminders = try fetchAllReminders()
        return allReminders.filter { $0.location?.id == locationID }
    }

    /// IDでリマインダーを取得
    public func fetchReminder(id: UUID) throws -> LocationReminder? {
        let descriptor = FetchDescriptor<LocationReminder>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// リマインダーを保存
    public func saveReminder(_ reminder: LocationReminder) throws {
        modelContext.insert(reminder)
        try modelContext.save()
    }

    /// リマインダーを削除
    public func deleteReminder(_ reminder: LocationReminder) throws {
        modelContext.delete(reminder)
        try modelContext.save()
    }

    /// 変更を保存（既存オブジェクトの更新時）
    public func save() throws {
        try modelContext.save()
    }

    // MARK: - 設定操作

    /// ユーザー設定を取得（存在しない場合はデフォルトを作成）
    public func getUserSettings() throws -> UserLocationSettings {
        let descriptor = FetchDescriptor<UserLocationSettings>()
        if let settings = try modelContext.fetch(descriptor).first {
            return settings
        }
        let defaultSettings = UserLocationSettings.createDefault()
        modelContext.insert(defaultSettings)
        try modelContext.save()
        return defaultSettings
    }

    /// 設定を保存
    public func saveSettings(_ settings: UserLocationSettings) throws {
        try modelContext.save()
    }

    // MARK: - 統計

    /// アクティブなリマインダーの場所数（監視対象数）
    public func activeLocationCount() throws -> Int {
        let locations = try fetchAllLocations()
        return locations.filter { $0.activeReminderCount > 0 }.count
    }
}
