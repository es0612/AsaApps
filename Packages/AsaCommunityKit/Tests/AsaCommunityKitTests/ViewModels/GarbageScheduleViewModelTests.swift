import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("GarbageScheduleViewModel テスト")
struct GarbageScheduleViewModelTests {
    @MainActor
    @Test("スケジュールを正しく読み込む")
    func testLoadSchedules() {
        let mock = MockCommunityDataService()
        mock.garbageSchedules = [
            GarbageSchedule(garbageType: .burnable, weekday: 2),
            GarbageSchedule(garbageType: .recyclePlastic, weekday: 4),
        ]
        let vm = GarbageScheduleViewModel(
            dataService: mock,
            notificationService: MockNotificationService()
        )
        vm.loadSchedules()

        #expect(vm.schedules.count == 2)
    }

    @MainActor
    @Test("リマインダー設定が設定から読み込まれる")
    func testReminderSettingsLoaded() {
        let mock = MockCommunityDataService()
        mock.settings.isGarbageReminderEnabled = true
        mock.garbageSchedules = []
        let vm = GarbageScheduleViewModel(
            dataService: mock,
            notificationService: MockNotificationService()
        )
        vm.loadSchedules()

        #expect(vm.isReminderEnabled == true)
    }

    @MainActor
    @Test("エラー時にerrorMessageが設定される")
    func testLoadError() {
        let mock = MockCommunityDataService()
        mock.shouldThrow = true
        let vm = GarbageScheduleViewModel(
            dataService: mock,
            notificationService: MockNotificationService()
        )
        vm.loadSchedules()

        #expect(vm.errorMessage != nil)
    }
}
