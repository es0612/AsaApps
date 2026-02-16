import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("DashboardViewModel テスト")
struct DashboardViewModelTests {
    @Test("初期状態")
    @MainActor func testInitialState() {
        let vm = DashboardViewModel(
            dataService: MockHubDataService(),
            scoreCalculator: MockScoreCalculator(),
            aggregator: MockDomainAggregator()
        )
        #expect(vm.dashboard == nil)
        #expect(vm.snapshots.isEmpty)
        #expect(vm.briefing == nil)
        #expect(vm.isLoading == false)
        #expect(vm.morningScore == 0)
        #expect(vm.stepsCount == 0)
        #expect(vm.streak == 0)
    }

    @Test("ダッシュボード読み込み - データあり")
    @MainActor func testLoadDashboardWithData() async {
        let dataService = MockHubDataService()
        let dashboard = HubDashboard(morningScore: 85, stepsCount: 7000, sleepHours: 7.5)
        dataService.dashboards = [dashboard]
        let scoreCalc = MockScoreCalculator()
        scoreCalc.streakToReturn = 3
        let aggregator = MockDomainAggregator()
        let snapshot = DomainSnapshot(domainRawValue: "health", score: 80)
        aggregator.snapshotsToReturn = [snapshot]
        let vm = DashboardViewModel(dataService: dataService, scoreCalculator: scoreCalc, aggregator: aggregator)
        await vm.loadDashboard()
        #expect(vm.dashboard != nil)
        #expect(vm.morningScore == 85)
        #expect(vm.stepsCount == 7000)
        #expect(vm.streak == 3)
        #expect(vm.snapshots.count == 1)
        #expect(vm.isLoading == false)
    }

    @Test("ダッシュボード読み込み - データなし")
    @MainActor func testLoadDashboardWithoutData() async {
        let vm = DashboardViewModel(
            dataService: MockHubDataService(),
            scoreCalculator: MockScoreCalculator(),
            aggregator: MockDomainAggregator()
        )
        await vm.loadDashboard()
        #expect(vm.dashboard == nil)
        #expect(vm.morningScore == 0)
    }

    @Test("ブリーフィング読み込み")
    @MainActor func testLoadBriefing() async {
        let dataService = MockHubDataService()
        let briefing = DailyBriefing(greeting: "おはよう!")
        dataService.briefings = [briefing]
        let vm = DashboardViewModel(
            dataService: dataService,
            scoreCalculator: MockScoreCalculator(),
            aggregator: MockDomainAggregator()
        )
        await vm.loadBriefing()
        #expect(vm.briefing != nil)
        #expect(vm.briefing?.greeting == "おはよう!")
    }

    @Test("データ更新")
    @MainActor func testRefreshData() async {
        let dataService = MockHubDataService()
        let dashboard = HubDashboard(morningScore: 70)
        dataService.dashboards = [dashboard]
        let briefing = DailyBriefing(greeting: "Hello")
        dataService.briefings = [briefing]
        let vm = DashboardViewModel(
            dataService: dataService,
            scoreCalculator: MockScoreCalculator(),
            aggregator: MockDomainAggregator()
        )
        await vm.refreshData()
        #expect(vm.dashboard != nil)
        #expect(vm.briefing != nil)
    }

    @Test("エラーハンドリング")
    @MainActor func testErrorHandling() async {
        let dataService = MockHubDataService()
        dataService.shouldThrowError = true
        let vm = DashboardViewModel(
            dataService: dataService,
            scoreCalculator: MockScoreCalculator(),
            aggregator: MockDomainAggregator()
        )
        await vm.loadDashboard()
        #expect(vm.error != nil)
        #expect(vm.isLoading == false)
    }

    @Test("isLoading状態遷移")
    @MainActor func testLoadingState() async {
        let vm = DashboardViewModel(
            dataService: MockHubDataService(),
            scoreCalculator: MockScoreCalculator(),
            aggregator: MockDomainAggregator()
        )
        #expect(vm.isLoading == false)
        await vm.loadDashboard()
        #expect(vm.isLoading == false)
    }

    @Test("sleepHoursの反映")
    @MainActor func testSleepHours() async {
        let dataService = MockHubDataService()
        let dashboard = HubDashboard(sleepHours: 8.0)
        dataService.dashboards = [dashboard]
        let vm = DashboardViewModel(
            dataService: dataService,
            scoreCalculator: MockScoreCalculator(),
            aggregator: MockDomainAggregator()
        )
        await vm.loadDashboard()
        #expect(abs(vm.sleepHours - 8.0) < 0.0001)
    }

    @Test("スナップショットの反映")
    @MainActor func testSnapshotsLoaded() async {
        let aggregator = MockDomainAggregator()
        let s1 = DomainSnapshot(domainRawValue: "morning", score: 90)
        let s2 = DomainSnapshot(domainRawValue: "health", score: 80)
        aggregator.snapshotsToReturn = [s1, s2]
        let vm = DashboardViewModel(
            dataService: MockHubDataService(),
            scoreCalculator: MockScoreCalculator(),
            aggregator: aggregator
        )
        await vm.loadDashboard()
        #expect(vm.snapshots.count == 2)
    }

    @Test("ストリーク計算")
    @MainActor func testStreakCalculation() async {
        let scoreCalc = MockScoreCalculator()
        scoreCalc.streakToReturn = 10
        let vm = DashboardViewModel(
            dataService: MockHubDataService(),
            scoreCalculator: scoreCalc,
            aggregator: MockDomainAggregator()
        )
        await vm.loadDashboard()
        #expect(vm.streak == 10)
    }

    @Test("ブリーフィングエラー")
    @MainActor func testBriefingError() async {
        let dataService = MockHubDataService()
        dataService.shouldThrowError = true
        let vm = DashboardViewModel(
            dataService: dataService,
            scoreCalculator: MockScoreCalculator(),
            aggregator: MockDomainAggregator()
        )
        await vm.loadBriefing()
        #expect(vm.error != nil)
    }

    @Test("エラーリセット")
    @MainActor func testErrorReset() async {
        let dataService = MockHubDataService()
        dataService.shouldThrowError = true
        let vm = DashboardViewModel(
            dataService: dataService,
            scoreCalculator: MockScoreCalculator(),
            aggregator: MockDomainAggregator()
        )
        await vm.loadDashboard()
        #expect(vm.error != nil)
        dataService.shouldThrowError = false
        await vm.loadDashboard()
        #expect(vm.error == nil)
    }
}
