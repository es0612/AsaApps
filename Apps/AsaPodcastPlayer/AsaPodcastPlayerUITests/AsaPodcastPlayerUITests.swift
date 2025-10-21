//
//  AsaPodcastPlayerUITests.swift
//  AsaPodcastPlayerUITests
//
//  Created by AsaPapa on 2025-10-21.
//

import XCTest

final class AsaPodcastPlayerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppLaunches() throws {
        // アプリが起動することを確認
        XCTAssertTrue(app.staticTexts["Podcast プレイヤー"].exists)
    }

    func testPlayButtonExists() throws {
        // 再生ボタンが存在することを確認
        let playButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'play'")).firstMatch
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
    }

    func testEpisodeCardExists() throws {
        // エピソードカードが表示されることを確認
        let episodeTitle = app.staticTexts["保育園通い始めの洗礼の話"]
        XCTAssertTrue(episodeTitle.waitForExistence(timeout: 5))
    }
}
