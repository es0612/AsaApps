//
//  DataService.swift
//  AsaSmartAlarm
//
//  Swift Dataを使用したデータ管理サービス
//

import Foundation
import SwiftData

// MARK: - データサービス

/// Swift Dataを使用したCRUD操作を提供するサービス
@MainActor
final class DataService {
    // MARK: - Properties

    let container: ModelContainer
    var modelContext: ModelContext {
        container.mainContext
    }

    // MARK: - Initializer

    init(inMemory: Bool = false) throws {
        let schema = Schema([
            SmartAlarm.self,
            AlarmAdjustmentRule.self,
            CalendarEvent.self,
            AlarmSettings.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    // MARK: - Alarm CRUD

    /// アラームを作成
    @discardableResult
    func createAlarm(
        baseTime: Date,
        label: String = "",
        repeatDays: [Int] = [],
        weatherAdjustmentEnabled: Bool = true,
        eventAdjustmentEnabled: Bool = true,
        setupDefaultRules: Bool = true
    ) throws -> SmartAlarm {
        let alarm = SmartAlarm(
            baseTime: baseTime,
            label: label,
            isEnabled: true,
            repeatDays: repeatDays,
            weatherAdjustmentEnabled: weatherAdjustmentEnabled,
            eventAdjustmentEnabled: eventAdjustmentEnabled
        )

        if setupDefaultRules {
            alarm.setupDefaultWeatherRules()
        }

        modelContext.insert(alarm)
        try modelContext.save()

        print("📅 アラーム作成: \(alarm.timeString) - \(label)")
        return alarm
    }

    /// すべてのアラームを取得
    func fetchAllAlarms() throws -> [SmartAlarm] {
        let descriptor = FetchDescriptor<SmartAlarm>(
            sortBy: [SortDescriptor(\.baseTime)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 有効なアラームのみ取得
    func fetchEnabledAlarms() throws -> [SmartAlarm] {
        let descriptor = FetchDescriptor<SmartAlarm>(
            predicate: #Predicate { $0.isEnabled },
            sortBy: [SortDescriptor(\.baseTime)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// アラームを更新
    func updateAlarm(_ alarm: SmartAlarm) throws {
        alarm.updatedAt = Date()
        try modelContext.save()
        print("📅 アラーム更新: \(alarm.timeString)")
    }

    /// アラームを削除
    func deleteAlarm(_ alarm: SmartAlarm) throws {
        modelContext.delete(alarm)
        try modelContext.save()
        print("📅 アラーム削除: \(alarm.id)")
    }

    // MARK: - Event CRUD

    /// イベントを作成
    @discardableResult
    func createEvent(
        title: String,
        startTime: Date,
        endTime: Date? = nil,
        description: String? = nil,
        location: String? = nil,
        preparationMinutes: Int = 30,
        travelMinutes: Int = 30,
        priority: EventPriority = .medium,
        isAllDay: Bool = false
    ) throws -> CalendarEvent {
        let event = CalendarEvent(
            title: title,
            startTime: startTime,
            endTime: endTime,
            eventDescription: description,
            location: location,
            preparationMinutes: preparationMinutes,
            travelMinutes: travelMinutes,
            priority: priority,
            isAllDay: isAllDay
        )

        modelContext.insert(event)
        try modelContext.save()

        print("📆 イベント作成: \(title) - \(event.fullDateTimeString)")
        return event
    }

    /// すべてのイベントを取得
    func fetchAllEvents() throws -> [CalendarEvent] {
        let descriptor = FetchDescriptor<CalendarEvent>(
            sortBy: [SortDescriptor(\.startTime)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 今後のイベントを取得
    func fetchUpcomingEvents(days: Int = 7) throws -> [CalendarEvent] {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: now)!

        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { event in
                event.startTime >= now && event.startTime <= endDate
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 明日の朝のイベントを取得
    func fetchTomorrowMorningEvents() throws -> [CalendarEvent] {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            return []
        }

        let startOfTomorrow = calendar.startOfDay(for: tomorrow)
        guard let endOfTomorrowMorning = calendar.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: tomorrow
        ) else {
            return []
        }

        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { event in
                event.startTime >= startOfTomorrow &&
                event.startTime <= endOfTomorrowMorning &&
                !event.isAllDay
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// イベントを更新
    func updateEvent(_ event: CalendarEvent) throws {
        event.updatedAt = Date()
        try modelContext.save()
        print("📆 イベント更新: \(event.title)")
    }

    /// イベントを削除
    func deleteEvent(_ event: CalendarEvent) throws {
        modelContext.delete(event)
        try modelContext.save()
        print("📆 イベント削除: \(event.id)")
    }

    // MARK: - Settings CRUD

    /// 設定を取得（存在しなければ作成）
    func fetchOrCreateSettings() throws -> AlarmSettings {
        let descriptor = FetchDescriptor<AlarmSettings>()
        let existingSettings = try modelContext.fetch(descriptor)

        if let settings = existingSettings.first {
            return settings
        }

        // 新規作成
        let newSettings = AlarmSettings()
        modelContext.insert(newSettings)
        try modelContext.save()
        print("⚙️ 設定を新規作成")
        return newSettings
    }

    /// 設定を更新
    func updateSettings(_ settings: AlarmSettings) throws {
        settings.updatedAt = Date()
        try modelContext.save()
        print("⚙️ 設定を更新")
    }

    // MARK: - Utility Methods

    /// すべてのデータを削除（デバッグ用）
    func deleteAllData() throws {
        let alarms = try fetchAllAlarms()
        for alarm in alarms {
            modelContext.delete(alarm)
        }

        let events = try fetchAllEvents()
        for event in events {
            modelContext.delete(event)
        }

        try modelContext.save()
        print("🗑️ すべてのデータを削除")
    }
}

// MARK: - Preview Support

extension DataService {
    /// プレビュー用のサービス
    static var preview: DataService {
        do {
            let service = try DataService(inMemory: true)

            // サンプルアラームを作成
            let calendar = Calendar.current
            let baseTime1 = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!
            let baseTime2 = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!

            _ = try service.createAlarm(
                baseTime: baseTime1,
                label: "朝活アラーム",
                repeatDays: [1, 2, 3, 4, 5]
            )

            _ = try service.createAlarm(
                baseTime: baseTime2,
                label: "週末アラーム",
                repeatDays: [0, 6]
            )

            // サンプルイベントを作成
            var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            tomorrowComponents.day! += 1
            tomorrowComponents.hour = 9
            tomorrowComponents.minute = 0

            _ = try service.createEvent(
                title: "朝会議",
                startTime: calendar.date(from: tomorrowComponents)!,
                preparationMinutes: 30,
                travelMinutes: 45,
                priority: .high
            )

            return service
        } catch {
            fatalError("プレビュー用DataServiceの作成に失敗: \(error)")
        }
    }
}
