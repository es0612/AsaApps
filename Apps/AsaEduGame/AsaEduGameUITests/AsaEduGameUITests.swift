import XCTest

final class AsaEduGameUITests: XCTestCase {
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssert(app.waitForExistence(timeout: 5))
    }
}
