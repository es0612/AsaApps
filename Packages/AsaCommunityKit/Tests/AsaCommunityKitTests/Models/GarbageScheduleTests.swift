import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("GarbageSchedule モデルテスト")
struct GarbageScheduleTests {

    @Test("初期化テスト - デフォルト値が正しく設定される")
    func testInitialization() {
        let schedule = GarbageSchedule(garbageType: .burnable, weekday: 2)
        #expect(schedule.garbageType == .burnable)
        #expect(schedule.weekday == 2)
        #expect(schedule.weekOfMonth == 0)
        #expect(schedule.collectionHour == 8)
        #expect(schedule.collectionMinute == 0)
    }

    @Test("garbageType アクセサ - rawValue 経由で正しく変換される")
    func testGarbageTypeAccessor() {
        let schedule = GarbageSchedule(garbageType: .recyclePET, weekday: 4)
        #expect(schedule.garbageType == .recyclePET)
        #expect(schedule.garbageTypeRawValue == "ペットボトル")

        schedule.garbageType = .recycleCan
        #expect(schedule.garbageType == .recycleCan)
        #expect(schedule.garbageTypeRawValue == "缶")
    }

    @Test("garbageType アクセサ - 不正な rawValue はデフォルトを返す")
    func testGarbageTypeAccessorInvalidRawValue() {
        let schedule = GarbageSchedule(garbageType: .burnable, weekday: 2)
        schedule.garbageTypeRawValue = "不正なゴミ種類"
        #expect(schedule.garbageType == .burnable)
    }

    @Test("weekdayText - 曜日表示テキストが正しく返される")
    func testWeekdayText() {
        let symbols = Calendar.current.shortWeekdaySymbols
        let sunday = GarbageSchedule(garbageType: .burnable, weekday: 1)
        #expect(sunday.weekdayText == symbols[0])

        let monday = GarbageSchedule(garbageType: .burnable, weekday: 2)
        #expect(monday.weekdayText == symbols[1])

        let saturday = GarbageSchedule(garbageType: .burnable, weekday: 7)
        #expect(saturday.weekdayText == symbols[6])
    }

    @Test("weekdayText - 範囲外の曜日は「不明」を返す")
    func testWeekdayTextOutOfRange() {
        let schedule = GarbageSchedule(garbageType: .burnable, weekday: 0)
        #expect(schedule.weekdayText == "不明")

        let schedule2 = GarbageSchedule(garbageType: .burnable, weekday: 8)
        #expect(schedule2.weekdayText == "不明")
    }

    @Test("scheduleDescription - 毎週の場合の説明文")
    func testScheduleDescriptionWeekly() {
        let schedule = GarbageSchedule(garbageType: .burnable, weekday: 2, weekOfMonth: 0)
        let symbols = Calendar.current.shortWeekdaySymbols
        #expect(schedule.scheduleDescription == "毎週\(symbols[1])曜日")
    }

    @Test("scheduleDescription - 第N週の場合の説明文")
    func testScheduleDescriptionMonthly() {
        let symbols = Calendar.current.shortWeekdaySymbols
        let schedule = GarbageSchedule(garbageType: .nonBurnable, weekday: 4, weekOfMonth: 2)
        #expect(schedule.scheduleDescription == "第2\(symbols[3])曜日")
    }

    @Test("GarbageType 全種類の iconName と colorHex が存在する")
    func testGarbageTypeProperties() {
        for garbageType in GarbageType.allCases {
            #expect(!garbageType.iconName.isEmpty)
            #expect(!garbageType.colorHex.isEmpty)
        }
    }
}
