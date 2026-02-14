import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("GarbageScheduleService テスト")
struct GarbageScheduleServiceTests {

    let service = GarbageScheduleService()

    @Test("nextCollectionDate - 毎週の次回収集日を計算する")
    func testNextCollectionDateWeekly() {
        let calendar = Calendar.current
        // 月曜日の毎週スケジュール
        let schedule = GarbageSchedule(garbageType: .burnable, weekday: 2, weekOfMonth: 0)

        // 基準日を固定（2026-01-05 は月曜日）
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 5
        components.hour = 6
        components.minute = 0
        let baseDate = calendar.date(from: components)!

        let next = service.nextCollectionDate(for: schedule, from: baseDate)
        #expect(next != nil)
        if let next {
            // 同じ日（まだ収集時刻前）
            #expect(calendar.component(.weekday, from: next) == 2)
            #expect(calendar.component(.hour, from: next) == 8)
        }
    }

    @Test("nextCollectionDate - 収集時刻過ぎなら翌週を返す")
    func testNextCollectionDateWeeklyAfterTime() {
        let calendar = Calendar.current
        let schedule = GarbageSchedule(garbageType: .burnable, weekday: 2, weekOfMonth: 0)

        // 月曜の9時（収集時刻8時を過ぎている）
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 5
        components.hour = 9
        components.minute = 0
        let baseDate = calendar.date(from: components)!

        let next = service.nextCollectionDate(for: schedule, from: baseDate)
        #expect(next != nil)
        if let next {
            // 翌週の月曜
            #expect(calendar.component(.day, from: next) == 12)
        }
    }

    @Test("nextCollectionDate - 月次（第N週）の次回収集日を計算する")
    func testNextCollectionDateMonthly() {
        let calendar = Calendar.current
        // 第1水曜日のスケジュール
        let schedule = GarbageSchedule(
            garbageType: .nonBurnable, weekday: 4, weekOfMonth: 1
        )

        // 2026-01-01（木曜）を基準に
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = 6
        let baseDate = calendar.date(from: components)!

        let next = service.nextCollectionDate(for: schedule, from: baseDate)
        #expect(next != nil)
        if let next {
            #expect(calendar.component(.weekday, from: next) == 4)
            #expect(calendar.component(.month, from: next) == 1)
        }
    }

    @Test("todaysGarbage - 今日の曜日に該当するスケジュールをフィルタする")
    func testTodaysGarbage() {
        let todayWeekday = Calendar.current.component(.weekday, from: Date())

        let matchingSchedule = GarbageSchedule(
            garbageType: .burnable, weekday: todayWeekday, weekOfMonth: 0
        )
        let nonMatchingSchedule = GarbageSchedule(
            garbageType: .recyclePET, weekday: (todayWeekday % 7) + 1, weekOfMonth: 0
        )

        let result = service.todaysGarbage(schedules: [matchingSchedule, nonMatchingSchedule])
        #expect(result.count == 1)
        #expect(result.first?.garbageType == .burnable)
    }

    @Test("tomorrowsGarbage - 明日の曜日に該当するスケジュールをフィルタする")
    func testTomorrowsGarbage() {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            Issue.record("明日の日付計算失敗")
            return
        }
        let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)

        let matchingSchedule = GarbageSchedule(
            garbageType: .recyclePaper, weekday: tomorrowWeekday, weekOfMonth: 0
        )
        let nonMatchingSchedule = GarbageSchedule(
            garbageType: .burnable, weekday: (tomorrowWeekday % 7) + 1, weekOfMonth: 0
        )

        let result = service.tomorrowsGarbage(schedules: [matchingSchedule, nonMatchingSchedule])
        #expect(result.count == 1)
        #expect(result.first?.garbageType == .recyclePaper)
    }

    @Test("todaysGarbage - 空の配列を渡すと空を返す")
    func testTodaysGarbageEmpty() {
        let result = service.todaysGarbage(schedules: [])
        #expect(result.isEmpty)
    }
}
