//
//  AsaVoiceAssistantUITests.swift
//  AsaVoiceAssistantUITests
//
//  UIテスト
//

import XCTest

/// AsaVoiceAssistantのUIテスト
///
/// 注意: 音声認識機能はシミュレーターでは完全にテストできません。
/// 実機でのテストが推奨されます。
final class AsaVoiceAssistantUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    /// アプリが正常に起動することを確認
    @MainActor
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // タブバーが表示されることを確認
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    /// 音声タブが表示されることを確認
    @MainActor
    func testVoiceTabExists() throws {
        let app = XCUIApplication()
        app.launch()

        // 音声タブボタンを確認
        let voiceTab = app.tabBars.buttons["音声"]
        XCTAssertTrue(voiceTab.exists)
    }

    /// タスクタブが表示されることを確認
    @MainActor
    func testTasksTabExists() throws {
        let app = XCUIApplication()
        app.launch()

        // タスクタブボタンを確認
        let tasksTab = app.tabBars.buttons["タスク"]
        XCTAssertTrue(tasksTab.exists)
    }

    /// 設定タブが表示されることを確認
    @MainActor
    func testSettingsTabExists() throws {
        let app = XCUIApplication()
        app.launch()

        // 設定タブボタンを確認
        let settingsTab = app.tabBars.buttons["設定"]
        XCTAssertTrue(settingsTab.exists)
    }

    /// タブ切り替えが正常に動作することを確認
    @MainActor
    func testTabSwitching() throws {
        let app = XCUIApplication()
        app.launch()

        // タスクタブに切り替え
        app.tabBars.buttons["タスク"].tap()

        // ナビゲーションタイトルを確認
        XCTAssertTrue(app.navigationBars["タスク一覧"].exists)

        // 設定タブに切り替え
        app.tabBars.buttons["設定"].tap()

        // ナビゲーションタイトルを確認
        XCTAssertTrue(app.navigationBars["設定"].exists)

        // 音声タブに戻る
        app.tabBars.buttons["音声"].tap()
    }
}
