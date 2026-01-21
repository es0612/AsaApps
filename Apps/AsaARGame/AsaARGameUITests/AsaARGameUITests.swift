import XCTest

// MARK: - AsaARGameUITests
/// ARゲームのUIテスト
/// 注: ARKitは実機でのみ動作するため、シミュレータでのテストは限定的
final class AsaARGameUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch Tests

    func testAppLaunches() throws {
        app.launch()

        // アプリが起動することを確認
        XCTAssertTrue(app.exists)
    }

    // MARK: - Onboarding Tests

    func testOnboardingDisplaysOnFirstLaunch() throws {
        // UserDefaultsをリセット
        app.launchArguments = ["-AsaARGame_HasCompletedOnboarding", "NO"]
        app.launch()

        // オンボーディング画面が表示されることを確認
        // 注: 実際の要素名は実装に応じて調整が必要
        let onboardingTitle = app.staticTexts["的当てゲーム"]
        XCTAssertTrue(onboardingTitle.waitForExistence(timeout: 5))
    }

    func testOnboardingNavigation() throws {
        app.launchArguments = ["-AsaARGame_HasCompletedOnboarding", "NO"]
        app.launch()

        // 「次へ」ボタンをタップ
        let nextButton = app.buttons["次へ"]
        if nextButton.waitForExistence(timeout: 5) {
            nextButton.tap()

            // 2ページ目の確認
            let secondPageTitle = app.staticTexts["平面を検出"]
            XCTAssertTrue(secondPageTitle.waitForExistence(timeout: 3))
        }
    }

    // MARK: - Note
    // AR関連のテストは実機でのみ実行可能です。
    // シミュレータでは平面検出やターゲット生成のテストは行えません。
}
