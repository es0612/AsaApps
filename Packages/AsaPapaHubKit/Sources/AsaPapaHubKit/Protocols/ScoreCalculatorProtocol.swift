import Foundation

// MARK: - スコア計算プロトコル

public protocol ScoreCalculatorProtocol: Sendable {
    func calculateMorningScore(routine: MorningRoutine) -> Int
    func calculateDomainScore(domain: LifeDomain, snapshot: DomainSnapshot) -> Int
    func calculateOverallProgress(dashboards: [HubDashboard]) -> Double
    func calculateStreak(dashboards: [HubDashboard]) -> Int
}
