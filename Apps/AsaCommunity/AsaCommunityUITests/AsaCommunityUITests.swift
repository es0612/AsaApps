import XCTest

final class AsaCommunityUITests: XCTestCase {
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssert(app.tabBars.firstMatch.exists)
    }
}
