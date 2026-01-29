//
//  CalendarEvent.swift
//  AsaSmartAlarm
//
//  カレンダーイベントモデル
//

import Foundation
import SwiftData

// MARK: - イベント優先度

enum EventPriority: String, Codable, CaseIterable, Identifiable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }

    var iconName: String {
        switch self {
        case .high: return "exclamationmark.3"
        case .medium: return "exclamationmark.2"
        case .low: return "exclamationmark"
        }
    }
}

// MARK: - カレンダーイベント

/// アラーム調整に使用するカレンダーイベント
@Model
final class CalendarEvent {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var title: String
    var eventDescription: String?
    var startTime: Date
    var endTime: Date?
    var location: String?
    var preparationMinutes: Int  // 準備時間（デフォルト30分）
    var travelMinutes: Int       // 移動時間（デフォルト30分）
    var priorityRawValue: String
    var isAllDay: Bool
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    /// イベント優先度
    var priority: EventPriority {
        get { EventPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    /// 推奨起床時刻（準備時間＋移動時間を逆算）
    var suggestedWakeUpTime: Date {
        let totalPreparationSeconds = Double(preparationMinutes + travelMinutes) * 60
        return startTime.addingTimeInterval(-totalPreparationSeconds)
    }

    /// イベント開始までの合計準備時間（分）
    var totalPreparationMinutes: Int {
        preparationMinutes + travelMinutes
    }

    /// 時刻の表示文字列
    var timeString: String {
        if isAllDay {
            return "終日"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startTime)
    }

    /// 日付の表示文字列
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (EEE)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: startTime)
    }

    /// 完全な日時表示
    var fullDateTimeString: String {
        if isAllDay {
            return "\(dateString) 終日"
        }
        return "\(dateString) \(timeString)"
    }

    /// イベントが今日かどうか
    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }

    /// イベントが明日かどうか
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(startTime)
    }

    /// イベントが朝（6:00-12:00）かどうか
    var isMorningEvent: Bool {
        let hour = Calendar.current.component(.hour, from: startTime)
        return hour >= 6 && hour < 12
    }

    // MARK: - Initializer

    init(
        title: String,
        startTime: Date,
        endTime: Date? = nil,
        eventDescription: String? = nil,
        location: String? = nil,
        preparationMinutes: Int = 30,
        travelMinutes: Int = 30,
        priority: EventPriority = .medium,
        isAllDay: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.eventDescription = eventDescription
        self.location = location
        self.preparationMinutes = preparationMinutes
        self.travelMinutes = travelMinutes
        self.priorityRawValue = priority.rawValue
        self.isAllDay = isAllDay
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// イベントを更新
    func update(
        title: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        eventDescription: String? = nil,
        location: String? = nil,
        preparationMinutes: Int? = nil,
        travelMinutes: Int? = nil,
        priority: EventPriority? = nil,
        isAllDay: Bool? = nil
    ) {
        if let title = title { self.title = title }
        if let startTime = startTime { self.startTime = startTime }
        if let endTime = endTime { self.endTime = endTime }
        if let eventDescription = eventDescription { self.eventDescription = eventDescription }
        if let location = location { self.location = location }
        if let preparationMinutes = preparationMinutes { self.preparationMinutes = preparationMinutes }
        if let travelMinutes = travelMinutes { self.travelMinutes = travelMinutes }
        if let priority = priority { self.priority = priority }
        if let isAllDay = isAllDay { self.isAllDay = isAllDay }
        self.updatedAt = Date()
    }
}

// MARK: - Preview Support

extension CalendarEvent {
    /// プレビュー用のサンプルイベント
    static var preview: CalendarEvent {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 9
        components.minute = 0
        let startTime = calendar.date(from: components)!

        return CalendarEvent(
            title: "朝会議",
            startTime: startTime,
            eventDescription: "週次チームミーティング",
            location: "会議室A",
            preparationMinutes: 30,
            travelMinutes: 45,
            priority: .high
        )
    }

    /// プレビュー用のサンプルイベント配列
    static var previewList: [CalendarEvent] {
        let calendar = Calendar.current

        // 明日の朝のイベント
        var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        tomorrowComponents.day! += 1

        var event1Components = tomorrowComponents
        event1Components.hour = 9
        event1Components.minute = 0
        let event1Time = calendar.date(from: event1Components)!

        var event2Components = tomorrowComponents
        event2Components.hour = 14
        event2Components.minute = 30
        let event2Time = calendar.date(from: event2Components)!

        // 明後日のイベント
        var afterTomorrowComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        afterTomorrowComponents.day! += 2
        afterTomorrowComponents.hour = 10
        afterTomorrowComponents.minute = 0
        let event3Time = calendar.date(from: afterTomorrowComponents)!

        return [
            CalendarEvent(
                title: "朝会議",
                startTime: event1Time,
                eventDescription: "週次チームミーティング",
                preparationMinutes: 30,
                travelMinutes: 45,
                priority: .high
            ),
            CalendarEvent(
                title: "クライアントMTG",
                startTime: event2Time,
                location: "オンライン",
                preparationMinutes: 15,
                travelMinutes: 0,
                priority: .medium
            ),
            CalendarEvent(
                title: "歯医者",
                startTime: event3Time,
                location: "○○歯科",
                preparationMinutes: 20,
                travelMinutes: 30,
                priority: .low
            )
        ]
    }
}
