import Foundation

// MARK: - GarbageScheduleService

/// ゴミ出しスケジュール計算サービス
public struct GarbageScheduleService: Sendable {

    public init() {}

    // MARK: - 次回収集日の計算

    /// 指定スケジュールの次回収集日を計算する
    /// - Parameters:
    ///   - schedule: ゴミ出しスケジュール
    ///   - date: 基準日（デフォルトは今日）
    /// - Returns: 次回の収集日（見つからない場合はnil）
    public func nextCollectionDate(
        for schedule: GarbageSchedule,
        from date: Date = Date()
    ) -> Date? {
        let calendar = Calendar.current

        // 毎週の場合
        if schedule.weekOfMonth == 0 {
            return nextWeeklyDate(
                weekday: schedule.weekday,
                hour: schedule.collectionHour,
                minute: schedule.collectionMinute,
                from: date,
                calendar: calendar
            )
        }

        // 第N週の場合
        return nextMonthlyDate(
            weekday: schedule.weekday,
            weekOfMonth: schedule.weekOfMonth,
            hour: schedule.collectionHour,
            minute: schedule.collectionMinute,
            from: date,
            calendar: calendar
        )
    }

    // MARK: - 今日・明日のゴミ

    /// 今日のゴミ出しスケジュールをフィルタ
    public func todaysGarbage(schedules: [GarbageSchedule]) -> [GarbageSchedule] {
        garbageForDate(Date(), schedules: schedules)
    }

    /// 明日のゴミ出しスケジュールをフィルタ
    public func tomorrowsGarbage(schedules: [GarbageSchedule]) -> [GarbageSchedule] {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            return []
        }
        return garbageForDate(tomorrow, schedules: schedules)
    }

    // MARK: - Private

    /// 指定日に該当するゴミ出しスケジュールを返す
    private func garbageForDate(
        _ date: Date,
        schedules: [GarbageSchedule]
    ) -> [GarbageSchedule] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        return schedules.filter { schedule in
            // 曜日が一致するか
            guard schedule.weekday == weekday else { return false }

            // 毎週ならOK
            if schedule.weekOfMonth == 0 { return true }

            // 第N週の判定: 日付が何日目かで週を計算
            let day = calendar.component(.day, from: date)
            let weekNumber = (day - 1) / 7 + 1
            return schedule.weekOfMonth == weekNumber
        }
    }

    /// 毎週繰り返しの次回日付を計算
    private func nextWeeklyDate(
        weekday: Int,
        hour: Int,
        minute: Int,
        from date: Date,
        calendar: Calendar
    ) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: date)
        var daysUntil = weekday - currentWeekday
        if daysUntil < 0 {
            daysUntil += 7
        }

        // 同じ曜日の場合、時刻も比較
        if daysUntil == 0 {
            let currentHour = calendar.component(.hour, from: date)
            let currentMinute = calendar.component(.minute, from: date)
            if currentHour > hour || (currentHour == hour && currentMinute >= minute) {
                daysUntil = 7
            }
        }

        guard let targetDate = calendar.date(byAdding: .day, value: daysUntil, to: date) else {
            return nil
        }
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: targetDate
        )
    }

    /// 月次繰り返し（第N曜日）の次回日付を計算
    private func nextMonthlyDate(
        weekday: Int,
        weekOfMonth: Int,
        hour: Int,
        minute: Int,
        from date: Date,
        calendar: Calendar
    ) -> Date? {
        // 今月の第N曜日を計算
        if let thisMonth = nthWeekdayOfMonth(
            weekday: weekday,
            nth: weekOfMonth,
            month: calendar.component(.month, from: date),
            year: calendar.component(.year, from: date),
            hour: hour,
            minute: minute,
            calendar: calendar
        ), thisMonth > date {
            return thisMonth
        }

        // 来月の第N曜日を計算
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) else {
            return nil
        }
        return nthWeekdayOfMonth(
            weekday: weekday,
            nth: weekOfMonth,
            month: calendar.component(.month, from: nextMonth),
            year: calendar.component(.year, from: nextMonth),
            hour: hour,
            minute: minute,
            calendar: calendar
        )
    }

    /// 指定月の第N曜日の日付を返す
    private func nthWeekdayOfMonth(
        weekday: Int,
        nth: Int,
        month: Int,
        year: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date? {
        // 月初を求める
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let firstDay = calendar.date(from: components) else {
            return nil
        }

        // 月初の曜日
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        var daysOffset = weekday - firstWeekday
        if daysOffset < 0 {
            daysOffset += 7
        }
        // 第N週目に移動
        daysOffset += (nth - 1) * 7

        guard let result = calendar.date(byAdding: .day, value: daysOffset, to: firstDay) else {
            return nil
        }

        // 計算結果が同じ月であることを確認
        let resultMonth = calendar.component(.month, from: result)
        guard resultMonth == month else { return nil }

        return result
    }
}
