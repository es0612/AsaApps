import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("SafetyReport モデルテスト")
struct SafetyReportTests {

    @Test("初期化テスト - デフォルト値が正しく設定される")
    func testInitialization() {
        let report = SafetyReport(title: "不審者情報", alertLevel: .warning)
        #expect(report.title == "不審者情報")
        #expect(report.alertLevel == .warning)
        #expect(report.isResolved == false)
        #expect(report.resolvedAt == nil)
    }

    @Test("alertLevel アクセサ - rawValue 経由で正しく変換される")
    func testAlertLevelAccessor() {
        let report = SafetyReport(title: "テスト", alertLevel: .emergency)
        #expect(report.alertLevel == .emergency)
        #expect(report.alertLevelRawValue == "緊急")

        report.alertLevel = .caution
        #expect(report.alertLevel == .caution)
        #expect(report.alertLevelRawValue == "注意")
    }

    @Test("alertLevel アクセサ - 不正な rawValue はデフォルトを返す")
    func testAlertLevelAccessorInvalidRawValue() {
        let report = SafetyReport(title: "テスト")
        report.alertLevelRawValue = "不正な値"
        #expect(report.alertLevel == .info)
    }

    @Test("isActiveAlert - 未解決かつ警告以上で true を返す")
    func testIsActiveAlertTrue() {
        let report = SafetyReport(title: "緊急警告", alertLevel: .warning)
        #expect(report.isActiveAlert == true)

        let emergency = SafetyReport(title: "緊急", alertLevel: .emergency)
        #expect(emergency.isActiveAlert == true)
    }

    @Test("isActiveAlert - 解決済みなら false を返す")
    func testIsActiveAlertResolved() {
        let report = SafetyReport(title: "解決済み", alertLevel: .warning)
        report.isResolved = true
        #expect(report.isActiveAlert == false)
    }

    @Test("isActiveAlert - 注意以下なら false を返す")
    func testIsActiveAlertLowLevel() {
        let info = SafetyReport(title: "お知らせ", alertLevel: .info)
        #expect(info.isActiveAlert == false)

        let caution = SafetyReport(title: "注意", alertLevel: .caution)
        #expect(caution.isActiveAlert == false)
    }

    @Test("SafetyAlertLevel の比較が正しく動作する")
    func testAlertLevelComparison() {
        #expect(SafetyAlertLevel.info < SafetyAlertLevel.caution)
        #expect(SafetyAlertLevel.caution < SafetyAlertLevel.warning)
        #expect(SafetyAlertLevel.warning < SafetyAlertLevel.emergency)
        #expect(SafetyAlertLevel.warning >= SafetyAlertLevel.warning)
    }
}
