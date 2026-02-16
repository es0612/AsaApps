import Foundation

// MARK: - ウィジェットデータサービス

public final class WidgetDataService: WidgetDataServiceProtocol, Sendable {
    private let suiteName: String

    public init(suiteName: String = "group.com.asapapa.apps.asapapahub") {
        self.suiteName = suiteName
    }

    public func updateWidgetData(dashboard: HubDashboard, routine: MorningRoutine?) async throws {
        let widgetInfo: [String: Any] = [
            "morningScore": dashboard.morningScore,
            "stepsCount": dashboard.stepsCount,
            "sleepHours": dashboard.sleepHours,
            "overallProgress": dashboard.overallProgress,
            "routineCompleted": routine?.isCompleted ?? false,
            "routineCompletionRate": routine?.completionRate ?? 0.0,
            "updatedAt": Date().timeIntervalSince1970,
        ]
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw PapaHubError.widgetUpdateFailed("UserDefaults初期化に失敗")
        }
        let data = try JSONSerialization.data(withJSONObject: widgetInfo)
        defaults.set(data, forKey: "widgetData")
    }

    public func getWidgetData() -> Data? {
        UserDefaults(suiteName: suiteName)?.data(forKey: "widgetData")
    }
}
