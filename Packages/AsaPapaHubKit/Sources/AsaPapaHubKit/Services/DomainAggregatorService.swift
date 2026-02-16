import Foundation

// MARK: - ドメインアグリゲーターサービス

@MainActor
public final class DomainAggregatorService: DomainAggregatorProtocol {
    private let dataService: HubDataServiceProtocol

    public init(dataService: HubDataServiceProtocol) {
        self.dataService = dataService
    }

    public func aggregateSnapshots(for date: Date) async throws -> [DomainSnapshot] {
        let existing = try await dataService.fetchSnapshots(for: date)
        guard !existing.isEmpty else {
            return LifeDomain.allCases.map { domain in
                DomainSnapshot(
                    date: date,
                    domainRawValue: domain.rawValue,
                    score: 0,
                    summary: "\(domain.displayName)のデータがありません",
                    trendRawValue: TrendDirection.stable.rawValue
                )
            }
        }
        return existing
    }

    public func aggregateWeeklyData(from startDate: Date, to endDate: Date) async throws -> [LifeDomain: [DomainSnapshot]] {
        var result: [LifeDomain: [DomainSnapshot]] = [:]
        let calendar = Calendar.current
        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        while current <= end {
            let snapshots = try await dataService.fetchSnapshots(for: current)
            for snapshot in snapshots {
                result[snapshot.domain, default: []].append(snapshot)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return result
    }
}
