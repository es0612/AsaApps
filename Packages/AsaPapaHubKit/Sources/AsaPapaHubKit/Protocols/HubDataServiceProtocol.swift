import Foundation

// MARK: - ハブデータサービスプロトコル

@MainActor
public protocol HubDataServiceProtocol: Sendable {
    func fetchDashboard(for date: Date) async throws -> HubDashboard?
    func saveDashboard(_ dashboard: HubDashboard) async throws
    func fetchDashboards(from startDate: Date, to endDate: Date) async throws -> [HubDashboard]
    func fetchPreferences() async throws -> HubUserPreferences
    func savePreferences(_ prefs: HubUserPreferences) async throws
    func fetchSnapshots(for date: Date) async throws -> [DomainSnapshot]
    func saveSnapshot(_ snapshot: DomainSnapshot) async throws
    func fetchBriefing(for date: Date) async throws -> DailyBriefing?
    func saveBriefing(_ briefing: DailyBriefing) async throws
    func fetchWeeklySummary(for weekStart: Date) async throws -> WeeklySummary?
    func saveWeeklySummary(_ summary: WeeklySummary) async throws
    func fetchQuickActions() async throws -> [QuickAction]
    func saveQuickAction(_ action: QuickAction) async throws
}
