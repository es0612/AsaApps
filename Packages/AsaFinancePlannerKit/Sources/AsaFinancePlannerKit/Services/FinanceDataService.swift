import Foundation
import SwiftData

// MARK: - FinanceDataService

/// SwiftDataベースの金融データ永続化サービス
@MainActor
public final class FinanceDataService: FinanceDataServiceProtocol {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Plan CRUD

    public func fetchPlans() throws -> [FinancialPlan] {
        let descriptor = FetchDescriptor<FinancialPlan>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchActivePlan() throws -> FinancialPlan? {
        var descriptor = FetchDescriptor<FinancialPlan>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    public func savePlan(_ plan: FinancialPlan) throws {
        modelContext.insert(plan)
        try modelContext.save()
    }

    public func deletePlan(_ plan: FinancialPlan) throws {
        modelContext.delete(plan)
        try modelContext.save()
    }

    // MARK: - Goal CRUD

    public func addGoal(_ goal: FinancialGoal, to plan: FinancialPlan) throws {
        plan.goals.append(goal)
        plan.updatedAt = Date()
        try modelContext.save()
    }

    public func deleteGoal(_ goal: FinancialGoal) throws {
        if let plan = goal.plan {
            plan.goals.removeAll { $0.id == goal.id }
            plan.updatedAt = Date()
        }
        modelContext.delete(goal)
        try modelContext.save()
    }

    // MARK: - Asset CRUD

    public func addAsset(_ asset: Asset, to plan: FinancialPlan) throws {
        plan.assets.append(asset)
        plan.updatedAt = Date()
        try modelContext.save()
    }

    public func deleteAsset(_ asset: Asset) throws {
        if let plan = asset.plan {
            plan.assets.removeAll { $0.id == asset.id }
            plan.updatedAt = Date()
        }
        modelContext.delete(asset)
        try modelContext.save()
    }

    // MARK: - Contribution CRUD

    public func addContribution(_ contribution: Contribution, to plan: FinancialPlan) throws {
        plan.contributions.append(contribution)
        plan.updatedAt = Date()
        try modelContext.save()
    }

    public func deleteContribution(_ contribution: Contribution) throws {
        if let plan = contribution.plan {
            plan.contributions.removeAll { $0.id == contribution.id }
            plan.updatedAt = Date()
        }
        modelContext.delete(contribution)
        try modelContext.save()
    }

    // MARK: - Scenario CRUD

    public func addScenario(_ scenario: Scenario, to plan: FinancialPlan) throws {
        plan.scenarios.append(scenario)
        plan.updatedAt = Date()
        try modelContext.save()
    }

    public func deleteScenario(_ scenario: Scenario) throws {
        if let plan = scenario.plan {
            plan.scenarios.removeAll { $0.id == scenario.id }
            plan.updatedAt = Date()
        }
        modelContext.delete(scenario)
        try modelContext.save()
    }

    // MARK: - Settings

    public func fetchSettings() throws -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        // デフォルト設定を生成して保存
        let defaultSettings = UserSettings()
        modelContext.insert(defaultSettings)
        try modelContext.save()
        return defaultSettings
    }

    public func saveSettings(_ settings: UserSettings) throws {
        modelContext.insert(settings)
        try modelContext.save()
    }

    // MARK: - Save

    public func save() throws {
        try modelContext.save()
    }
}
