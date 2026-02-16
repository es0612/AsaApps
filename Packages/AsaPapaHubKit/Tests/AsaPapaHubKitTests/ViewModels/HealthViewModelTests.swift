import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("HealthViewModel テスト")
struct HealthViewModelTests {
    @Test("初期状態")
    @MainActor func testInitialState() {
        let vm = HealthViewModel(dataService: MockHubDataService())
        #expect(vm.weeklySteps.isEmpty)
        #expect(vm.weeklySleep.isEmpty)
        #expect(vm.selectedPeriod == .week)
        #expect(vm.isLoading == false)
    }

    @Test("健康データ読み込み")
    @MainActor func testLoadHealthData() async {
        let dataService = MockHubDataService()
        let dashboard = HubDashboard(stepsCount: 8000, sleepHours: 7.0)
        dataService.dashboards = [dashboard]
        let vm = HealthViewModel(dataService: dataService)
        await vm.loadHealthData()
        #expect(!vm.weeklySteps.isEmpty)
        #expect(!vm.weeklySleep.isEmpty)
    }

    @Test("期間変更")
    @MainActor func testChangePeriod() async {
        let vm = HealthViewModel(dataService: MockHubDataService())
        await vm.changePeriod(.month)
        #expect(vm.selectedPeriod == .month)
    }

    @Test("エラーハンドリング")
    @MainActor func testErrorHandling() async {
        let dataService = MockHubDataService()
        dataService.shouldThrowError = true
        let vm = HealthViewModel(dataService: dataService)
        await vm.loadHealthData()
        #expect(vm.error != nil)
    }

    @Test("isLoading状態")
    @MainActor func testLoadingState() async {
        let vm = HealthViewModel(dataService: MockHubDataService())
        #expect(vm.isLoading == false)
        await vm.loadHealthData()
        #expect(vm.isLoading == false)
    }
}
