//
//  SmartAlarm.swift
//  AsaSmartAlarm
//
//  メインのアラームモデル
//

import Foundation
import SwiftData

// MARK: - スマートアラーム

/// 天気や予定に応じて自動調整されるスマートアラーム
@Model
final class SmartAlarm {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID
    var baseTime: Date          // 基準時刻（時:分のみ使用）
    var label: String
    var isEnabled: Bool
    var repeatDaysData: Data?   // [Int]をJSONで保存
    var soundName: String
    var createdAt: Date
    var updatedAt: Date

    // MARK: - スマート機能フラグ

    var weatherAdjustmentEnabled: Bool
    var eventAdjustmentEnabled: Bool

    // MARK: - Relationship

    @Relationship(deleteRule: .cascade, inverse: \AlarmAdjustmentRule.alarm)
    var adjustmentRules: [AlarmAdjustmentRule] = []

    // MARK: - Computed Properties

    /// 繰り返し曜日（0=日曜日, 1=月曜日, ..., 6=土曜日）
    var repeatDays: [Int] {
        get {
            guard let data = repeatDaysData else { return [] }
            return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
        }
        set {
            repeatDaysData = try? JSONEncoder().encode(newValue)
        }
    }

    /// 繰り返し曜日の表示文字列
    var repeatDaysDescription: String {
        if repeatDays.isEmpty {
            return "1回のみ"
        }

        let dayNames = ["日", "月", "火", "水", "木", "金", "土"]

        // 毎日の場合
        if repeatDays.count == 7 {
            return "毎日"
        }

        // 平日のみ
        if repeatDays.sorted() == [1, 2, 3, 4, 5] {
            return "平日"
        }

        // 週末のみ
        if repeatDays.sorted() == [0, 6] {
            return "週末"
        }

        // 個別表示
        let sortedDays = repeatDays.sorted()
        return sortedDays.map { dayNames[$0] }.joined(separator: " ")
    }

    /// 基準時刻の時:分表示
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: baseTime)
    }

    /// 次回のアラーム予定日時（調整なし）
    var nextScheduledDate: Date? {
        calculateNextDate(from: Date())
    }

    /// 有効な天気ルールのみ取得
    var enabledWeatherRules: [AlarmAdjustmentRule] {
        adjustmentRules.filter { $0.conditionType == .weather && $0.isEnabled }
    }

    /// 有効なイベントルールのみ取得
    var enabledEventRules: [AlarmAdjustmentRule] {
        adjustmentRules.filter { $0.conditionType == .event && $0.isEnabled }
    }

    // MARK: - Initializer

    init(
        baseTime: Date,
        label: String = "",
        isEnabled: Bool = true,
        repeatDays: [Int] = [],
        soundName: String = "default",
        weatherAdjustmentEnabled: Bool = true,
        eventAdjustmentEnabled: Bool = true
    ) {
        self.id = UUID()
        self.baseTime = baseTime
        self.label = label
        self.isEnabled = isEnabled
        self.repeatDaysData = try? JSONEncoder().encode(repeatDays)
        self.soundName = soundName
        self.createdAt = Date()
        self.updatedAt = Date()
        self.weatherAdjustmentEnabled = weatherAdjustmentEnabled
        self.eventAdjustmentEnabled = eventAdjustmentEnabled
    }

    // MARK: - Methods

    /// 次回のアラーム日時を計算（基準日から）
    func calculateNextDate(from baseDate: Date) -> Date? {
        let calendar = Calendar.current

        // 基準時刻の時:分を取得
        let timeComponents = calendar.dateComponents([.hour, .minute], from: baseTime)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else {
            return nil
        }

        // 今日の同じ時刻を作成
        var todayAtTime = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: baseDate
        )!

        // 繰り返しなしの場合
        if repeatDays.isEmpty {
            // 今日の時刻がまだ来ていなければ今日、そうでなければ明日
            if todayAtTime > baseDate {
                return todayAtTime
            } else {
                return calendar.date(byAdding: .day, value: 1, to: todayAtTime)
            }
        }

        // 繰り返しありの場合
        // 今日から7日間チェック
        for dayOffset in 0..<7 {
            let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: todayAtTime)!
            let weekday = calendar.component(.weekday, from: checkDate) - 1  // 0=日曜日

            if repeatDays.contains(weekday) {
                // dayOffset == 0 の場合、時刻が過ぎていないかチェック
                if dayOffset == 0 && checkDate <= baseDate {
                    continue
                }
                return checkDate
            }
        }

        return nil
    }

    /// ルールを追加
    func addRule(_ rule: AlarmAdjustmentRule) {
        rule.alarm = self
        adjustmentRules.append(rule)
        updatedAt = Date()
    }

    /// ルールを削除
    func removeRule(_ rule: AlarmAdjustmentRule) {
        adjustmentRules.removeAll { $0.id == rule.id }
        updatedAt = Date()
    }

    /// デフォルトの天気ルールをセットアップ
    func setupDefaultWeatherRules() {
        let defaultRules = AlarmAdjustmentRule.defaultWeatherRules()
        for rule in defaultRules {
            addRule(rule)
        }
    }

    /// 特定の天気条件のルールを取得
    func rule(for condition: WeatherCondition) -> AlarmAdjustmentRule? {
        adjustmentRules.first {
            $0.conditionType == .weather && $0.weatherCondition == condition
        }
    }

    /// アラームを更新
    func update(
        baseTime: Date? = nil,
        label: String? = nil,
        isEnabled: Bool? = nil,
        repeatDays: [Int]? = nil,
        soundName: String? = nil,
        weatherAdjustmentEnabled: Bool? = nil,
        eventAdjustmentEnabled: Bool? = nil
    ) {
        if let baseTime = baseTime { self.baseTime = baseTime }
        if let label = label { self.label = label }
        if let isEnabled = isEnabled { self.isEnabled = isEnabled }
        if let repeatDays = repeatDays { self.repeatDays = repeatDays }
        if let soundName = soundName { self.soundName = soundName }
        if let weatherAdjustmentEnabled = weatherAdjustmentEnabled {
            self.weatherAdjustmentEnabled = weatherAdjustmentEnabled
        }
        if let eventAdjustmentEnabled = eventAdjustmentEnabled {
            self.eventAdjustmentEnabled = eventAdjustmentEnabled
        }
        self.updatedAt = Date()
    }
}

// MARK: - Preview Support

extension SmartAlarm {
    /// プレビュー用のサンプルアラーム
    static var preview: SmartAlarm {
        let calendar = Calendar.current
        let baseTime = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!

        let alarm = SmartAlarm(
            baseTime: baseTime,
            label: "朝活アラーム",
            isEnabled: true,
            repeatDays: [1, 2, 3, 4, 5],  // 平日
            weatherAdjustmentEnabled: true,
            eventAdjustmentEnabled: true
        )
        alarm.setupDefaultWeatherRules()
        return alarm
    }
}
