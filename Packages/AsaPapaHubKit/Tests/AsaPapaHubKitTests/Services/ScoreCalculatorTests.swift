import Testing
import Foundation
@testable import AsaPapaHubKit

@Suite("ScoreCalculator テスト")
struct ScoreCalculatorTests {
    let calculator = ScoreCalculator()

    @Test("朝活スコア - アイテムなし")
    func testMorningScoreEmpty() {
        let routine = MorningRoutine()
        let score = calculator.calculateMorningScore(routine: routine)
        #expect(score == 0)
    }

    @Test("朝活スコア - 全完了 + 時間内")
    func testMorningScoreFullCompletion() {
        let routine = MorningRoutine(targetDurationMinutes: 60)
        let item1 = MorningRoutineItem(title: "A", order: 0, statusRawValue: "completed")
        let item2 = MorningRoutineItem(title: "B", order: 1, statusRawValue: "completed")
        routine.items = [item1, item2]
        let start = Date()
        routine.startTime = start
        routine.endTime = start.addingTimeInterval(45 * 60)
        let score = calculator.calculateMorningScore(routine: routine)
        #expect(score == 100)
    }

    @Test("朝活スコア - 半分完了")
    func testMorningScoreHalfCompletion() {
        let routine = MorningRoutine()
        let item1 = MorningRoutineItem(title: "A", order: 0, statusRawValue: "completed")
        let item2 = MorningRoutineItem(title: "B", order: 1, statusRawValue: "pending")
        routine.items = [item1, item2]
        let score = calculator.calculateMorningScore(routine: routine)
        #expect(score == 40) // 0.5 * 80 = 40, 時間ボーナスなし
    }

    @Test("朝活スコア - 時間超過")
    func testMorningScoreOvertime() {
        let routine = MorningRoutine(targetDurationMinutes: 60)
        let item1 = MorningRoutineItem(title: "A", order: 0, statusRawValue: "completed")
        routine.items = [item1]
        let start = Date()
        routine.startTime = start
        routine.endTime = start.addingTimeInterval(90 * 60) // 90分（目標60分）
        let score = calculator.calculateMorningScore(routine: routine)
        #expect(score >= 70 && score <= 100)
    }

    @Test("ドメインスコア - 範囲制限")
    func testDomainScoreRange() {
        let snapshot = DomainSnapshot(score: 150) // 100超
        let score = calculator.calculateDomainScore(domain: .health, snapshot: snapshot)
        #expect(score == 100)

        let snapshotNeg = DomainSnapshot(score: -10)
        let scoreNeg = calculator.calculateDomainScore(domain: .health, snapshot: snapshotNeg)
        #expect(scoreNeg == 0)
    }

    @Test("全体進捗 - 空")
    func testOverallProgressEmpty() {
        let progress = calculator.calculateOverallProgress(dashboards: [])
        #expect(abs(progress - 0.0) < 0.0001)
    }

    @Test("全体進捗 - 複数ダッシュボード")
    func testOverallProgressMultiple() {
        let d1 = HubDashboard(overallProgress: 0.8)
        let d2 = HubDashboard(overallProgress: 0.6)
        let progress = calculator.calculateOverallProgress(dashboards: [d1, d2])
        #expect(abs(progress - 0.7) < 0.0001)
    }

    @Test("ストリーク - 空")
    func testStreakEmpty() {
        let streak = calculator.calculateStreak(dashboards: [])
        #expect(streak == 0)
    }

    @Test("ストリーク - 連続日数")
    func testStreakConsecutive() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let d1 = HubDashboard(date: today, morningScore: 80)
        let d2 = HubDashboard(date: yesterday, morningScore: 70)
        let streak = calculator.calculateStreak(dashboards: [d1, d2])
        #expect(streak == 2)
    }

    @Test("ストリーク - 途切れ")
    func testStreakBroken() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let d1 = HubDashboard(date: today, morningScore: 0) // スコア0は途切れ
        let streak = calculator.calculateStreak(dashboards: [d1])
        #expect(streak == 0)
    }
}
