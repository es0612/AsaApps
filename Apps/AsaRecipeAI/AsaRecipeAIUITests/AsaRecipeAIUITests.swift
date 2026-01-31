//
//  AsaRecipeAIUITests.swift
//  AsaRecipeAIUITests
//
//  AsaRecipeAI のUIテスト
//

import XCTest

final class AsaRecipeAIUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // ホームタブが表示されることを確認
        XCTAssertTrue(app.tabBars.buttons["ホーム"].exists)
    }

    @MainActor
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // 各タブに移動できることを確認
        app.tabBars.buttons["お気に入り"].tap()
        XCTAssertTrue(app.navigationBars["お気に入り"].exists)

        app.tabBars.buttons["履歴"].tap()
        XCTAssertTrue(app.navigationBars["履歴"].exists)

        app.tabBars.buttons["設定"].tap()
        XCTAssertTrue(app.navigationBars["設定"].exists)

        app.tabBars.buttons["ホーム"].tap()
        XCTAssertTrue(app.navigationBars["AsaRecipeAI"].exists)
    }

    @MainActor
    func testHomeViewElements() throws {
        let app = XCUIApplication()
        app.launch()

        // ホーム画面の主要要素が存在することを確認
        XCTAssertTrue(app.staticTexts["食材を撮影してレシピを発見"].exists)
        XCTAssertTrue(app.staticTexts["写真を選択"].exists)
    }

    @MainActor
    func testSettingsView() throws {
        let app = XCUIApplication()
        app.launch()

        // 設定タブに移動
        app.tabBars.buttons["設定"].tap()

        // 設定項目が存在することを確認
        XCTAssertTrue(app.staticTexts["Foundation Models"].exists)
        XCTAssertTrue(app.staticTexts["レシピ生成"].exists)
        XCTAssertTrue(app.staticTexts["食事制限"].exists)
        XCTAssertTrue(app.staticTexts["アプリ情報"].exists)
    }

    @MainActor
    func testEmptyFavoritesState() throws {
        let app = XCUIApplication()
        app.launch()

        // お気に入りタブに移動
        app.tabBars.buttons["お気に入り"].tap()

        // 空状態のメッセージが表示されることを確認
        XCTAssertTrue(app.staticTexts["お気に入りがありません"].exists)
    }

    @MainActor
    func testEmptyHistoryState() throws {
        let app = XCUIApplication()
        app.launch()

        // 履歴タブに移動
        app.tabBars.buttons["履歴"].tap()

        // 空状態のメッセージが表示されることを確認
        XCTAssertTrue(app.staticTexts["履歴がありません"].exists)
    }
}
