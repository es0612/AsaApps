import XCTest

final class AsaSmartReminderUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // アプリが正常に起動することを確認
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
