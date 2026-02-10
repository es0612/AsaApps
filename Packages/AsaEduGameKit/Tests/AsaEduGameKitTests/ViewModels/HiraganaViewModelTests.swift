import Testing
import Foundation
@testable import AsaEduGameKit

// MARK: - HiraganaViewModel テスト用Mock

/// テスト用の手書き認識Mock
private struct MockHandwritingService: HandwritingRecognizing {
    func recognize(drawingPoints: [[CGPoint]]) async throws -> HandwritingResult {
        HandwritingResult(
            recognizedCharacter: "あ",
            confidence: 0.95
        )
    }

    func supportedCharacters() -> [String] {
        ["あ", "い", "う", "え", "お"]
    }
}

// MARK: - HiraganaViewModel テスト

@Suite("HiraganaViewModel テスト")
struct HiraganaViewModelTests {

    @Test("初期状態")
    @MainActor
    func testInitialState() {
        let vm = HiraganaViewModel()
        #expect(vm.currentCharacter == "")
        #expect(vm.isWritingMode == false)
        #expect(vm.drawingPoints.isEmpty)
        #expect(vm.recognitionResult == nil)
        #expect(vm.isRecognizing == false)
    }

    @Test("読み方問題セットアップ")
    @MainActor
    func testReadingSetup() {
        let vm = HiraganaViewModel()
        let question = GameQuestion(
            questionType: .hiraganaReading,
            questionText: "「あめ」のさいしょのもじは？",
            options: ["あ", "い", "う", "え"],
            correctAnswer: "あ"
        )
        vm.setupForQuestion(question)
        #expect(vm.isWritingMode == false)
        #expect(vm.currentCharacter == "「あめ」のさいしょのもじは？")
    }

    @Test("マッチング問題セットアップ")
    @MainActor
    func testMatchingSetup() {
        let vm = HiraganaViewModel()
        let question = GameQuestion(
            questionType: .hiraganaMatching,
            questionText: "「あ」ではじまることばは？",
            options: ["あめ", "いぬ", "うし", "えんぴつ"],
            correctAnswer: "あめ"
        )
        vm.setupForQuestion(question)
        #expect(vm.isWritingMode == false)
        #expect(vm.currentCharacter == "「あ」ではじまることばは？")
    }

    @Test("書き取りモードセットアップ")
    @MainActor
    func testWritingModeSetup() {
        let vm = HiraganaViewModel()
        let question = GameQuestion(
            questionType: .hiraganaWriting,
            questionText: "「あめ」のさいしょのもじをかこう！",
            options: ["あ", "い", "う", "え"],
            correctAnswer: "あ"
        )
        vm.setupForQuestion(question)
        #expect(vm.isWritingMode == true)
        #expect(vm.currentCharacter == "あ")
    }

    @Test("描画クリア")
    @MainActor
    func testClearDrawing() {
        let vm = HiraganaViewModel()
        vm.drawingPoints = [[CGPoint(x: 10, y: 20), CGPoint(x: 30, y: 40)]]
        vm.clearDrawing()
        #expect(vm.drawingPoints.isEmpty)
        #expect(vm.recognitionResult == nil)
    }

    @Test("描画ポイント追加")
    @MainActor
    func testAddDrawingPoints() {
        let vm = HiraganaViewModel()
        let stroke = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10)]
        vm.drawingPoints.append(stroke)
        #expect(vm.drawingPoints.count == 1)
        #expect(vm.drawingPoints[0].count == 2)
    }

    @Test("手書き認識なしでの初期化")
    @MainActor
    func testInitWithoutHandwriting() {
        let vm = HiraganaViewModel(handwritingService: nil)
        #expect(vm.isWritingMode == false)
        #expect(vm.recognitionResult == nil)
    }

    @Test("手書き認識ありでの初期化")
    @MainActor
    func testInitWithHandwriting() {
        let vm = HiraganaViewModel(handwritingService: MockHandwritingService())
        #expect(vm.isWritingMode == false)
        #expect(vm.recognitionResult == nil)
    }

    @Test("認識結果リセット")
    @MainActor
    func testRecognitionResultReset() {
        let vm = HiraganaViewModel()
        // setupForQuestionが呼ばれると認識結果がリセットされること
        let question = GameQuestion(
            questionType: .hiraganaReading,
            questionText: "テスト",
            options: ["あ", "い", "う", "え"],
            correctAnswer: "あ"
        )
        vm.setupForQuestion(question)
        #expect(vm.recognitionResult == nil)
        #expect(vm.drawingPoints.isEmpty)
    }

    @Test("現在の文字取得")
    @MainActor
    func testCurrentCharacter() {
        let vm = HiraganaViewModel()
        // 書き取り問題では correctAnswer が currentCharacter になる
        let question = GameQuestion(
            questionType: .hiraganaWriting,
            questionText: "「いぬ」のさいしょのもじをかこう！",
            options: ["あ", "い", "う", "え"],
            correctAnswer: "い"
        )
        vm.setupForQuestion(question)
        #expect(vm.currentCharacter == "い")
    }
}
