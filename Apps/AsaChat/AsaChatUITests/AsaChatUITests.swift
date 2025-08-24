import XCTest

final class AsaChatUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Clean up
    }

    @MainActor
    func testAsaChatLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // アプリのタイトルが表示されることを確認
        XCTAssertTrue(app.navigationBars["AsaChat"].exists)
        
        // 入力フィールドが存在することを確認
        let messageTextField = app.textFields["メッセージを入力..."]
        XCTAssertTrue(messageTextField.exists)
        
        // 送信ボタンが存在することを確認
        let sendButton = app.buttons["送信"]
        XCTAssertTrue(sendButton.exists)
    }

    @MainActor
    func testSendMessage() throws {
        let app = XCUIApplication()
        app.launch()
        
        let messageTextField = app.textFields["メッセージを入力..."]
        let sendButton = app.buttons["送信"]
        
        // メッセージを入力
        messageTextField.tap()
        messageTextField.typeText("UIテストメッセージ")
        
        // 送信ボタンをタップ
        sendButton.tap()
        
        // メッセージが送信されたことを確認（入力フィールドがクリアされる）
        XCTAssertEqual(messageTextField.value as? String, "")
    }

    @MainActor
    func testMenuFunctionality() throws {
        let app = XCUIApplication()
        app.launch()
        
        // メニューボタンをタップ
        let menuButton = app.buttons.matching(identifier: "ellipsis.circle").firstMatch
        if menuButton.exists {
            menuButton.tap()
            
            // メニュー項目が表示されることを確認
            XCTAssertTrue(app.buttons["チャット履歴をクリア"].waitForExistence(timeout: 2))
        }
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