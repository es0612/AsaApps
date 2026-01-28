import XCTest

final class AsaStudyPlannerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // ダッシュボードタブが表示されることを確認
        XCTAssertTrue(app.tabBars.buttons["ダッシュボード"].exists)
        XCTAssertTrue(app.tabBars.buttons["学習項目"].exists)
        XCTAssertTrue(app.tabBars.buttons["セッション"].exists)
        XCTAssertTrue(app.tabBars.buttons["分析"].exists)
        XCTAssertTrue(app.tabBars.buttons["設定"].exists)
    }

    @MainActor
    func testNavigateToStudyItems() throws {
        let app = XCUIApplication()
        app.launch()

        // 学習項目タブに移動
        app.tabBars.buttons["学習項目"].tap()

        // ナビゲーションタイトルが表示されることを確認
        XCTAssertTrue(app.navigationBars["学習項目"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
