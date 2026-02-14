import Foundation
import SwiftData

// MARK: - LifeLogDataService

/// SwiftData ベースのライフログデータ永続化サービス
@MainActor
public final class LifeLogDataService: LifeLogDataServiceProtocol {
    private let modelContext: ModelContext

    // MARK: - Init

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - エントリー

    public func fetchEntries(for date: Date) async throws -> [LifeLogEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        let descriptor = FetchDescriptor<LifeLogEntry>(
            predicate: #Predicate { $0.timestamp >= startOfDay && $0.timestamp < endOfDay },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchEntries(from startDate: Date, to endDate: Date) async throws -> [LifeLogEntry] {
        let descriptor = FetchDescriptor<LifeLogEntry>(
            predicate: #Predicate { $0.timestamp >= startDate && $0.timestamp <= endDate },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func fetchEntries(source: DataSource) async throws -> [LifeLogEntry] {
        let rawValue = source.rawValue
        let descriptor = FetchDescriptor<LifeLogEntry>(
            predicate: #Predicate { $0.sourceRawValue == rawValue },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func saveEntry(_ entry: LifeLogEntry) async throws {
        entry.updatedAt = Date()
        modelContext.insert(entry)
        try modelContext.save()
    }

    public func deleteEntry(_ entry: LifeLogEntry) async throws {
        modelContext.delete(entry)
        try modelContext.save()
    }

    public func toggleFavorite(_ entry: LifeLogEntry) async throws {
        entry.isFavorite.toggle()
        entry.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - 日次サマリー

    public func fetchDailySummary(for date: Date) async throws -> DailySummary? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }
        let descriptor = FetchDescriptor<DailySummary>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    public func saveDailySummary(_ summary: DailySummary) async throws {
        modelContext.insert(summary)
        try modelContext.save()
    }

    // MARK: - 週次サマリー

    public func fetchWeeklySummary(for weekStart: Date) async throws -> WeeklySummary? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: weekStart)
        guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfDay) else {
            return nil
        }
        let descriptor = FetchDescriptor<WeeklySummary>(
            predicate: #Predicate { $0.weekStartDate >= startOfDay && $0.weekStartDate < endOfWeek },
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    public func saveWeeklySummary(_ summary: WeeklySummary) async throws {
        modelContext.insert(summary)
        try modelContext.save()
    }

    // MARK: - 場所ログ

    public func fetchPlaces() async throws -> [PlaceLog] {
        let descriptor = FetchDescriptor<PlaceLog>(
            sortBy: [SortDescriptor(\.lastVisitedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    public func savePlaceLog(_ place: PlaceLog) async throws {
        modelContext.insert(place)
        try modelContext.save()
    }

    // MARK: - ユーザー設定

    public func fetchOrCreatePreferences() async throws -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let defaults = UserPreferences()
        modelContext.insert(defaults)
        try modelContext.save()
        return defaults
    }

    public func savePreferences(_ preferences: UserPreferences) async throws {
        modelContext.insert(preferences)
        try modelContext.save()
    }
}
