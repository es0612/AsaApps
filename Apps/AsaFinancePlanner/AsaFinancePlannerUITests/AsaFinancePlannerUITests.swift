import XCTest

final class AsaFinancePlannerUITests: XCTestCase {
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
