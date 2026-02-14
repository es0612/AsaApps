import Testing
import Foundation

@testable import AsaCommunityKit

@Suite("ContentModerationService テスト")
struct ContentModerationServiceTests {

    let service = ContentModerationService()

    @Test("analyzeSentiment - ニュートラルなテキストはacceptableを返す")
    func testAnalyzeSentimentNeutral() {
        let result = service.analyzeSentiment(text: "今日は天気が良いです")
        #expect(result.isAcceptable == true)
        #expect(result.warningMessage == nil)
    }

    @Test("analyzeSentiment - 感情スコアが返される")
    func testAnalyzeSentimentReturnsScore() {
        let result = service.analyzeSentiment(text: "こんにちは")
        // 感情スコアは -1.0 ~ 1.0 の範囲
        #expect(result.sentimentScore >= -1.0)
        #expect(result.sentimentScore <= 1.0)
    }

    @Test("analyzeSentiment - 言語が検出される")
    func testAnalyzeSentimentDetectsLanguage() {
        let result = service.analyzeSentiment(text: "今日はとても良い天気です。みんなで散歩しましょう。")
        #expect(result.detectedLanguage != nil)
    }

    @Test("detectLanguage - 日本語テキストの言語を検出する")
    func testDetectLanguageJapanese() {
        let language = service.detectLanguage(text: "今日はとても良い天気です。みんなで公園に行きましょう。")
        #expect(language == "ja")
    }

    @Test("detectLanguage - 英語テキストの言語を検出する")
    func testDetectLanguageEnglish() {
        let language = service.detectLanguage(text: "Hello, this is a test message for language detection.")
        #expect(language == "en")
    }

    @Test("カスタム閾値で初期化できる")
    func testCustomThreshold() {
        let strictService = ContentModerationService(negativeThreshold: -0.1)
        let result = strictService.analyzeSentiment(text: "テスト")
        // 閾値が-0.1でも動作すること
        #expect(result.sentimentScore >= -1.0)
        #expect(result.sentimentScore <= 1.0)
    }
}
