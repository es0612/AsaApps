import Foundation
import SwiftData
import Testing

@testable import AsaFinancePlannerKit

// MARK: - FinanceDataServiceTests

/// SwiftData の inMemory テストは macOS のSPMテストランナーで
/// 並行実行時にクラッシュするため、.serialized で実行する。
@Suite("FinanceDataService テスト", .serialized)
struct FinanceDataServiceTests {

    // MARK: - Plan CRUD

    @Test("プラン作成・取得")
    @MainActor
    func testCreateAndFetchPlan() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "テストプラン")
        try service.savePlan(plan)

        let plans = try service.fetchPlans()
        #expect(plans.count == 1)
        #expect(plans.first?.name == "テストプラン")
    }

    @Test("アクティブプラン取得")
    @MainActor
    func testFetchActivePlan() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan1 = FinancialPlan(name: "プラン1")
        plan1.isActive = true
        try service.savePlan(plan1)

        let plan2 = FinancialPlan(name: "プラン2")
        plan2.isActive = false
        try service.savePlan(plan2)

        let activePlan = try service.fetchActivePlan()
        #expect(activePlan?.name == "プラン1")
    }

    @Test("プラン削除")
    @MainActor
    func testDeletePlan() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "削除対象")
        try service.savePlan(plan)
        #expect(try service.fetchPlans().count == 1)

        try service.deletePlan(plan)
        #expect(try service.fetchPlans().count == 0)
    }

    // MARK: - Goal CRUD

    @Test("ゴールの追加")
    @MainActor
    func testAddGoal() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "テストプラン")
        try service.savePlan(plan)

        let goal = FinancialGoal(
            name: "教育資金",
            targetAmount: Decimal(5_000_000),
            targetDate: Date()
        )
        try service.addGoal(goal, to: plan)

        #expect(plan.goals.count == 1)
        #expect(plan.goals.first?.name == "教育資金")
    }

    @Test("ゴールの削除")
    @MainActor
    func testDeleteGoal() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "テストプラン")
        try service.savePlan(plan)

        let goal = FinancialGoal(
            name: "削除目標",
            targetAmount: Decimal(1_000_000),
            targetDate: Date()
        )
        try service.addGoal(goal, to: plan)
        #expect(plan.goals.count == 1)

        try service.deleteGoal(goal)
        #expect(plan.goals.count == 0)
    }

    // MARK: - Asset CRUD

    @Test("資産の追加")
    @MainActor
    func testAddAsset() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "テストプラン")
        try service.savePlan(plan)

        let asset = Asset(
            name: "国内株式投信",
            assetClass: .domesticStock,
            currentValue: Decimal(3_000_000)
        )
        try service.addAsset(asset, to: plan)

        #expect(plan.assets.count == 1)
        #expect(plan.assets.first?.name == "国内株式投信")
    }

    @Test("資産の削除")
    @MainActor
    func testDeleteAsset() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "テストプラン")
        try service.savePlan(plan)

        let asset = Asset(name: "現金", assetClass: .cash, currentValue: Decimal(1_000_000))
        try service.addAsset(asset, to: plan)
        #expect(plan.assets.count == 1)

        try service.deleteAsset(asset)
        #expect(plan.assets.count == 0)
    }

    // MARK: - Contribution CRUD

    @Test("積立の追加")
    @MainActor
    func testAddContribution() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "テストプラン")
        try service.savePlan(plan)

        let contribution = Contribution(
            name: "つみたてNISA",
            monthlyAmount: Decimal(33333),
            assetClass: .domesticStock
        )
        try service.addContribution(contribution, to: plan)

        #expect(plan.contributions.count == 1)
        #expect(plan.contributions.first?.name == "つみたてNISA")
    }

    @Test("積立の削除")
    @MainActor
    func testDeleteContribution() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "テストプラン")
        try service.savePlan(plan)

        let contribution = Contribution(name: "テスト積立", monthlyAmount: Decimal(10000))
        try service.addContribution(contribution, to: plan)
        #expect(plan.contributions.count == 1)

        try service.deleteContribution(contribution)
        #expect(plan.contributions.count == 0)
    }

    // MARK: - Scenario CRUD

    @Test("シナリオの追加")
    @MainActor
    func testAddScenario() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "テストプラン")
        try service.savePlan(plan)

        let scenario = Scenario(name: "楽観シナリオ")
        try service.addScenario(scenario, to: plan)

        #expect(plan.scenarios.count == 1)
        #expect(plan.scenarios.first?.name == "楽観シナリオ")
    }

    @Test("シナリオの削除")
    @MainActor
    func testDeleteScenario() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let plan = FinancialPlan(name: "テストプラン")
        try service.savePlan(plan)

        let scenario = Scenario(name: "削除シナリオ")
        try service.addScenario(scenario, to: plan)
        #expect(plan.scenarios.count == 1)

        try service.deleteScenario(scenario)
        #expect(plan.scenarios.count == 0)
    }

    // MARK: - Settings

    @Test("設定の保存・取得")
    @MainActor
    func testSaveAndFetchSettings() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let settings = UserSettings(
            currentAge: 40,
            retirementAge: 60,
            monthlyLivingExpense: Decimal(300000)
        )
        try service.saveSettings(settings)

        let fetched = try service.fetchSettings()
        #expect(fetched.currentAge == 40)
        #expect(fetched.retirementAge == 60)
        #expect(fetched.monthlyLivingExpense == Decimal(300000))
    }

    @Test("設定が未保存ならデフォルト設定を返す")
    @MainActor
    func testFetchDefaultSettings() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        let settings = try service.fetchSettings()
        #expect(settings.currentAge == 30)
        #expect(settings.retirementAge == 65)
    }

    // MARK: - Save

    @Test("save メソッドが例外を投げない")
    @MainActor
    func testSaveDoesNotThrow() throws {
        let container = try ModelContainer(
            for: FinancialPlan.self, FinancialGoal.self, Asset.self,
            Contribution.self, Scenario.self, UserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let service = FinanceDataService(modelContext: container.mainContext)

        #expect(throws: Never.self) {
            try service.save()
        }
    }
}
