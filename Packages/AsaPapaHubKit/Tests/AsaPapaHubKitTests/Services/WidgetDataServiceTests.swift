import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("WidgetDataService テスト")
struct WidgetDataServiceTests {
    @Test("初期状態でデータなし")
    func testInitialStateNil() {
        let service = WidgetDataService(suiteName: "test.widget.\(UUID().uuidString)")
        let data = service.getWidgetData()
        #expect(data == nil)
    }

    @Test("データ更新と取得")
    func testUpdateAndGetData() async throws {
        let suiteName = "test.widget.\(UUID().uuidString)"
        let service = WidgetDataService(suiteName: suiteName)
        let dashboard = HubDashboard(morningScore: 85, stepsCount: 7000, sleepHours: 7.5)
        try await service.updateWidgetData(dashboard: dashboard, routine: nil)
        let data = service.getWidgetData()
        #expect(data != nil)
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            #expect(json["morningScore"] as? Int == 85)
            #expect(json["stepsCount"] as? Int == 7000)
        }
    }

    @Test("ルーティンありのデータ更新")
    func testUpdateWithRoutine() async throws {
        let suiteName = "test.widget.\(UUID().uuidString)"
        let service = WidgetDataService(suiteName: suiteName)
        let dashboard = HubDashboard(morningScore: 90)
        let routine = MorningRoutine(isCompleted: true)
        let item = MorningRoutineItem(statusRawValue: "completed")
        routine.items = [item]
        try await service.updateWidgetData(dashboard: dashboard, routine: routine)
        let data = service.getWidgetData()
        #expect(data != nil)
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            #expect(json["routineCompleted"] as? Bool == true)
        }
    }

    @Test("異なるsuiteNameは独立")
    func testIndependentSuiteNames() async throws {
        let service1 = WidgetDataService(suiteName: "test.widget.\(UUID().uuidString)")
        let service2 = WidgetDataService(suiteName: "test.widget.\(UUID().uuidString)")
        let dashboard = HubDashboard(morningScore: 50)
        try await service1.updateWidgetData(dashboard: dashboard, routine: nil)
        #expect(service1.getWidgetData() != nil)
        #expect(service2.getWidgetData() == nil)
    }

    @Test("更新タイムスタンプが含まれる")
    func testUpdatedAtTimestamp() async throws {
        let suiteName = "test.widget.\(UUID().uuidString)"
        let service = WidgetDataService(suiteName: suiteName)
        let before = Date().timeIntervalSince1970
        let dashboard = HubDashboard()
        try await service.updateWidgetData(dashboard: dashboard, routine: nil)
        let after = Date().timeIntervalSince1970
        if let data = service.getWidgetData(),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let updatedAt = json["updatedAt"] as? TimeInterval
        {
            #expect(updatedAt >= before && updatedAt <= after)
        }
    }
}
