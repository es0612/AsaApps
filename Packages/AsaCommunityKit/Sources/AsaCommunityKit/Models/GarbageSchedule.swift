import Foundation
import SwiftData

// MARK: - GarbageSchedule

/// ゴミ出しスケジュールモデル
@Model
public final class GarbageSchedule {
    public var id: UUID = UUID()
    public var garbageTypeRawValue: String = GarbageType.burnable.rawValue
    /// 収集曜日（1=日曜...7=土曜、Calendar.component(.weekday)準拠）
    public var weekday: Int = 2
    /// 第何週目（0=毎週、1=第1週、2=第2週...）
    public var weekOfMonth: Int = 0
    /// 収集開始時刻（朝8:00等）
    public var collectionHour: Int = 8
    public var collectionMinute: Int = 0
    public var note: String = ""

    public init(
        garbageType: GarbageType,
        weekday: Int,
        weekOfMonth: Int = 0,
        collectionHour: Int = 8,
        collectionMinute: Int = 0,
        note: String = ""
    ) {
        self.id = UUID()
        self.garbageTypeRawValue = garbageType.rawValue
        self.weekday = weekday
        self.weekOfMonth = weekOfMonth
        self.collectionHour = collectionHour
        self.collectionMinute = collectionMinute
        self.note = note
    }

    // MARK: - GarbageType Accessor

    /// GarbageType への変換アクセサ
    public var garbageType: GarbageType {
        get { GarbageType(rawValue: garbageTypeRawValue) ?? .burnable }
        set { garbageTypeRawValue = newValue.rawValue }
    }

    // MARK: - Computed Properties

    /// 曜日表示テキスト
    public var weekdayText: String {
        let symbols = Calendar.current.shortWeekdaySymbols
        guard weekday >= 1, weekday <= 7 else { return "不明" }
        return symbols[weekday - 1]
    }

    /// スケジュール説明文
    public var scheduleDescription: String {
        if weekOfMonth == 0 {
            return "毎週\(weekdayText)曜日"
        } else {
            return "第\(weekOfMonth)\(weekdayText)曜日"
        }
    }
}
