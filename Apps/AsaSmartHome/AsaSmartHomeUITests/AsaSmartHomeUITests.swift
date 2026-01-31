import XCTest

final class AsaSmartHomeUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // テスト後のクリーンアップ
    }

    // MARK: - Tab Navigation Tests

    func testTabNavigation() throws {
        // ダッシュボードタブが表示されていることを確認
        XCTAssertTrue(app.tabBars.buttons["ダッシュボード"].exists)
        XCTAssertTrue(app.tabBars.buttons["部屋"].exists)
        XCTAssertTrue(app.tabBars.buttons["シーン"].exists)
        XCTAssertTrue(app.tabBars.buttons["設定"].exists)

        // 各タブに移動
        app.tabBars.buttons["部屋"].tap()
        XCTAssertTrue(app.navigationBars["部屋"].waitForExistence(timeout: 5))

        app.tabBars.buttons["シーン"].tap()
        XCTAssertTrue(app.navigationBars["シーン"].waitForExistence(timeout: 5))

        app.tabBars.buttons["設定"].tap()
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5))

        app.tabBars.buttons["ダッシュボード"].tap()
        XCTAssertTrue(app.navigationBars["スマートホーム"].waitForExistence(timeout: 5))
    }

    // MARK: - Dashboard Tests

    func testDashboardLoads() throws {
        // ダッシュボードのナビゲーションバーが表示されるまで待機
        let navBar = app.navigationBars["スマートホーム"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 10))
    }

    // MARK: - Settings Tests

    func testSettingsView() throws {
        // 設定タブに移動
        app.tabBars.buttons["設定"].tap()

        // 設定画面が表示されることを確認
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5))

        // 基本的な設定項目が表示されていることを確認
        XCTAssertTrue(app.staticTexts["一般"].exists || app.cells.count > 0)
    }
}
