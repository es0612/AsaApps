import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("SafetyViewModel テスト")
struct SafetyViewModelTests {
    @MainActor
    @Test("安全データを正しく読み込む")
    func testLoadSafetyData() {
        let mock = MockCommunityDataService()
        mock.safetyReports = [
            SafetyReport(title: "不審者情報", alertLevel: .warning),
        ]
        mock.shelters = [
            EvacuationShelter(name: "小学校", address: "住所", latitude: 35.68, longitude: 139.76, capacity: 100),
        ]
        let vm = SafetyViewModel(
            dataService: mock,
            notificationService: MockNotificationService()
        )
        vm.loadSafetyData()

        #expect(vm.safetyReports.count == 1)
        #expect(vm.shelters.count == 1)
    }

    @MainActor
    @Test("アクティブアラート数を正しくカウントする")
    func testActiveAlertCount() {
        let mock = MockCommunityDataService()
        let warning = SafetyReport(title: "警告", alertLevel: .warning)
        let info = SafetyReport(title: "情報", alertLevel: .info)
        mock.safetyReports = [warning, info]
        let vm = SafetyViewModel(
            dataService: mock,
            notificationService: MockNotificationService()
        )
        vm.loadSafetyData()

        #expect(vm.activeAlertCount == 1) // warning のみ
    }

    @MainActor
    @Test("レポートを解決済みにする")
    func testResolveReport() {
        let mock = MockCommunityDataService()
        let report = SafetyReport(title: "テスト", alertLevel: .caution)
        mock.safetyReports = [report]
        let vm = SafetyViewModel(
            dataService: mock,
            notificationService: MockNotificationService()
        )
        vm.loadSafetyData()
        vm.resolveReport(report)

        #expect(vm.safetyReports.first?.isResolved == true)
    }
}
