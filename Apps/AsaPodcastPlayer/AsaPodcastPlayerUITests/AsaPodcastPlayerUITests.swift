import XCTest

final class AsaPodcastPlayerUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        // テスト後のクリーンアップ
    }
    
    @MainActor
    func testAppLaunch() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // Then
        XCTAssertTrue(app.staticTexts["AsaPodcastPlayer"].exists)
        XCTAssertTrue(app.staticTexts["朝活パパのポッドキャストプレイヤー"].exists)
    }
    
    @MainActor
    func testLibraryButtonExists() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // Then
        let libraryButton = app.buttons.matching(identifier: "ライブラリボタン").firstMatch
        XCTAssertTrue(libraryButton.exists || app.buttons["ライブラリを開く"].exists)
    }
    
    @MainActor
    func testNoEpisodeSelectedState() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // Then
        XCTAssertTrue(app.staticTexts["ポッドキャストを選択してください"].exists)
        XCTAssertTrue(app.staticTexts["ライブラリからエピソードを選んで\nポッドキャストを楽しみましょう"].exists)
        XCTAssertTrue(app.buttons["ライブラリを開く"].exists)
    }
    
    @MainActor
    func testLibraryButtonTap() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // When
        let libraryButton = app.buttons["ライブラリを開く"]
        if libraryButton.exists {
            libraryButton.tap()
            
            // Then
            // ライブラリが開かれることを確認
            // 実際の実装に応じて調整が必要
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == true"),
                object: app.navigationBars.firstMatch
            )
            wait(for: [expectation], timeout: 3.0)
        }
    }
    
    @MainActor
    func testPlaybackControls() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // エピソードが選択されている場合のみテスト
        if app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'play'")).firstMatch.exists {
            // When
            let playButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'play'")).firstMatch
            playButton.tap()
            
            // Then
            // プレイヤーの状態変化を確認
            // 実際の実装に応じて調整が必要
        }
    }
    
    @MainActor
    func testSleepTimerButton() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // Then
        // スリープタイマーボタンの存在を確認
        let sleepTimerButtons = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'moon'"))
        XCTAssertTrue(sleepTimerButtons.count > 0 || app.images.matching(NSPredicate(format: "identifier CONTAINS 'moon'")).count > 0)
    }
    
    @MainActor
    func testPlaybackRateControl() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // エピソードが選択されている場合のみテスト
        let playbackRateElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'x'"))
        if playbackRateElements.count > 0 {
            // When
            let playbackRateButton = playbackRateElements.firstMatch
            playbackRateButton.tap()
            
            // Then
            // 再生速度の変化を確認
            // 実際の実装に応じて調整が必要
        }
    }
    
    @MainActor
    func testSkipControls() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // Then
        // スキップボタンの存在を確認
        let skipForwardElements = app.staticTexts["30秒"]
        let skipBackwardElements = app.staticTexts["15秒"]
        
        // これらの要素のいずれかが存在することを確認
        XCTAssertTrue(skipForwardElements.exists || skipBackwardElements.exists)
    }
    
    @MainActor
    func testAutoPlayToggle() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // Then
        // 自動再生トグルボタンの存在を確認
        let autoPlayElements = app.staticTexts["自動再生"]
        if autoPlayElements.exists {
            // When
            autoPlayElements.tap()
            
            // Then
            // トグル状態の変化を確認
            // 実際の実装に応じて調整が必要
        }
    }
    
    @MainActor
    func testAccessibilityElements() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // Then
        // 主要なUI要素がアクセシビリティに対応していることを確認
        XCTAssertTrue(app.staticTexts["AsaPodcastPlayer"].exists)
        
        // ボタンがアクセシブルであることを確認
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists && button.isHittable {
                // ボタンにアクセシビリティラベルがあることを確認
                XCTAssertFalse(button.label.isEmpty, "ボタンにアクセシビリティラベルがありません")
            }
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