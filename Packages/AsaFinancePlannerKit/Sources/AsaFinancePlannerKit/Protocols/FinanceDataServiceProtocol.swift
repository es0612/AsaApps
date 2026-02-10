import Foundation
import SwiftData

// MARK: - FinanceDataServiceProtocol

/// 金融データの永続化サービスプロトコル
@MainActor
public protocol FinanceDataServiceProtocol {
    // MARK: - Plan CRUD

    func fetchPlans() throws -> [FinancialPlan]
    func fetchActivePlan() throws -> FinancialPlan?
    func savePlan(_ plan: FinancialPlan) throws
    func deletePlan(_ plan: FinancialPlan) throws

    // MARK: - Goal CRUD

    func addGoal(_ goal: FinancialGoal, to plan: FinancialPlan) throws
    func deleteGoal(_ goal: FinancialGoal) throws

    // MARK: - Asset CRUD

    func addAsset(_ asset: Asset, to plan: FinancialPlan) throws
    func deleteAsset(_ asset: Asset) throws

    // MARK: - Contribution CRUD

    func addContribution(_ contribution: Contribution, to plan: FinancialPlan) throws
    func deleteContribution(_ contribution: Contribution) throws

    // MARK: - Scenario CRUD

    func addScenario(_ scenario: Scenario, to plan: FinancialPlan) throws
    func deleteScenario(_ scenario: Scenario) throws

    // MARK: - Settings

    func fetchSettings() throws -> UserSettings
    func saveSettings(_ settings: UserSettings) throws

    // MARK: - Save

    func save() throws
}
