import Foundation
import Testing
@testable import AsaSmartReminderKit

// MARK: - LocationReminder テスト

@Suite("LocationReminder")
struct LocationReminderTests {

    // MARK: - 初期化

    @Test("デフォルト値での初期化")
    func defaultInit() {
        let reminder = LocationReminder(title: "牛乳を買う")
        #expect(reminder.title == "牛乳を買う")
        #expect(reminder.triggerOnEntry == true)
        #expect(reminder.triggerOnExit == false)
        #expect(reminder.isRepeating == false)
        #expect(reminder.isCompleted == false)
        #expect(reminder.isActive == true)
        #expect(reminder.triggerCount == 0)
        #expect(reminder.note == nil)
        #expect(reminder.location == nil)
    }

    @Test("カスタム値での初期化")
    func customInit() {
        let reminder = LocationReminder(
            title: "鍵を確認",
            note: "玄関の鍵",
            triggerOnEntry: false,
            triggerOnExit: true,
            isRepeating: true
        )
        #expect(reminder.title == "鍵を確認")
        #expect(reminder.note == "玄関の鍵")
        #expect(reminder.triggerOnEntry == false)
        #expect(reminder.triggerOnExit == true)
        #expect(reminder.isRepeating == true)
    }

    // MARK: - triggerDescription

    @Test("到着時のみのトリガー説明")
    func entryOnlyTriggerDescription() {
        let reminder = LocationReminder(title: "テスト", triggerOnEntry: true, triggerOnExit: false)
        #expect(reminder.triggerDescription == "到着時")
    }

    @Test("離脱時のみのトリガー説明")
    func exitOnlyTriggerDescription() {
        let reminder = LocationReminder(title: "テスト", triggerOnEntry: false, triggerOnExit: true)
        #expect(reminder.triggerDescription == "離脱時")
    }

    @Test("到着・離脱時のトリガー説明")
    func bothTriggerDescription() {
        let reminder = LocationReminder(title: "テスト", triggerOnEntry: true, triggerOnExit: true)
        #expect(reminder.triggerDescription == "到着・離脱時")
    }

    @Test("無効なトリガー説明")
    func noTriggerDescription() {
        let reminder = LocationReminder(title: "テスト", triggerOnEntry: false, triggerOnExit: false)
        #expect(reminder.triggerDescription == "無効")
    }

    // MARK: - isEffective

    @Test("アクティブかつ未完了ならeffective")
    func isEffectiveWhenActiveAndNotCompleted() {
        let reminder = LocationReminder(title: "テスト", isActive: true)
        #expect(reminder.isEffective == true)
    }

    @Test("非アクティブならnot effective")
    func isNotEffectiveWhenInactive() {
        let reminder = LocationReminder(title: "テスト", isActive: false)
        #expect(reminder.isEffective == false)
    }

    @Test("完了済みならnot effective")
    func isNotEffectiveWhenCompleted() {
        let reminder = LocationReminder(title: "テスト", isCompleted: true)
        #expect(reminder.isEffective == false)
    }

    // MARK: - markCompleted

    @Test("完了にすると状態が正しく変わる")
    func markCompleted() {
        let reminder = LocationReminder(title: "テスト")
        reminder.markCompleted()
        #expect(reminder.isCompleted == true)
        #expect(reminder.completedAt != nil)
        #expect(reminder.isActive == false)
    }

    // MARK: - markIncomplete

    @Test("未完了に戻すと状態が正しく変わる")
    func markIncomplete() {
        let reminder = LocationReminder(title: "テスト", isCompleted: true, isActive: false)
        reminder.markIncomplete()
        #expect(reminder.isCompleted == false)
        #expect(reminder.completedAt == nil)
        #expect(reminder.isActive == true)
    }

    // MARK: - recordTrigger

    @Test("非リピートのトリガー発火で完了になる")
    func recordTriggerNonRepeating() {
        let reminder = LocationReminder(title: "テスト", isRepeating: false)
        reminder.recordTrigger()
        #expect(reminder.triggerCount == 1)
        #expect(reminder.lastTriggeredAt != nil)
        #expect(reminder.isCompleted == true)
    }

    @Test("リピートのトリガー発火で完了にならない")
    func recordTriggerRepeating() {
        let reminder = LocationReminder(title: "テスト", isRepeating: true)
        reminder.recordTrigger()
        #expect(reminder.triggerCount == 1)
        #expect(reminder.lastTriggeredAt != nil)
        #expect(reminder.isCompleted == false)
        #expect(reminder.isActive == true)
    }

    @Test("複数回のトリガー発火でカウントが増える")
    func recordTriggerMultipleTimes() {
        let reminder = LocationReminder(title: "テスト", isRepeating: true)
        reminder.recordTrigger()
        reminder.recordTrigger()
        reminder.recordTrigger()
        #expect(reminder.triggerCount == 3)
    }
}
