import Foundation
@testable import AsaPapaHubKit

@MainActor
final class MockHubDataService: HubDataServiceProtocol {
    var dashboards: [HubDashboard] = []
    var preferences: HubUserPreferences?
    var snapshots: [DomainSnapshot] = []
    var briefings: [DailyBriefing] = []
    var weeklySummaries: [WeeklySummary] = []
    var quickActions: [QuickAction] = []
    var shouldThrowError = false

    func fetchDashboard(for date: Date) async throws -> HubDashboard? {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        let calendar = Calendar.current
        return dashboards.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func saveDashboard(_ dashboard: HubDashboard) async throws {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        dashboards.append(dashboard)
    }

    func fetchDashboards(from startDate: Date, to endDate: Date) async throws -> [HubDashboard] {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        return dashboards.filter { $0.date >= startDate && $0.date <= endDate }
    }

    func fetchPreferences() async throws -> HubUserPreferences {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        if let prefs = preferences { return prefs }
        let prefs = HubUserPreferences()
        preferences = prefs
        return prefs
    }

    func savePreferences(_ prefs: HubUserPreferences) async throws {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        preferences = prefs
    }

    func fetchSnapshots(for date: Date) async throws -> [DomainSnapshot] {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        let calendar = Calendar.current
        return snapshots.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func saveSnapshot(_ snapshot: DomainSnapshot) async throws {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        snapshots.append(snapshot)
    }

    func fetchBriefing(for date: Date) async throws -> DailyBriefing? {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        let calendar = Calendar.current
        return briefings.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func saveBriefing(_ briefing: DailyBriefing) async throws {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        briefings.append(briefing)
    }

    func fetchWeeklySummary(for weekStart: Date) async throws -> WeeklySummary? {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        let calendar = Calendar.current
        return weeklySummaries.first { calendar.isDate($0.weekStartDate, inSameDayAs: weekStart) }
    }

    func saveWeeklySummary(_ summary: WeeklySummary) async throws {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        weeklySummaries.append(summary)
    }

    func fetchQuickActions() async throws -> [QuickAction] {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        return quickActions
    }

    func saveQuickAction(_ action: QuickAction) async throws {
        if shouldThrowError { throw PapaHubError.saveFailed("mock error") }
        quickActions.append(action)
    }
}
