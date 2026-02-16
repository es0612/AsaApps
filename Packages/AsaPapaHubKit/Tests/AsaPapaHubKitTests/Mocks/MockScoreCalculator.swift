import Foundation
@testable import AsaPapaHubKit

final class MockScoreCalculator: ScoreCalculatorProtocol, @unchecked Sendable {
    var morningScoreToReturn: Int = 80
    var domainScoreToReturn: Int = 75
    var overallProgressToReturn: Double = 0.7
    var streakToReturn: Int = 5

    func calculateMorningScore(routine: MorningRoutine) -> Int {
        morningScoreToReturn
    }

    func calculateDomainScore(domain: LifeDomain, snapshot: DomainSnapshot) -> Int {
        domainScoreToReturn
    }

    func calculateOverallProgress(dashboards: [HubDashboard]) -> Double {
        overallProgressToReturn
    }

    func calculateStreak(dashboards: [HubDashboard]) -> Int {
        streakToReturn
    }
}
