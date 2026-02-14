import Foundation
@testable import AsaLifeLogKit

// MARK: - MockDataService

/// テスト用のモックデータサービス
@MainActor
final class MockDataService: LifeLogDataServiceProtocol {
    var entries: [LifeLogEntry] = []
    var dailySummaries: [DailySummary] = []
    var weeklySummaries: [WeeklySummary] = []
    var places: [PlaceLog] = []
    var preferences: UserPreferences = UserPreferences()

    // 呼び出し記録
    var saveEntryCalled = false
    var deleteEntryCalled = false
    var toggleFavoriteCalled = false
    var saveDailySummaryCalled = false
    var saveWeeklySummaryCalled = false
    var savePlaceLogCalled = false
    var savePreferencesCalled = false
    var shouldThrowError = false

    func fetchEntries(for date: Date) async throws -> [LifeLogEntry] {
        if shouldThrowError { throw LifeLogError.dataNotFound }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        return entries.filter { $0.timestamp >= startOfDay && $0.timestamp < endOfDay }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func fetchEntries(from startDate: Date, to endDate: Date) async throws -> [LifeLogEntry] {
        if shouldThrowError { throw LifeLogError.dataNotFound }
        return entries.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func fetchEntries(source: DataSource) async throws -> [LifeLogEntry] {
        if shouldThrowError { throw LifeLogError.dataNotFound }
        return entries.filter { $0.source == source }
    }

    func saveEntry(_ entry: LifeLogEntry) async throws {
        if shouldThrowError { throw LifeLogError.saveFailed(underlying: NSError(domain: "test", code: 0)) }
        saveEntryCalled = true
        if !entries.contains(where: { $0.id == entry.id }) {
            entries.append(entry)
        }
    }

    func deleteEntry(_ entry: LifeLogEntry) async throws {
        if shouldThrowError { throw LifeLogError.dataNotFound }
        deleteEntryCalled = true
        entries.removeAll { $0.id == entry.id }
    }

    func toggleFavorite(_ entry: LifeLogEntry) async throws {
        if shouldThrowError { throw LifeLogError.saveFailed(underlying: NSError(domain: "test", code: 0)) }
        toggleFavoriteCalled = true
        entry.isFavorite.toggle()
    }

    func fetchDailySummary(for date: Date) async throws -> DailySummary? {
        if shouldThrowError { throw LifeLogError.dataNotFound }
        return dailySummaries.first
    }

    func saveDailySummary(_ summary: DailySummary) async throws {
        if shouldThrowError { throw LifeLogError.saveFailed(underlying: NSError(domain: "test", code: 0)) }
        saveDailySummaryCalled = true
        dailySummaries.append(summary)
    }

    func fetchWeeklySummary(for weekStart: Date) async throws -> WeeklySummary? {
        if shouldThrowError { throw LifeLogError.dataNotFound }
        return weeklySummaries.first
    }

    func saveWeeklySummary(_ summary: WeeklySummary) async throws {
        if shouldThrowError { throw LifeLogError.saveFailed(underlying: NSError(domain: "test", code: 0)) }
        saveWeeklySummaryCalled = true
        weeklySummaries.append(summary)
    }

    func fetchPlaces() async throws -> [PlaceLog] {
        if shouldThrowError { throw LifeLogError.dataNotFound }
        return places
    }

    func savePlaceLog(_ place: PlaceLog) async throws {
        if shouldThrowError { throw LifeLogError.saveFailed(underlying: NSError(domain: "test", code: 0)) }
        savePlaceLogCalled = true
        if !places.contains(where: { $0.id == place.id }) {
            places.append(place)
        }
    }

    func fetchOrCreatePreferences() async throws -> UserPreferences {
        if shouldThrowError { throw LifeLogError.dataNotFound }
        return preferences
    }

    func savePreferences(_ preferences: UserPreferences) async throws {
        if shouldThrowError { throw LifeLogError.saveFailed(underlying: NSError(domain: "test", code: 0)) }
        savePreferencesCalled = true
        self.preferences = preferences
    }
}
