//
//  VoiceTaskTests.swift
//  AsaVoiceAssistantTests
//
//  VoiceTaskモデルのテスト
//

import Testing
import Foundation
@testable import AsaVoiceAssistant

/// VoiceTaskモデルのテストスイート
struct VoiceTaskTests {
    // MARK: - Initialization Tests

    @Test("タスク初期化 - 基本的なプロパティが正しく設定される")
    func testInitialization() {
        let task = VoiceTask(
            title: "テストタスク",
            priority: .high,
            category: .work
        )

        #expect(task.title == "テストタスク")
        #expect(task.priority == .high)
        #expect(task.category == .work)
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
        #expect(task.createdByVoice == false)
    }

    @Test("タスク初期化 - 音声作成フラグが正しく設定される")
    func testVoiceCreation() {
        let task = VoiceTask(
            title: "音声で作成したタスク",
            originalTranscription: "明日までに報告書を作成",
            createdByVoice: true
        )

        #expect(task.createdByVoice == true)
        #expect(task.originalTranscription == "明日までに報告書を作成")
    }

    // MARK: - Completion Tests

    @Test("タスク完了 - complete()で完了状態になる")
    func testComplete() {
        let task = VoiceTask(title: "テスト")

        #expect(task.isCompleted == false)

        task.complete()

        #expect(task.isCompleted == true)
        #expect(task.completedAt != nil)
    }

    @Test("タスク未完了 - uncomplete()で未完了状態に戻る")
    func testUncomplete() {
        let task = VoiceTask(title: "テスト")
        task.complete()

        #expect(task.isCompleted == true)

        task.uncomplete()

        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }

    // MARK: - Due Date Tests

    @Test("期限判定 - 今日期限のタスクを正しく判定")
    func testIsDueToday() {
        let task = VoiceTask(
            title: "今日期限",
            dueDate: Date()
        )

        #expect(task.isDueToday == true)
        #expect(task.isDueTomorrow == false)
    }

    @Test("期限判定 - 明日期限のタスクを正しく判定")
    func testIsDueTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let task = VoiceTask(
            title: "明日期限",
            dueDate: tomorrow
        )

        #expect(task.isDueTomorrow == true)
        #expect(task.isDueToday == false)
    }

    @Test("期限切れ判定 - 過去の期限を正しく検出")
    func testIsOverdue() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let task = VoiceTask(
            title: "期限切れ",
            dueDate: yesterday
        )

        #expect(task.isOverdue == true)
    }

    @Test("期限切れ判定 - 完了済みタスクは期限切れにならない")
    func testCompletedTaskNotOverdue() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let task = VoiceTask(
            title: "完了済み期限切れ",
            dueDate: yesterday
        )
        task.complete()

        #expect(task.isOverdue == false)
    }

    // MARK: - Update Tests

    @Test("タスク更新 - update()で各プロパティが更新される")
    func testUpdate() {
        let task = VoiceTask(
            title: "元のタイトル",
            priority: .low,
            category: .personal
        )

        task.update(
            title: "新しいタイトル",
            priority: .high,
            category: .work
        )

        #expect(task.title == "新しいタイトル")
        #expect(task.priority == .high)
        #expect(task.category == .work)
    }

    // MARK: - Speech Text Tests

    @Test("読み上げテキスト - 基本的なタスクの読み上げ")
    func testToSpeechTextBasic() {
        let task = VoiceTask(title: "買い物に行く")
        let speechText = task.toSpeechText()

        #expect(speechText == "買い物に行く")
    }

    @Test("読み上げテキスト - 期限付きタスクの読み上げ")
    func testToSpeechTextWithDueDate() {
        let task = VoiceTask(
            title: "報告書作成",
            dueDate: Date()  // 今日
        )
        let speechText = task.toSpeechText()

        #expect(speechText.contains("報告書作成"))
        #expect(speechText.contains("今日"))
    }

    @Test("読み上げテキスト - 高優先度タスクの読み上げ")
    func testToSpeechTextWithHighPriority() {
        let task = VoiceTask(
            title: "緊急対応",
            priority: .high
        )
        let speechText = task.toSpeechText()

        #expect(speechText.contains("緊急対応"))
        #expect(speechText.contains("優先度高"))
    }
}
