import Foundation

// MARK: - スコア計算

public final class ScoreCalculator: ScoreCalculatorProtocol, Sendable {
    public init() {}

    public func calculateMorningScore(routine: MorningRoutine) -> Int {
        guard !routine.items.isEmpty else { return 0 }
        let completionRate = routine.completionRate
        var score = Int(completionRate * 80.0)

        // 時間ボーナス: 目標時間内に完了した場合 +20点
        if let actual = routine.actualDurationMinutes {
            if actual <= routine.targetDurationMinutes {
                score += 20
            } else {
                let overageRatio = Double(actual - routine.targetDurationMinutes) / Double(routine.targetDurationMinutes)
                score += max(0, 20 - Int(overageRatio * 20.0))
            }
        }
        return min(100, max(0, score))
    }

    public func calculateDomainScore(domain: LifeDomain, snapshot: DomainSnapshot) -> Int {
        min(100, max(0, snapshot.score))
    }

    public func calculateOverallProgress(dashboards: [HubDashboard]) -> Double {
        guard !dashboards.isEmpty else { return 0.0 }
        let total = dashboards.reduce(0.0) { $0 + $1.overallProgress }
        return total / Double(dashboards.count)
    }

    public func calculateStreak(dashboards: [HubDashboard]) -> Int {
        let calendar = Calendar.current
        let sorted = dashboards.sorted { $0.date > $1.date }
        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        for dashboard in sorted {
            let dashboardDate = calendar.startOfDay(for: dashboard.date)
            if dashboardDate == expectedDate && dashboard.morningScore > 0 {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if dashboardDate < expectedDate {
                break
            }
        }
        return streak
    }
}
