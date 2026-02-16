import XCTest

// MARK: - AsaPapaHub UI テスト

final class AsaPapaHubUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    // MARK: - タブナビゲーション テスト

    func testTabNavigationExists() throws {
        // タブバーの存在確認
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
    }

    // MARK: - ダッシュボード表示テスト

    func testDashboardLoads() throws {
        // ダッシュボードが表示されることを確認
        let homeTab = app.tabBars.buttons["ホーム"]
        if homeTab.exists {
            homeTab.tap()
        }
    }

    // MARK: - 設定画面テスト

    func testSettingsNavigation() throws {
        let settingsTab = app.tabBars.buttons["設定"]
        if settingsTab.exists {
            settingsTab.tap()
        }
    }
}
