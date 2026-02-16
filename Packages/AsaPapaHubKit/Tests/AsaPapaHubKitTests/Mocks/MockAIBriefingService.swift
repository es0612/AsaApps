import Foundation
@testable import AsaPapaHubKit

@MainActor
final class MockAIBriefingService: AIBriefingServiceProtocol {
    var isAvailable: Bool = true
    var shouldThrowError = false

    func generateBriefing(for date: Date, dashboard: HubDashboard) async throws -> DailyBriefing {
        if shouldThrowError { throw PapaHubError.aiGenerationFailed("mock error") }
        return DailyBriefing(
            date: date,
            greeting: "おはようございます!",
            scheduleOverview: "今日も素晴らしい一日にしましょう",
            healthAdvice: "水分補給を忘れずに",
            motivationalMessage: "継続は力なり",
            statusRawValue: BriefingStatus.completed.rawValue
        )
    }

    func generateWeeklySummary(dashboards: [HubDashboard]) async throws -> WeeklySummary {
        if shouldThrowError { throw PapaHubError.aiGenerationFailed("mock error") }
        return WeeklySummary(
            summaryText: "今週も頑張りました",
            averageMorningScore: 80,
            statusRawValue: BriefingStatus.completed.rawValue
        )
    }
}
