import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("SettingsViewModel テスト")
struct SettingsViewModelTests {
    @Test("初期状態")
    @MainActor func testInitialState() {
        let vm = SettingsViewModel(dataService: MockHubDataService())
        #expect(vm.preferences == nil)
        #expect(vm.isLoading == false)
        #expect(vm.error == nil)
    }

    @Test("設定読み込み")
    @MainActor func testLoadPreferences() async {
        let vm = SettingsViewModel(dataService: MockHubDataService())
        await vm.loadPreferences()
        #expect(vm.preferences != nil)
        #expect(vm.preferences?.stepsGoal == 10000)
    }

    @Test("設定保存")
    @MainActor func testSavePreferences() async {
        let dataService = MockHubDataService()
        let vm = SettingsViewModel(dataService: dataService)
        await vm.loadPreferences()
        vm.preferences?.stepsGoal = 15000
        await vm.savePreferences()
        #expect(dataService.preferences?.stepsGoal == 15000)
    }

    @Test("ドメイン切り替え - 追加")
    @MainActor func testToggleDomainAdd() async {
        let vm = SettingsViewModel(dataService: MockHubDataService())
        await vm.loadPreferences()
        vm.preferences?.enabledDomains = [.morning, .health]
        vm.toggleDomain(.learning)
        #expect(vm.preferences?.enabledDomains.contains(.learning) == true)
    }

    @Test("ドメイン切り替え - 削除")
    @MainActor func testToggleDomainRemove() async {
        let vm = SettingsViewModel(dataService: MockHubDataService())
        await vm.loadPreferences()
        vm.preferences?.enabledDomains = [.morning, .health, .learning]
        vm.toggleDomain(.health)
        #expect(vm.preferences?.enabledDomains.contains(.health) == false)
    }

    @Test("デフォルトにリセット")
    @MainActor func testResetToDefaults() async {
        let vm = SettingsViewModel(dataService: MockHubDataService())
        await vm.loadPreferences()
        vm.preferences?.stepsGoal = 20000
        vm.preferences?.aiEnabled = false
        await vm.resetToDefaults()
        #expect(vm.preferences?.stepsGoal == 10000)
        #expect(vm.preferences?.aiEnabled == true)
        #expect(abs((vm.preferences?.sleepGoalHours ?? 0) - 7.0) < 0.0001)
    }

    @Test("エラーハンドリング - 読み込み")
    @MainActor func testLoadError() async {
        let dataService = MockHubDataService()
        dataService.shouldThrowError = true
        let vm = SettingsViewModel(dataService: dataService)
        await vm.loadPreferences()
        #expect(vm.error != nil)
    }

    @Test("エラーハンドリング - 保存")
    @MainActor func testSaveError() async {
        let dataService = MockHubDataService()
        let vm = SettingsViewModel(dataService: dataService)
        await vm.loadPreferences()
        dataService.shouldThrowError = true
        await vm.savePreferences()
        #expect(vm.error != nil)
    }

    @Test("preferencesなしでの保存は無操作")
    @MainActor func testSaveWithoutPreferences() async {
        let vm = SettingsViewModel(dataService: MockHubDataService())
        await vm.savePreferences()
        #expect(vm.error == nil)
    }
}
