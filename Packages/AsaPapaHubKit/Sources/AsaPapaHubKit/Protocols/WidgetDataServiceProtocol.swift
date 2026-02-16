import Foundation

// MARK: - ウィジェットデータサービスプロトコル

public protocol WidgetDataServiceProtocol: Sendable {
    func updateWidgetData(dashboard: HubDashboard, routine: MorningRoutine?) async throws
    func getWidgetData() -> Data?
}
