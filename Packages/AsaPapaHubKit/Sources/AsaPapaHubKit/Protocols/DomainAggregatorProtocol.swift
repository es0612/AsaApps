import Foundation

// MARK: - ドメインアグリゲータープロトコル

@MainActor
public protocol DomainAggregatorProtocol: Sendable {
    func aggregateSnapshots(for date: Date) async throws -> [DomainSnapshot]
    func aggregateWeeklyData(from startDate: Date, to endDate: Date) async throws -> [LifeDomain: [DomainSnapshot]]
}
