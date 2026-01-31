//
//  PronunciationScoringServiceTests.swift
//  AsaLanguageLearnTests
//
//  発音スコアリングサービスのテスト
//

import Testing
@testable import AsaLanguageLearn

struct PronunciationScoringServiceTests {
    let service = PronunciationScoringService.shared

    // MARK: - Perfect Match Tests

    @Test("完全一致はスコア1.0")
    func testPerfectMatch() {
        let result = service.calculateScore(
            recognized: "Good morning",
            target: "Good morning"
        )
        #expect(result.score == 1.0)
        #expect(result.accuracy == .perfect)
    }

    @Test("大文字小文字の違いは無視")
    func testCaseInsensitive() {
        let result = service.calculateScore(
            recognized: "GOOD MORNING",
            target: "good morning"
        )
        #expect(result.score == 1.0)
    }

    @Test("前後の空白は無視")
    func testTrimWhitespace() {
        let result = service.calculateScore(
            recognized: "  Good morning  ",
            target: "Good morning"
        )
        #expect(result.score == 1.0)
    }

    // MARK: - Partial Match Tests

    @Test("部分一致は中間スコア")
    func testPartialMatch() {
        let result = service.calculateScore(
            recognized: "Good",
            target: "Good morning"
        )
        #expect(result.score > 0.3)
        #expect(result.score < 1.0)
    }

    @Test("類似テキストは高スコア")
    func testSimilarText() {
        let result = service.calculateScore(
            recognized: "Good mornin",
            target: "Good morning"
        )
        #expect(result.score >= 0.7)
        #expect(result.accuracy == .good || result.accuracy == .perfect)
    }

    // MARK: - No Match Tests

    @Test("全く異なるテキストは低スコア")
    func testNoMatch() {
        let result = service.calculateScore(
            recognized: "Hello world",
            target: "Good morning"
        )
        #expect(result.score < 0.5)
    }

    @Test("空の認識テキストはスコア0")
    func testEmptyRecognized() {
        let result = service.calculateScore(
            recognized: "",
            target: "Good morning"
        )
        #expect(result.score == 0.0)
        #expect(result.accuracy == .needsWork)
    }

    @Test("両方空ならスコア1.0")
    func testBothEmpty() {
        let result = service.calculateScore(
            recognized: "",
            target: ""
        )
        #expect(result.score == 1.0)
    }

    // MARK: - Word Match Tests

    @Test("単語マッチ結果が正しく生成される")
    func testWordMatches() {
        let result = service.calculateScore(
            recognized: "Good morning",
            target: "Good morning"
        )
        #expect(result.wordMatches.count == 2)
        #expect(result.wordMatches.allSatisfy { $0.isMatch })
    }

    @Test("一部単語が認識されない場合")
    func testPartialWordMatch() {
        let result = service.calculateScore(
            recognized: "Good",
            target: "Good morning everyone"
        )
        let matchedCount = result.wordMatches.filter { $0.isMatch }.count
        #expect(matchedCount >= 1)
    }

    // MARK: - Accuracy Level Tests

    @Test("スコア0.9以上はPerfect")
    func testAccuracyPerfect() {
        let accuracy = PronunciationAccuracy.from(score: 0.95)
        #expect(accuracy == .perfect)
    }

    @Test("スコア0.7-0.9はGood")
    func testAccuracyGood() {
        let accuracy = PronunciationAccuracy.from(score: 0.75)
        #expect(accuracy == .good)
    }

    @Test("スコア0.5-0.7はFair")
    func testAccuracyFair() {
        let accuracy = PronunciationAccuracy.from(score: 0.55)
        #expect(accuracy == .fair)
    }

    @Test("スコア0.5未満はNeedsWork")
    func testAccuracyNeedsWork() {
        let accuracy = PronunciationAccuracy.from(score: 0.3)
        #expect(accuracy == .needsWork)
    }

    // MARK: - Counts As Correct Tests

    @Test("PerfectとGoodは正解としてカウント")
    func testCountsAsCorrect() {
        #expect(PronunciationAccuracy.perfect.countsAsCorrect == true)
        #expect(PronunciationAccuracy.good.countsAsCorrect == true)
        #expect(PronunciationAccuracy.fair.countsAsCorrect == false)
        #expect(PronunciationAccuracy.needsWork.countsAsCorrect == false)
    }

    // MARK: - Punctuation Tests

    @Test("句読点は無視される")
    func testIgnorePunctuation() {
        let result = service.calculateScore(
            recognized: "Hello, how are you?",
            target: "Hello how are you"
        )
        #expect(result.score >= 0.9)
    }
}
