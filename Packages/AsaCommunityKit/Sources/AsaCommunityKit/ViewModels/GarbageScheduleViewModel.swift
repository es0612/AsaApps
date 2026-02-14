import Foundation

// MARK: - GarbageScheduleViewModel

/// ゴミ出しスケジュールのViewModel
///
/// スケジュール一覧、今日/明日のゴミ計算、リマインダー設定を管理する。
@MainActor @Observable
public final class GarbageScheduleViewModel {
    // MARK: - Dependencies

    private let dataService: CommunityDataServiceProtocol
    private let notificationService: NotificationServiceProtocol

    // MARK: - Properties

    public var schedules: [GarbageSchedule] = []
    public var todaysGarbage: [GarbageSchedule] = []
    public var tomorrowsGarbage: [GarbageSchedule] = []
    public var isReminderEnabled: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Initialization

    public init(
        dataService: CommunityDataServiceProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.dataService = dataService
        self.notificationService = notificationService
    }

    // MARK: - Methods

    /// スケジュールを取得し、今日・明日のゴミを計算する
    public func loadSchedules() {
        isLoading = true
        errorMessage = nil
        do {
            schedules = try dataService.fetchGarbageSchedules()

            let settings = try dataService.fetchSettings()
            isReminderEnabled = settings.isGarbageReminderEnabled

            todaysGarbage = filterSchedules(for: Date())
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                tomorrowsGarbage = filterSchedules(for: tomorrow)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 全スケジュールのリマインダーを設定する
    public func setupReminders() async {
        errorMessage = nil
        do {
            let settings = try dataService.fetchSettings()

            // 既存リマインダーをクリア
            await notificationService.removeAllPendingNotifications()

            // 各スケジュールにリマインダーを設定（前夜の指定時刻）
            for schedule in schedules {
                try await notificationService.scheduleGarbageReminder(
                    garbageType: schedule.garbageType,
                    weekday: schedule.weekday,
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// リマインダーのON/OFFを切り替える
    public func toggleReminder() async {
        errorMessage = nil
        isReminderEnabled.toggle()
        do {
            let settings = try dataService.fetchSettings()
            settings.isGarbageReminderEnabled = isReminderEnabled
            try dataService.saveSettings(settings)

            if isReminderEnabled {
                await setupReminders()
            } else {
                await notificationService.removeAllPendingNotifications()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    /// 指定日に該当するゴミ出しスケジュールを抽出する
    private func filterSchedules(for date: Date) -> [GarbageSchedule] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let weekOfMonth = calendar.component(.weekOfMonth, from: date)

        return schedules.filter { schedule in
            guard schedule.weekday == weekday else { return false }
            return schedule.weekOfMonth == 0 || schedule.weekOfMonth == weekOfMonth
        }
    }
}
