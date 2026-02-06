import Testing
@testable import AsaSmartReminderKit

// MARK: - MonitoringState テスト

@Suite("MonitoringState")
struct MonitoringStateTests {

    // MARK: - isMonitoring

    @Test("idle状態はモニタリングではない")
    func idleNotMonitoring() {
        #expect(MonitoringState.idle.isMonitoring == false)
    }

    @Test("starting状態はモニタリングではない")
    func startingNotMonitoring() {
        #expect(MonitoringState.starting.isMonitoring == false)
    }

    @Test("monitoring状態はモニタリング中")
    func monitoringIsMonitoring() {
        #expect(MonitoringState.monitoring(activeCount: 5).isMonitoring == true)
    }

    @Test("error状態はモニタリングではない")
    func errorNotMonitoring() {
        let state = MonitoringState.error(.locationPermissionDenied)
        #expect(state.isMonitoring == false)
    }

    // MARK: - activeCount

    @Test("monitoring状態のアクティブカウント")
    func monitoringActiveCount() {
        #expect(MonitoringState.monitoring(activeCount: 15).activeCount == 15)
    }

    @Test("idle状態のアクティブカウントは0")
    func idleActiveCount() {
        #expect(MonitoringState.idle.activeCount == 0)
    }

    // MARK: - displayText

    @Test("idle状態の表示テキスト")
    func idleDisplayText() {
        #expect(MonitoringState.idle.displayText == "停止中")
    }

    @Test("starting状態の表示テキスト")
    func startingDisplayText() {
        #expect(MonitoringState.starting.displayText == "開始中...")
    }

    @Test("monitoring状態の表示テキスト")
    func monitoringDisplayText() {
        #expect(MonitoringState.monitoring(activeCount: 5).displayText == "監視中（5/20）")
    }

    @Test("error状態の表示テキスト")
    func errorDisplayText() {
        let state = MonitoringState.error(.locationPermissionDenied)
        #expect(state.displayText.contains("位置情報の権限"))
    }

    // MARK: - MonitoringError displayText

    @Test("全エラーに表示テキストがある")
    func allErrorsHaveDisplayText() {
        let errors: [MonitoringError] = [
            .locationPermissionDenied,
            .notificationPermissionDenied,
            .monitorCreationFailed,
            .locationServicesDisabled,
            .unknown("テストエラー"),
        ]
        for error in errors {
            #expect(!error.displayText.isEmpty)
        }
    }

    @Test("unknownエラーにメッセージが含まれる")
    func unknownErrorMessage() {
        let error = MonitoringError.unknown("カスタムメッセージ")
        #expect(error.displayText == "カスタムメッセージ")
    }

    // MARK: - Equatable

    @Test("同じ状態の等価比較")
    func equalStates() {
        #expect(MonitoringState.idle == MonitoringState.idle)
        #expect(MonitoringState.monitoring(activeCount: 3) == MonitoringState.monitoring(activeCount: 3))
    }

    @Test("異なる状態の不等比較")
    func unequalStates() {
        #expect(MonitoringState.idle != MonitoringState.starting)
        #expect(MonitoringState.monitoring(activeCount: 3) != MonitoringState.monitoring(activeCount: 5))
    }
}
