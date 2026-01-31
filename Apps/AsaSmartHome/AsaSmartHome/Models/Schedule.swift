import Foundation
import SwiftData

// MARK: - Weekday

/// 曜日を表すビットフラグ
struct Weekday: OptionSet, Codable, Sendable, Hashable {
    let rawValue: Int

    static let sunday    = Weekday(rawValue: 1 << 0)
    static let monday    = Weekday(rawValue: 1 << 1)
    static let tuesday   = Weekday(rawValue: 1 << 2)
    static let wednesday = Weekday(rawValue: 1 << 3)
    static let thursday  = Weekday(rawValue: 1 << 4)
    static let friday    = Weekday(rawValue: 1 << 5)
    static let saturday  = Weekday(rawValue: 1 << 6)

    static let weekdays: Weekday = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekend: Weekday = [.saturday, .sunday]
    static let everyday: Weekday = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    /// 曜日の日本語名
    static let names: [Weekday: String] = [
        .sunday: "日",
        .monday: "月",
        .tuesday: "火",
        .wednesday: "水",
        .thursday: "木",
        .friday: "金",
        .saturday: "土"
    ]

    /// 曜日の順序配列
    static let orderedDays: [Weekday] = [
        .sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday
    ]

    /// 選択されている曜日を文字列で返す
    var displayString: String {
        if self == .everyday {
            return "毎日"
        } else if self == .weekdays {
            return "平日"
        } else if self == .weekend {
            return "週末"
        }

        var result: [String] = []
        for day in Weekday.orderedDays {
            if self.contains(day) {
                result.append(Weekday.names[day] ?? "")
            }
        }
        return result.joined(separator: "・")
    }

    /// 今日がこの曜日セットに含まれるかチェック
    func includesDay(_ weekdayNumber: Int) -> Bool {
        // weekdayNumberは1(日曜)〜7(土曜)
        let day = Weekday(rawValue: 1 << (weekdayNumber - 1))
        return self.contains(day)
    }
}

// MARK: - Schedule Model

/// スケジュールモデル - シーンを指定時刻に実行
@Model
final class Schedule {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var name: String
    var sceneId: UUID?  // 実行するシーンのID
    var hour: Int       // 0-23
    var minute: Int     // 0-59
    var weekdaysRawValue: Int
    var isEnabled: Bool
    var createdAt: Date
    var lastExecuted: Date?

    // MARK: - Computed Properties

    var weekdays: Weekday {
        get { Weekday(rawValue: weekdaysRawValue) }
        set { weekdaysRawValue = newValue.rawValue }
    }

    /// 実行時刻の文字列表現
    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// 次回実行日時を計算
    var nextExecutionDate: Date? {
        guard isEnabled else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.hour, .minute, .weekday], from: now)

        guard let currentHour = currentComponents.hour,
              let currentMinute = currentComponents.minute,
              let currentWeekday = currentComponents.weekday else {
            return nil
        }

        // 今日の実行時刻がまだ来ていない場合
        let isTodayPending = (hour > currentHour) || (hour == currentHour && minute > currentMinute)

        // 次の実行日を探す
        for daysOffset in 0..<8 {
            let targetDate = calendar.date(byAdding: .day, value: daysOffset, to: now)!
            let targetWeekday = calendar.component(.weekday, from: targetDate)

            // この曜日が有効かチェック
            if weekdays.includesDay(targetWeekday) {
                // 今日で、かつ時刻が過ぎている場合はスキップ
                if daysOffset == 0 && !isTodayPending {
                    continue
                }

                // 次回実行日時を構築
                var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
                components.hour = hour
                components.minute = minute
                components.second = 0

                return calendar.date(from: components)
            }
        }

        return nil
    }

    /// 次回実行までの時間文字列
    var nextExecutionString: String {
        guard let nextDate = nextExecutionDate else {
            return "設定なし"
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(nextDate) {
            return "今日 \(timeString)"
        } else if calendar.isDateInTomorrow(nextDate) {
            return "明日 \(timeString)"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "M/d (E) HH:mm"
            return formatter.string(from: nextDate)
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        sceneId: UUID? = nil,
        hour: Int = 7,
        minute: Int = 0,
        weekdays: Weekday = .everyday,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.sceneId = sceneId
        self.hour = hour
        self.minute = minute
        self.weekdaysRawValue = weekdays.rawValue
        self.isEnabled = isEnabled
        self.createdAt = Date()
        self.lastExecuted = nil
    }

    // MARK: - Methods

    /// スケジュールを実行済みとしてマーク
    func markAsExecuted() {
        lastExecuted = Date()
    }
}

// MARK: - Sample Data

extension Schedule {
    /// サンプルスケジュール
    static func sampleSchedules() -> [Schedule] {
        [
            Schedule(name: "朝の目覚め", hour: 6, minute: 30, weekdays: .weekdays),
            Schedule(name: "おやすみタイマー", hour: 23, minute: 0, weekdays: .everyday),
            Schedule(name: "週末のんびり", hour: 9, minute: 0, weekdays: .weekend)
        ]
    }
}
