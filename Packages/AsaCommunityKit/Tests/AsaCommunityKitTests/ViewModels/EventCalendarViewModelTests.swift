import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("EventCalendarViewModel テスト")
struct EventCalendarViewModelTests {
    @MainActor
    @Test("イベントを正しく読み込む")
    func testLoadEvents() {
        let mock = MockCommunityDataService()
        mock.events = [
            CommunityEvent(
                title: "夏祭り", location: "公園",
                startDate: Date().addingTimeInterval(86400),
                endDate: Date().addingTimeInterval(86400 + 3600)
            ),
        ]
        let vm = EventCalendarViewModel(
            dataService: mock,
            notificationService: MockNotificationService()
        )
        vm.loadEvents()

        #expect(vm.events.count == 1)
    }

    @MainActor
    @Test("イベントを作成できる")
    func testCreateEvent() {
        let mock = MockCommunityDataService()
        let vm = EventCalendarViewModel(
            dataService: mock,
            notificationService: MockNotificationService()
        )
        vm.createEvent(
            title: "防災訓練",
            location: "小学校",
            startDate: Date().addingTimeInterval(86400),
            endDate: Date().addingTimeInterval(86400 + 7200)
        )

        #expect(vm.events.count == 1)
        #expect(vm.events.first?.title == "防災訓練")
    }

    @MainActor
    @Test("選択日のイベントをフィルタする")
    func testEventsForSelectedDate() {
        let mock = MockCommunityDataService()
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        mock.events = [
            CommunityEvent(
                title: "今日のイベント", location: "場所",
                startDate: today, endDate: today.addingTimeInterval(3600)
            ),
            CommunityEvent(
                title: "明日のイベント", location: "場所",
                startDate: tomorrow, endDate: tomorrow.addingTimeInterval(3600)
            ),
        ]
        let vm = EventCalendarViewModel(
            dataService: mock,
            notificationService: MockNotificationService()
        )
        vm.loadEvents()
        vm.selectedDate = today

        #expect(vm.eventsForSelectedDate.count == 1)
        #expect(vm.eventsForSelectedDate.first?.title == "今日のイベント")
    }
}
