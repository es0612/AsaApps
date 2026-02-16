import Foundation

// MARK: - AIブリーフィングサービスプロトコル

@MainActor
public protocol AIBriefingServiceProtocol: Sendable {
    func generateBriefing(for date: Date, dashboard: HubDashboard) async throws -> DailyBriefing
    func generateWeeklySummary(dashboards: [HubDashboard]) async throws -> WeeklySummary
    var isAvailable: Bool { get }
}
