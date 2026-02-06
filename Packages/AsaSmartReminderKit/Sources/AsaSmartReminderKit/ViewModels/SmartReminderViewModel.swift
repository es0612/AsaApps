#if os(iOS)
import CoreLocation
import Foundation
import SwiftData

// MARK: - メインViewModel

/// リマインダーのCRUD・監視・フィルタリングを統括するメインViewModel
@MainActor
@Observable
public final class SmartReminderViewModel {
    // MARK: - Properties

    public private(set) var reminders: [LocationReminder] = []
    public private(set) var locations: [ReminderLocation] = []
    public private(set) var monitoringState: MonitoringState = .idle
    public var selectedFilter: ReminderFilter = .active
    public var errorMessage: String?
    public var showingAddReminder = false
    public var showingAddLocation = false

    private let dataService: ReminderDataService
    private let notificationService: NotificationService
    private let geofenceService: GeofenceMonitorService
    private let regionPrioritizer: RegionPrioritizer

    // MARK: - フィルタ

    public enum ReminderFilter: String, CaseIterable {
        case active = "アクティブ"
        case completed = "完了"
        case all = "すべて"
    }

    public var filteredReminders: [LocationReminder] {
        switch selectedFilter {
        case .active:
            reminders.filter { $0.isActive && !$0.isCompleted }
        case .completed:
            reminders.filter(\.isCompleted)
        case .all:
            reminders
        }
    }

    // MARK: - Init

    public init(
        dataService: ReminderDataService,
        notificationService: NotificationService? = nil,
        geofenceService: GeofenceMonitorService? = nil,
        regionPrioritizer: RegionPrioritizer = RegionPrioritizer()
    ) {
        self.dataService = dataService
        self.notificationService = notificationService ?? NotificationService()
        self.geofenceService = geofenceService ?? GeofenceMonitorService()
        self.regionPrioritizer = regionPrioritizer
    }

    // MARK: - データ読み込み

    /// 全データを読み込み
    public func loadData() {
        do {
            reminders = try dataService.fetchAllReminders()
            locations = try dataService.fetchAllLocations()
        } catch {
            errorMessage = "データの読み込みに失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - リマインダー操作

    /// リマインダーを追加
    public func addReminder(
        title: String,
        note: String?,
        location: ReminderLocation,
        triggerOnEntry: Bool,
        triggerOnExit: Bool,
        isRepeating: Bool
    ) async {
        let reminder = LocationReminder(
            title: title,
            note: note,
            triggerOnEntry: triggerOnEntry,
            triggerOnExit: triggerOnExit,
            isRepeating: isRepeating,
            location: location
        )

        do {
            try dataService.saveReminder(reminder)
            try await notificationService.scheduleLocationNotification(
                reminder: reminder,
                location: location
            )
            try dataService.save()
            loadData()
        } catch {
            errorMessage = "リマインダーの追加に失敗: \(error.localizedDescription)"
        }
    }

    /// リマインダーを完了/未完了に切替
    public func toggleCompletion(_ reminder: LocationReminder) {
        if reminder.isCompleted {
            reminder.markIncomplete()
        } else {
            reminder.markCompleted()
            notificationService.cancelNotification(for: reminder)
        }

        do {
            try dataService.save()
            loadData()
        } catch {
            errorMessage = "状態の変更に失敗: \(error.localizedDescription)"
        }
    }

    /// リマインダーを削除
    public func deleteReminder(_ reminder: LocationReminder) {
        notificationService.cancelNotification(for: reminder)
        do {
            try dataService.deleteReminder(reminder)
            loadData()
        } catch {
            errorMessage = "リマインダーの削除に失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - 場所操作

    /// 場所を追加
    public func addLocation(
        name: String,
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        category: LocationCategory,
        address: String?
    ) {
        let location = ReminderLocation(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radius: radius,
            address: address,
            category: category
        )

        do {
            try dataService.saveLocation(location)
            loadData()
        } catch {
            errorMessage = "場所の追加に失敗: \(error.localizedDescription)"
        }
    }

    /// 場所を削除（紐付くリマインダーもカスケード削除）
    public func deleteLocation(_ location: ReminderLocation) {
        notificationService.cancelNotifications(for: location.reminders)
        do {
            try dataService.deleteLocation(location)
            loadData()
        } catch {
            errorMessage = "場所の削除に失敗: \(error.localizedDescription)"
        }
    }

    // MARK: - 監視状態

    /// 監視中のリージョン数を更新
    public func updateMonitoringState() async {
        let count = await geofenceService.monitoredRegionCount
        if count > 0 {
            monitoringState = .monitoring(activeCount: count)
        } else {
            monitoringState = .idle
        }
    }

    // MARK: - エラー処理

    public func clearError() {
        errorMessage = nil
    }
}
#endif
