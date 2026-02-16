import Foundation
import SwiftData

// MARK: - ハブデータサービス

@MainActor
public final class HubDataService: HubDataServiceProtocol {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Dashboard

    public func fetchDashboard(for date: Date) async throws -> HubDashboard? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<HubDashboard>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    public func saveDashboard(_ dashboard: HubDashboard) async throws {
        modelContext.insert(dashboard)
        try modelContext.save()
    }

    public func fetchDashboards(from startDate: Date, to endDate: Date) async throws -> [HubDashboard] {
        let descriptor = FetchDescriptor<HubDashboard>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Preferences

    public func fetchPreferences() async throws -> HubUserPreferences {
        let descriptor = FetchDescriptor<HubUserPreferences>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let prefs = HubUserPreferences()
        modelContext.insert(prefs)
        try modelContext.save()
        return prefs
    }

    public func savePreferences(_ prefs: HubUserPreferences) async throws {
        prefs.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Snapshots

    public func fetchSnapshots(for date: Date) async throws -> [DomainSnapshot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<DomainSnapshot>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay },
            sortBy: [SortDescriptor(\.domainRawValue)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func saveSnapshot(_ snapshot: DomainSnapshot) async throws {
        modelContext.insert(snapshot)
        try modelContext.save()
    }

    // MARK: - Briefing

    public func fetchBriefing(for date: Date) async throws -> DailyBriefing? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<DailyBriefing>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    public func saveBriefing(_ briefing: DailyBriefing) async throws {
        modelContext.insert(briefing)
        try modelContext.save()
    }

    // MARK: - Weekly Summary

    public func fetchWeeklySummary(for weekStart: Date) async throws -> WeeklySummary? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: weekStart)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<WeeklySummary>(
            predicate: #Predicate { $0.weekStartDate >= startOfDay && $0.weekStartDate < endOfDay },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    public func saveWeeklySummary(_ summary: WeeklySummary) async throws {
        modelContext.insert(summary)
        try modelContext.save()
    }

    // MARK: - Quick Actions

    public func fetchQuickActions() async throws -> [QuickAction] {
        let descriptor = FetchDescriptor<QuickAction>(
            sortBy: [SortDescriptor(\.order)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func saveQuickAction(_ action: QuickAction) async throws {
        modelContext.insert(action)
        try modelContext.save()
    }
}
