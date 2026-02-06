import Foundation
import Testing
@testable import AsaSmartReminderKit

// MARK: - UserLocationSettings テスト

@Suite("UserLocationSettings")
struct UserLocationSettingsTests {

    @Test("デフォルト値での初期化")
    func defaultInit() {
        let settings = UserLocationSettings()
        #expect(settings.defaultRadius == 100)
        #expect(settings.defaultTriggerOnEntry == true)
        #expect(settings.defaultTriggerOnExit == false)
        #expect(settings.hapticFeedbackEnabled == true)
    }

    @Test("カスタム値での初期化")
    func customInit() {
        let settings = UserLocationSettings(
            defaultRadius: 200,
            defaultTriggerOnEntry: false,
            defaultTriggerOnExit: true,
            hapticFeedbackEnabled: false
        )
        #expect(settings.defaultRadius == 200)
        #expect(settings.defaultTriggerOnEntry == false)
        #expect(settings.defaultTriggerOnExit == true)
        #expect(settings.hapticFeedbackEnabled == false)
    }

    @Test("createDefault でデフォルト設定を生成")
    func createDefault() {
        let settings = UserLocationSettings.createDefault()
        #expect(settings.defaultRadius == 100)
        #expect(settings.defaultTriggerOnEntry == true)
        #expect(settings.defaultTriggerOnExit == false)
        #expect(settings.hapticFeedbackEnabled == true)
    }

    @Test("プロパティの変更が反映される")
    func propertyMutation() {
        let settings = UserLocationSettings()
        settings.defaultRadius = 250
        settings.hapticFeedbackEnabled = false
        #expect(settings.defaultRadius == 250)
        #expect(settings.hapticFeedbackEnabled == false)
    }
}
