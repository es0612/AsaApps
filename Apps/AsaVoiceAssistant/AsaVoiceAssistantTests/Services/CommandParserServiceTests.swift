//
//  CommandParserServiceTests.swift
//  AsaVoiceAssistantTests
//
//  CommandParserServiceのテスト
//

import Testing
import Foundation
@testable import AsaVoiceAssistant

/// CommandParserServiceのテストスイート
struct CommandParserServiceTests {
    let parser = CommandParserService.shared

    // MARK: - Create Task Tests

    @Test("タスク作成コマンド - 「〜を追加」パターン")
    func testCreateTaskAddPattern() {
        let command = parser.parse("報告書を追加")

        #expect(command.intent == .createTask)
        #expect(command.taskTitle != nil)
        #expect(command.taskTitle?.contains("報告書") == true)
    }

    @Test("タスク作成コマンド - 「〜を作成」パターン")
    func testCreateTaskCreatePattern() {
        let command = parser.parse("買い物リストを作成")

        #expect(command.intent == .createTask)
        #expect(command.taskTitle?.contains("買い物リスト") == true)
    }

    @Test("タスク作成コマンド - 「〜する」パターン")
    func testCreateTaskVerbPattern() {
        let command = parser.parse("牛乳を買う")

        #expect(command.intent == .createTask)
    }

    @Test("タスク作成コマンド - 期限抽出（明日）")
    func testCreateTaskWithTomorrowDue() {
        let command = parser.parse("明日までに報告書を作成")

        #expect(command.intent == .createTask)
        #expect(command.dueDate != nil)

        if let dueDate = command.dueDate {
            #expect(Calendar.current.isDateInTomorrow(dueDate))
        }
    }

    @Test("タスク作成コマンド - 期限抽出（今日）")
    func testCreateTaskWithTodayDue() {
        let command = parser.parse("今日中に資料を準備")

        #expect(command.dueDate != nil)

        if let dueDate = command.dueDate {
            #expect(Calendar.current.isDateInToday(dueDate))
        }
    }

    @Test("タスク作成コマンド - 優先度抽出（高）")
    func testCreateTaskWithHighPriority() {
        let command = parser.parse("重要な会議の準備を追加")

        #expect(command.priority == .high)
    }

    @Test("タスク作成コマンド - 優先度抽出（低）")
    func testCreateTaskWithLowPriority() {
        let command = parser.parse("後でやる掃除を追加")

        #expect(command.priority == .low)
    }

    @Test("タスク作成コマンド - カテゴリ抽出（仕事）")
    func testCreateTaskWithWorkCategory() {
        let command = parser.parse("会議の準備を追加")

        #expect(command.category == .work)
    }

    @Test("タスク作成コマンド - カテゴリ抽出（買い物）")
    func testCreateTaskWithShoppingCategory() {
        let command = parser.parse("スーパーで牛乳を買う")

        #expect(command.category == .shopping)
    }

    // MARK: - Complete Task Tests

    @Test("タスク完了コマンド - 「〜を完了」パターン")
    func testCompleteTaskPattern() {
        let command = parser.parse("報告書を完了")

        #expect(command.intent == .completeTask)
        #expect(command.targetTaskQuery?.contains("報告書") == true)
    }

    @Test("タスク完了コマンド - 「〜終わった」パターン")
    func testCompleteTaskFinishedPattern() {
        let command = parser.parse("買い物終わった")

        #expect(command.intent == .completeTask)
    }

    // MARK: - Delete Task Tests

    @Test("タスク削除コマンド - 「〜を削除」パターン")
    func testDeleteTaskPattern() {
        let command = parser.parse("古いタスクを削除")

        #expect(command.intent == .deleteTask)
        #expect(command.targetTaskQuery != nil)
    }

    // MARK: - List Tasks Tests

    @Test("タスク一覧コマンド - 「今日のタスクを見せて」")
    func testListTasksToday() {
        let command = parser.parse("今日のタスクを見せて")

        #expect(command.intent == .listTasks)
    }

    @Test("タスク一覧コマンド - 「高優先度のタスクを見せて」")
    func testListTasksHighPriority() {
        let command = parser.parse("高優先度のタスクを見せて")

        #expect(command.intent == .listTasks)
        #expect(command.filterPriority == .high)
    }

    @Test("タスク一覧コマンド - 「タスクを確認」")
    func testListTasksCheck() {
        let command = parser.parse("タスクを確認")

        #expect(command.intent == .listTasks)
    }

    // MARK: - Read Tasks Tests

    @Test("タスク読み上げコマンド - 「タスクを読んで」")
    func testReadTasksPattern() {
        let command = parser.parse("タスクを読んで")

        #expect(command.intent == .readTasks)
    }

    @Test("タスク読み上げコマンド - 「今日のタスクを読み上げて」")
    func testReadTasksTodayPattern() {
        let command = parser.parse("今日のタスクを読み上げて")

        #expect(command.intent == .readTasks)
    }

    // MARK: - Unknown Command Tests

    @Test("不明なコマンド - 認識できないテキスト")
    func testUnknownCommand() {
        let command = parser.parse("こんにちは")

        #expect(command.intent == .unknown)
        #expect(command.isValid == false)
    }

    // MARK: - Date Extraction Tests

    @Test("期限抽出 - 「X日後」パターン")
    func testDueDateDaysLater() {
        let command = parser.parse("3日後までに完成させる")

        #expect(command.dueDate != nil)

        if let dueDate = command.dueDate {
            let expectedDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
            #expect(Calendar.current.isDate(dueDate, inSameDayAs: expectedDate))
        }
    }

    @Test("期限抽出 - 「X月X日」パターン")
    func testDueDateSpecificDate() {
        let command = parser.parse("12月25日までにプレゼントを買う")

        #expect(command.dueDate != nil)

        if let dueDate = command.dueDate {
            let components = Calendar.current.dateComponents([.month, .day], from: dueDate)
            #expect(components.month == 12)
            #expect(components.day == 25)
        }
    }

    // MARK: - Confidence Tests

    @Test("信頼度スコア - 明確なコマンドは高信頼度")
    func testHighConfidence() {
        let command = parser.parse("報告書を追加")

        #expect(command.confidence >= 0.8)
    }

    @Test("信頼度スコア - 不明なコマンドは低信頼度")
    func testLowConfidence() {
        let command = parser.parse("こんにちは")

        #expect(command.confidence == 0.0)
    }
}
