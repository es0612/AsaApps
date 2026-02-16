import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("MorningRoutine テスト")
struct MorningRoutineTests {
    @Test("初期値が正しい")
    func testDefaultValues() {
        let routine = MorningRoutine()
        #expect(routine.targetDurationMinutes == 60)
        #expect(routine.isCompleted == false)
        #expect(routine.totalScore == 0)
        #expect(routine.startTime == nil)
        #expect(routine.endTime == nil)
        #expect(routine.items.isEmpty)
    }

    @Test("completionRate - アイテムなし")
    func testCompletionRateEmpty() {
        let routine = MorningRoutine()
        #expect(abs(routine.completionRate - 0.0) < 0.0001)
    }

    @Test("completionRate - 全完了")
    func testCompletionRateAllCompleted() {
        let routine = MorningRoutine()
        let item1 = MorningRoutineItem(title: "A", order: 0, statusRawValue: "completed")
        let item2 = MorningRoutineItem(title: "B", order: 1, statusRawValue: "completed")
        routine.items = [item1, item2]
        #expect(abs(routine.completionRate - 1.0) < 0.0001)
    }

    @Test("completionRate - 部分完了")
    func testCompletionRatePartial() {
        let routine = MorningRoutine()
        let item1 = MorningRoutineItem(title: "A", order: 0, statusRawValue: "completed")
        let item2 = MorningRoutineItem(title: "B", order: 1, statusRawValue: "pending")
        routine.items = [item1, item2]
        #expect(abs(routine.completionRate - 0.5) < 0.0001)
    }

    @Test("actualDurationMinutes - 開始・終了あり")
    func testActualDurationWithTimes() {
        let routine = MorningRoutine()
        let start = Date()
        routine.startTime = start
        routine.endTime = start.addingTimeInterval(45 * 60)
        #expect(routine.actualDurationMinutes == 45)
    }

    @Test("actualDurationMinutes - 未開始")
    func testActualDurationNil() {
        let routine = MorningRoutine()
        #expect(routine.actualDurationMinutes == nil)
    }

    @Test("completedItemsCount")
    func testCompletedItemsCount() {
        let routine = MorningRoutine()
        let item1 = MorningRoutineItem(title: "A", order: 0, statusRawValue: "completed")
        let item2 = MorningRoutineItem(title: "B", order: 1, statusRawValue: "skipped")
        let item3 = MorningRoutineItem(title: "C", order: 2, statusRawValue: "completed")
        routine.items = [item1, item2, item3]
        #expect(routine.completedItemsCount == 2)
    }

    @Test("カスタム初期化")
    func testCustomInit() {
        let routine = MorningRoutine(targetDurationMinutes: 45, isCompleted: true, totalScore: 90)
        #expect(routine.targetDurationMinutes == 45)
        #expect(routine.isCompleted == true)
        #expect(routine.totalScore == 90)
    }

    @Test("IDはユニーク")
    func testUniqueId() {
        let r1 = MorningRoutine()
        let r2 = MorningRoutine()
        #expect(r1.id != r2.id)
    }

    @Test("日付の設定")
    func testDateSetting() {
        let date = Date()
        let routine = MorningRoutine(date: date)
        #expect(routine.date == date)
    }

    @Test("completionRate - スキップは完了に含まない")
    func testCompletionRateSkipNotCounted() {
        let routine = MorningRoutine()
        let item1 = MorningRoutineItem(title: "A", order: 0, statusRawValue: "completed")
        let item2 = MorningRoutineItem(title: "B", order: 1, statusRawValue: "skipped")
        routine.items = [item1, item2]
        #expect(abs(routine.completionRate - 0.5) < 0.0001)
    }
}
