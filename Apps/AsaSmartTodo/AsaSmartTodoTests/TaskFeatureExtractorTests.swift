//
//  TaskFeatureExtractorTests.swift
//  AsaSmartTodoTests
//
//  タスク特徴量抽出サービスのテスト
//  タイトル/説明の複雑度、時間帯スコア、期限スコアを検証
//

import Testing
import Foundation
@testable import AsaSmartTodo

struct TaskFeatureExtractorTests {
    let extractor = TaskFeatureExtractor()

    // MARK: - タイトル複雑度テスト

    @Test("空のタイトルは複雑度0.0")
    func testEmptyTitleComplexity() {
        let complexity = extractor.calculateTitleComplexity("")

        #expect(complexity == 0.0)
    }

    @Test("短いタイトルは低い複雑度")
    func testShortTitleComplexity() {
        let complexity = extractor.calculateTitleComplexity("買い物")

        #expect(complexity > 0.0)
        #expect(complexity < 0.3)
    }

    @Test("長いタイトルは高い複雑度")
    func testLongTitleComplexity() {
        let complexity = extractor.calculateTitleComplexity("重要な会議のための資料準備と発表スライドの作成、データ分析結果のまとめ")

        #expect(complexity > 0.5)
        #expect(complexity <= 1.0)
    }

    @Test("最大文字数のタイトルは複雑度1.0に近い")
    func testMaxTitleComplexity() {
        let longTitle = String(repeating: "あ", count: 50)
        let complexity = extractor.calculateTitleComplexity(longTitle)

        #expect(complexity >= 0.8)
        #expect(complexity <= 1.0)
    }

    // MARK: - 説明文複雑度テスト

    @Test("nil説明文は複雑度0.0")
    func testNilDescriptionComplexity() {
        let complexity = extractor.calculateDescriptionComplexity(nil)

        #expect(complexity == 0.0)
    }

    @Test("空の説明文は複雑度0.0")
    func testEmptyDescriptionComplexity() {
        let complexity = extractor.calculateDescriptionComplexity("")

        #expect(complexity == 0.0)
    }

    @Test("短い説明文は低い複雑度")
    func testShortDescriptionComplexity() {
        let complexity = extractor.calculateDescriptionComplexity("簡単な説明")

        #expect(complexity > 0.0)
        #expect(complexity < 0.3)
    }

    @Test("長い説明文は高い複雑度")
    func testLongDescriptionComplexity() {
        let description = """
        明日の会議で使う資料を準備する必要がある。
        スライド20枚程度を作成し、データ分析結果をまとめる。
        過去3ヶ月のデータを集計し、グラフとチャートを作成。
        最終的なレポートを作成して、チームメンバーにレビューを依頼する。
        フィードバックを反映して、最終版を完成させる。
        """

        let complexity = extractor.calculateDescriptionComplexity(description)

        #expect(complexity > 0.7)
        #expect(complexity <= 1.0)
    }

    // MARK: - 時間帯スコアテスト

    @Test("朝活時間帯（5-7時）は最高スコア")
    func testEarlyMorningTimeScore() {
        let score6AM = extractor.calculateTimeOfDayScore(hour: 6)

        #expect(score6AM == 0.9)
    }

    @Test("朝の時間帯（7-9時）は高スコア")
    func testMorningTimeScore() {
        let score8AM = extractor.calculateTimeOfDayScore(hour: 8)

        #expect(score8AM == 0.7)
    }

    @Test("午前中（9-12時）は中スコア")
    func testMidMorningTimeScore() {
        let score10AM = extractor.calculateTimeOfDayScore(hour: 10)

        #expect(score10AM == 0.6)
    }

    @Test("午後（12-17時）は中スコア")
    func testAfternoonTimeScore() {
        let score2PM = extractor.calculateTimeOfDayScore(hour: 14)

        #expect(score2PM == 0.5)
    }

    @Test("夕方（17-21時）は中スコア")
    func testEveningTimeScore() {
        let score6PM = extractor.calculateTimeOfDayScore(hour: 18)

        #expect(score6PM == 0.6)
    }

    @Test("夜間・深夜は低スコア")
    func testNightTimeScore() {
        let score11PM = extractor.calculateTimeOfDayScore(hour: 23)

        #expect(score11PM == 0.3)
    }

    // MARK: - 期限スコアテスト

    @Test("期限切れタスクは最高スコア1.0")
    func testOverdueDateScore() {
        let score = extractor.calculateDueDateScore(daysUntilDue: -1)

        #expect(score == 1.0)
    }

    @Test("明日期限タスクは0.9スコア")
    func testTomorrowDueDateScore() {
        let score = extractor.calculateDueDateScore(daysUntilDue: 1)

        #expect(score == 0.9)
    }

    @Test("2-3日後期限タスクは0.7スコア")
    func testTwoDaysDueDateScore() {
        let score = extractor.calculateDueDateScore(daysUntilDue: 2)

        #expect(score == 0.7)
    }

    @Test("1週間後期限タスクは0.5スコア")
    func testOneWeekDueDateScore() {
        let score = extractor.calculateDueDateScore(daysUntilDue: 7)

        #expect(score == 0.5)
    }

    @Test("2週間後期限タスクは0.4スコア")
    func testTwoWeeksDueDateScore() {
        let score = extractor.calculateDueDateScore(daysUntilDue: 14)

        #expect(score == 0.4)
    }

    @Test("期限未設定タスクは0.3スコア")
    func testNoDueDateScore() {
        let score = extractor.calculateDueDateScore(daysUntilDue: nil)

        #expect(score == 0.3)
    }

    // MARK: - 期限までの日数計算テスト

    @Test("期限未設定の場合nilを返す")
    func testCalculateDaysUntilDueWithNil() {
        let days = extractor.calculateDaysUntilDue(from: nil)

        #expect(days == nil)
    }

    @Test("明日の期限は1日")
    func testCalculateDaysUntilDueTomorrow() {
        let tomorrow = Date().addingTimeInterval(86400)
        let days = extractor.calculateDaysUntilDue(from: tomorrow)

        #expect(days == 1)
    }

    @Test("昨日の期限は-1日")
    func testCalculateDaysUntilDueYesterday() {
        let yesterday = Date().addingTimeInterval(-86400)
        let days = extractor.calculateDaysUntilDue(from: yesterday)

        #expect(days == -1)
    }

    // MARK: - 統合テスト

    @Test("タスクから全特徴量を抽出")
    func testExtractAllFeatures() {
        let task = SmartTask(
            title: "重要な会議の準備",
            description: "明日の会議で使う資料を準備する",
            category: .work,
            userPriority: .high,
            dueDate: Date().addingTimeInterval(86400)
        )

        let features = extractor.extractFeatures(from: task)

        #expect(features.titleComplexity >= 0.0)
        #expect(features.titleComplexity <= 1.0)
        #expect(features.descriptionComplexity >= 0.0)
        #expect(features.descriptionComplexity <= 1.0)
        #expect(features.timeOfDayScore >= 0.0)
        #expect(features.timeOfDayScore <= 1.0)
        #expect(features.dueDateScore >= 0.0)
        #expect(features.dueDateScore <= 1.0)
    }
}
