//
//  AsaMultiplayerGameUITests.swift
//  AsaMultiplayerGameUITests
//
//  UIテスト
//

import XCTest

final class AsaMultiplayerGameUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // テスト後のクリーンアップ
    }

    @MainActor
    func testMainMenuDisplayed() throws {
        // Given
        let app = XCUIApplication()
        app.launch()

        // Then
        XCTAssertTrue(app.staticTexts["お絵かきバトル"].exists)
        XCTAssertTrue(app.buttons["ルームを作成"].exists)
        XCTAssertTrue(app.buttons["ルームに参加"].exists)
    }

    @MainActor
    func testCreateRoomFlow() throws {
        // Given
        let app = XCUIApplication()
        app.launch()

        // When
        app.buttons["ルームを作成"].tap()

        // Then
        XCTAssertTrue(app.staticTexts["ルーム作成"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["名前を入力"].exists)
    }

    @MainActor
    func testJoinRoomFlow() throws {
        // Given
        let app = XCUIApplication()
        app.launch()

        // When
        app.buttons["ルームに参加"].tap()

        // Then
        XCTAssertTrue(app.staticTexts["ルーム参加"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["名前を入力"].exists)
        XCTAssertTrue(app.textFields["6桁のコードを入力"].exists)
    }

    @MainActor
    func testCreateRoomAndEnterLobby() throws {
        // Given
        let app = XCUIApplication()
        app.launch()

        // When
        app.buttons["ルームを作成"].tap()

        let nameField = app.textFields["名前を入力"]
        nameField.tap()
        nameField.typeText("テストプレイヤー")

        app.buttons["ルームを作成"].tap()

        // Then
        XCTAssertTrue(app.staticTexts["ロビー"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["ルームコード"].exists)
    }
}
