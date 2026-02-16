import Foundation
@testable import AsaPapaHubKit

@MainActor
final class MockDomainAggregator: DomainAggregatorProtocol {
    var snapshotsToReturn: [DomainSnapshot] = []
    var weeklyDataToReturn: [LifeDomain: [DomainSnapshot]] = [:]
    var shouldThrowError = false

    func aggregateSnapshots(for date: Date) async throws -> [DomainSnapshot] {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        return snapshotsToReturn
    }

    func aggregateWeeklyData(from startDate: Date, to endDate: Date) async throws -> [LifeDomain: [DomainSnapshot]] {
        if shouldThrowError { throw PapaHubError.fetchFailed("mock error") }
        return weeklyDataToReturn
    }
}
