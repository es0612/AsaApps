//
//  AlarmViewModel.swift
//  AsaSmartAlarm
//
//  アラーム管理のメインViewModel
//

import Foundation
import SwiftData

// MARK: - アラームViewModel

/// アラーム一覧と管理を行うメインViewModel
@MainActor
@Observable
final class AlarmViewModel {
    // MARK: - Properties

    private(set) var alarms: [SmartAlarm] = []
    private(set) var settings: AlarmSettings?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    // シート表示
    var showingAddAlarm: Bool = false
    var showingSettings: Bool = false
    var selectedAlarm: SmartAlarm?

    // 計算結果キャッシュ
    private(set) var alarmCalculations: [UUID: AlarmCalculationResult] = [:]

    // Services
    private var dataService: DataService?
    private let schedulerService = AlarmSchedulerService()
    private let notificationService = NotificationService.shared

    // 外部依存（天気・イベント）
    var weatherForecast: MorningWeatherForecast?
    var upcomingEvents: [CalendarEvent] = []

    // MARK: - Computed Properties

    /// 有効なアラームの数
    var enabledAlarmCount: Int {
        alarms.filter { $0.isEnabled }.count
    }

    /// 次に発火するアラーム
    var nextAlarm: SmartAlarm? {
        let enabledAlarms = alarms.filter { $0.isEnabled }
        return enabledAlarms.min { lhs, rhs in
            let lhsNext = alarmCalculations[lhs.id]?.adjustedTime ?? lhs.nextScheduledDate
            let rhsNext = alarmCalculations[rhs.id]?.adjustedTime ?? rhs.nextScheduledDate
            return (lhsNext ?? .distantFuture) < (rhsNext ?? .distantFuture)
        }
    }

    /// 次のアラームの計算結果
    var nextAlarmCalculation: AlarmCalculationResult? {
        guard let next = nextAlarm else { return nil }
        return alarmCalculations[next.id]
    }

    // MARK: - Initializer

    init() {}

    // MARK: - Setup

    /// DataServiceを設定
    func setup(dataService: DataService) {
        self.dataService = dataService
        Task {
            await loadData()
        }
    }

    // MARK: - Data Operations

    /// データをロード
    func loadData() async {
        guard let dataService = dataService else { return }

        isLoading = true
        errorMessage = nil

        do {
            alarms = try dataService.fetchAllAlarms()
            settings = try dataService.fetchOrCreateSettings()

            // 通知権限を確認
            await checkNotificationPermission()

            // アラーム時刻を計算
            await calculateAllAlarmTimes()

            print("📅 アラームをロード: \(alarms.count)件")
        } catch {
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
            print("📅 ロードエラー: \(error)")
        }

        isLoading = false
    }

    /// アラームを追加
    func addAlarm(
        baseTime: Date,
        label: String,
        repeatDays: [Int],
        weatherAdjustmentEnabled: Bool = true,
        eventAdjustmentEnabled: Bool = true
    ) async {
        guard let dataService = dataService else { return }

        do {
            let alarm = try dataService.createAlarm(
                baseTime: baseTime,
                label: label,
                repeatDays: repeatDays,
                weatherAdjustmentEnabled: weatherAdjustmentEnabled,
                eventAdjustmentEnabled: eventAdjustmentEnabled
            )
            alarms.append(alarm)
            alarms.sort { $0.baseTime < $1.baseTime }

            // 時刻を計算してスケジュール
            await calculateAndScheduleAlarm(alarm)

            print("📅 アラーム追加完了: \(alarm.timeString)")
        } catch {
            errorMessage = "アラームの追加に失敗しました"
            print("📅 追加エラー: \(error)")
        }
    }

    /// アラームを更新
    func updateAlarm(_ alarm: SmartAlarm) async {
        guard let dataService = dataService else { return }

        do {
            try dataService.updateAlarm(alarm)

            // 再計算してスケジュール
            await calculateAndScheduleAlarm(alarm)

            print("📅 アラーム更新完了: \(alarm.timeString)")
        } catch {
            errorMessage = "アラームの更新に失敗しました"
            print("📅 更新エラー: \(error)")
        }
    }

    /// アラームの有効/無効を切り替え
    func toggleAlarm(_ alarm: SmartAlarm) async {
        alarm.isEnabled.toggle()
        await updateAlarm(alarm)

        if !alarm.isEnabled {
            // 無効化された場合は通知をキャンセル
            await schedulerService.cancelAlarm(alarm)
        }
    }

    /// アラームを削除
    func deleteAlarm(_ alarm: SmartAlarm) async {
        guard let dataService = dataService else { return }

        do {
            // 通知をキャンセル
            await schedulerService.cancelAlarm(alarm)

            try dataService.deleteAlarm(alarm)
            alarms.removeAll { $0.id == alarm.id }
            alarmCalculations.removeValue(forKey: alarm.id)

            print("📅 アラーム削除完了")
        } catch {
            errorMessage = "アラームの削除に失敗しました"
            print("📅 削除エラー: \(error)")
        }
    }

    /// アラームを複数削除
    func deleteAlarms(at offsets: IndexSet) async {
        let alarmsToDelete = offsets.map { alarms[$0] }
        for alarm in alarmsToDelete {
            await deleteAlarm(alarm)
        }
    }

    // MARK: - Calculation & Scheduling

    /// すべてのアラーム時刻を計算
    func calculateAllAlarmTimes() async {
        for alarm in alarms where alarm.isEnabled {
            if let result = schedulerService.calculateNextAlarmTime(
                for: alarm,
                weatherForecast: weatherForecast,
                events: upcomingEvents
            ) {
                alarmCalculations[alarm.id] = result
            }
        }
    }

    /// 単一アラームの時刻を計算してスケジュール
    func calculateAndScheduleAlarm(_ alarm: SmartAlarm) async {
        guard alarm.isEnabled else { return }

        if let result = schedulerService.calculateNextAlarmTime(
            for: alarm,
            weatherForecast: weatherForecast,
            events: upcomingEvents
        ) {
            alarmCalculations[alarm.id] = result
            await schedulerService.scheduleAlarm(alarm, with: result)
        }
    }

    /// すべての有効なアラームをスケジュール
    func scheduleAllAlarms() async {
        await schedulerService.scheduleAllAlarms(
            alarms,
            weatherForecast: weatherForecast,
            events: upcomingEvents
        )
    }

    /// 天気予報が更新された時に呼び出す
    func weatherForecastUpdated(_ forecast: MorningWeatherForecast?) async {
        self.weatherForecast = forecast
        await calculateAllAlarmTimes()
        await scheduleAllAlarms()
    }

    /// イベントが更新された時に呼び出す
    func eventsUpdated(_ events: [CalendarEvent]) async {
        self.upcomingEvents = events
        await calculateAllAlarmTimes()
        await scheduleAllAlarms()
    }

    // MARK: - Notification

    /// 通知権限をチェック
    private func checkNotificationPermission() async {
        let isAuthorized = await notificationService.isAuthorized()
        if !isAuthorized {
            let granted = await notificationService.requestAuthorization()
            if !granted {
                print("📅 通知権限が拒否されました")
            }
        }
    }

    // MARK: - Utility

    /// 特定アラームの計算結果を取得
    func calculation(for alarm: SmartAlarm) -> AlarmCalculationResult? {
        alarmCalculations[alarm.id]
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Preview Support

extension AlarmViewModel {
    /// プレビュー用のViewModel
    static var preview: AlarmViewModel {
        let viewModel = AlarmViewModel()
        viewModel.setup(dataService: .preview)
        viewModel.weatherForecast = .preview
        return viewModel
    }
}
