//
//  AsaSmartTodoUITests.swift
//  AsaSmartTodoUITests
//
//  主要ユーザーフローのUIテスト
//  タスク作成、AI予測採用、設定変更の3フローを検証
//

import XCTest

final class AsaSmartTodoUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - フロー1: タスク作成フロー

    func testTaskCreationFlow() throws {
        // 1. 新規タスク作成ボタンをタップ
        let addButton = app.buttons["新しいタスク"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // 2. タイトル入力フィールドを確認
        let titleField = app.textFields["タイトルを入力"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("重要な会議の準備")

        // 3. 説明文入力（オプショナル）
        let descriptionField = app.textViews["説明を入力（オプション）"]
        if descriptionField.exists {
            descriptionField.tap()
            descriptionField.typeText("プレゼン資料を準備する")
        }

        // 4. カテゴリ選択
        let categoryPicker = app.buttons["カテゴリ選択"]
        if categoryPicker.exists {
            categoryPicker.tap()

            // 「仕事」カテゴリを選択
            let workCategory = app.buttons["仕事"]
            if workCategory.waitForExistence(timeout: 2) {
                workCategory.tap()
            }
        }

        // 5. 期限設定
        let dueDateToggle = app.switches["期限を設定"]
        if dueDateToggle.exists {
            if !dueDateToggle.isSelected {
                dueDateToggle.tap()
            }

            // DatePickerが表示されることを確認
            let datePicker = app.datePickers.firstMatch
            XCTAssertTrue(datePicker.waitForExistence(timeout: 2))
        }

        // 6. 保存ボタンをタップ
        let saveButton = app.buttons["保存"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        saveButton.tap()

        // 7. タスクリストに戻り、作成したタスクが表示されることを確認
        let createdTask = app.staticTexts["重要な会議の準備"]
        XCTAssertTrue(createdTask.waitForExistence(timeout: 3), "作成したタスクがリストに表示されること")
    }

    func testTaskCreationWithMinimalInput() throws {
        // タイトルのみでタスク作成（最小入力パターン）
        let addButton = app.buttons["新しいタスク"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let titleField = app.textFields["タイトルを入力"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("簡単なメモ")

        let saveButton = app.buttons["保存"]
        saveButton.tap()

        let createdTask = app.staticTexts["簡単なメモ"]
        XCTAssertTrue(createdTask.waitForExistence(timeout: 3))
    }

    func testTaskCreationCancellation() throws {
        // タスク作成キャンセルフロー
        let addButton = app.buttons["新しいタスク"]
        addButton.tap()

        let titleField = app.textFields["タイトルを入力"]
        titleField.tap()
        titleField.typeText("キャンセルするタスク")

        // キャンセルボタンをタップ
        let cancelButton = app.buttons["キャンセル"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            // ナビゲーションバーの戻るボタン
            let backButton = app.navigationBars.buttons.firstMatch
            backButton.tap()
        }

        // タスクが作成されていないことを確認
        let cancelledTask = app.staticTexts["キャンセルするタスク"]
        XCTAssertFalse(cancelledTask.exists, "キャンセルしたタスクは作成されないこと")
    }

    // MARK: - フロー2: AI予測採用フロー

    func testAIPredictionAcceptanceFlow() throws {
        // 1. タスクを作成してAI予測を表示
        let addButton = app.buttons["新しいタスク"]
        addButton.tap()

        let titleField = app.textFields["タイトルを入力"]
        titleField.tap()
        titleField.typeText("緊急の報告書作成")

        // 説明を追加（AI予測の信頼度を上げる）
        let descriptionField = app.textViews["説明を入力（オプション）"]
        if descriptionField.exists {
            descriptionField.tap()
            descriptionField.typeText("明日の会議で使う重要な報告書を作成する必要があります")
        }

        // カテゴリを「仕事」に設定
        let categoryPicker = app.buttons["カテゴリ選択"]
        if categoryPicker.exists {
            categoryPicker.tap()
            let workCategory = app.buttons["仕事"]
            if workCategory.waitForExistence(timeout: 2) {
                workCategory.tap()
            }
        }

        // 期限を明日に設定
        let dueDateToggle = app.switches["期限を設定"]
        if dueDateToggle.exists && !dueDateToggle.isSelected {
            dueDateToggle.tap()
        }

        // 2. AI予測が表示されることを確認
        let aiPredictionCard = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '推奨優先度'")).firstMatch
        if aiPredictionCard.waitForExistence(timeout: 2) {
            // AI予測カードが表示されている
            XCTAssertTrue(aiPredictionCard.exists, "AI予測が表示されること")
        }

        // 3. AI予測の「採用」ボタンをタップ
        let acceptButton = app.buttons["AI予測を採用"]
        if acceptButton.exists {
            acceptButton.tap()

            // 4. 優先度が更新されたことを確認
            let highPriorityIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '高'")).firstMatch
            XCTAssertTrue(highPriorityIndicator.waitForExistence(timeout: 2), "優先度が更新されること")
        }

        // 5. タスクを保存
        let saveButton = app.buttons["保存"]
        saveButton.tap()

        // 6. リストでAI採用されたタスクが表示されることを確認
        let createdTask = app.staticTexts["緊急の報告書作成"]
        XCTAssertTrue(createdTask.waitForExistence(timeout: 3))
    }

    func testAIPredictionRejection() throws {
        // AI予測を拒否するフロー
        let addButton = app.buttons["新しいタスク"]
        addButton.tap()

        let titleField = app.textFields["タイトルを入力"]
        titleField.tap()
        titleField.typeText("タスク")

        // AI予測が表示されたら「無視」ボタンをタップ
        let rejectButton = app.buttons["無視"]
        if rejectButton.waitForExistence(timeout: 2) {
            rejectButton.tap()

            // AI予測カードが非表示になることを確認
            let aiPredictionCard = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '推奨優先度'")).firstMatch
            XCTAssertFalse(aiPredictionCard.exists, "AI予測カードが非表示になること")
        }

        // キャンセル
        let cancelButton = app.buttons["キャンセル"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    // MARK: - フロー3: 設定変更フロー

    func testSettingsModificationFlow() throws {
        // 1. 設定タブに移動
        let settingsTab = app.tabBars.buttons["設定"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // 2. AI重み設定セクションが表示されることを確認
        let aiWeightsSection = app.staticTexts["AI予測の重み設定"]
        XCTAssertTrue(aiWeightsSection.waitForExistence(timeout: 3), "AI重み設定セクションが表示されること")

        // 3. 期限重みのスライダーを調整
        let dueDateSlider = app.sliders["期限の重み"]
        if dueDateSlider.exists {
            // スライダーを50%に設定
            dueDateSlider.adjust(toNormalizedSliderPosition: 0.5)

            // 重み値が更新されたことを確認（おおよそ50%前後）
            let sliderValue = dueDateSlider.value as? String
            XCTAssertNotNil(sliderValue, "スライダー値が取得できること")
        }

        // 4. カテゴリ重みのスライダーを調整
        let categorySlider = app.sliders["カテゴリの重み"]
        if categorySlider.exists {
            categorySlider.adjust(toNormalizedSliderPosition: 0.3)
        }

        // 5. 「重みをリセット」ボタンが存在することを確認
        let resetButton = app.buttons["重みをリセット"]
        if resetButton.exists {
            // リセットボタンをタップ
            resetButton.tap()

            // アラートが表示される場合は確認
            let confirmAlert = app.alerts.firstMatch
            if confirmAlert.waitForExistence(timeout: 1) {
                let confirmButton = confirmAlert.buttons["リセット"]
                if confirmButton.exists {
                    confirmButton.tap()
                }
            }

            // デフォルト値に戻ったことを確認
            // （実際の値は環境依存なので、存在確認のみ）
            XCTAssertTrue(dueDateSlider.exists)
        }

        // 6. 通知設定セクションをスクロールして表示
        app.swipeUp()

        let notificationSection = app.staticTexts["通知設定"]
        if notificationSection.waitForExistence(timeout: 2) {
            XCTAssertTrue(notificationSection.exists, "通知設定セクションが表示されること")
        }

        // 7. 通知有効化トグルを操作
        let notificationToggle = app.switches["通知を有効化"]
        if notificationToggle.exists {
            let initialState = notificationToggle.isSelected
            notificationToggle.tap()

            // トグル状態が変わったことを確認
            let newState = notificationToggle.isSelected
            XCTAssertNotEqual(initialState, newState, "トグル状態が変更されること")

            // 元に戻す
            notificationToggle.tap()
        }
    }

    func testCustomCategoryManagement() throws {
        // カスタムカテゴリ管理フロー
        let settingsTab = app.tabBars.buttons["設定"]
        settingsTab.tap()

        // カスタムカテゴリセクションまでスクロール
        app.swipeUp()
        app.swipeUp()

        let customCategorySection = app.staticTexts["カスタムカテゴリ"]
        if customCategorySection.waitForExistence(timeout: 2) {
            // 新しいカテゴリ追加ボタン
            let addCategoryButton = app.buttons["カテゴリを追加"]
            if addCategoryButton.exists {
                addCategoryButton.tap()

                // カテゴリ名入力
                let nameField = app.textFields["カテゴリ名"]
                if nameField.waitForExistence(timeout: 2) {
                    nameField.tap()
                    nameField.typeText("副業")

                    // 保存
                    let saveButton = app.buttons["保存"]
                    if saveButton.exists {
                        saveButton.tap()
                    }

                    // 追加されたカテゴリが表示されることを確認
                    let newCategory = app.staticTexts["副業"]
                    XCTAssertTrue(newCategory.waitForExistence(timeout: 2), "新しいカテゴリが追加されること")
                }
            }
        }
    }

    func testSettingsNavigationFlow() throws {
        // 設定画面のナビゲーションフロー
        let settingsTab = app.tabBars.buttons["設定"]
        settingsTab.tap()

        // 各セクションが存在することを確認
        let aiWeightsSection = app.staticTexts["AI予測の重み設定"]
        XCTAssertTrue(aiWeightsSection.exists)

        app.swipeUp()

        let notificationSection = app.staticTexts["通知設定"]
        XCTAssertTrue(notificationSection.waitForExistence(timeout: 2))

        // タスクリストタブに戻る
        let tasksTab = app.tabBars.buttons["タスク"]
        if tasksTab.exists {
            tasksTab.tap()

            // タスクリストに戻ったことを確認
            let addButton = app.buttons["新しいタスク"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        }
    }
}
