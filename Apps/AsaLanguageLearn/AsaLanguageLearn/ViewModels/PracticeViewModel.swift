//
//  PracticeViewModel.swift
//  AsaLanguageLearn
//
//  発音練習画面のViewModel
//

import Foundation
import SwiftData

/// 発音練習の状態
enum PracticeState: Equatable {
    case ready
    case listening
    case processing
    case showingResult(PronunciationResult)
    case completed
    case error(String)
}

/// 発音練習ViewModel
@MainActor
@Observable
final class PracticeViewModel {
    // MARK: - Properties

    /// 現在の状態
    private(set) var state: PracticeState = .ready

    /// 現在の学習アイテム
    private(set) var currentItem: LearningItem?

    /// 練習するアイテムリスト
    private(set) var items: [LearningItem] = []

    /// 現在のインデックス
    private(set) var currentIndex: Int = 0

    /// セッションの統計
    private(set) var correctCount: Int = 0
    private(set) var incorrectCount: Int = 0
    private(set) var sessionStartTime: Date = Date()

    /// 最後の発音結果
    private(set) var lastResult: PronunciationResult?

    // MARK: - Dependencies

    let speechRecognitionService: SpeechRecognitionServiceProtocol
    let textToSpeechService: TextToSpeechServiceProtocol
    private let scoringService: PronunciationScoringServiceProtocol
    private let modelContext: ModelContext

    // MARK: - Computed Properties

    var recognizedText: String {
        speechRecognitionService.recognizedText
    }

    var audioLevel: Float {
        speechRecognitionService.audioLevel
    }

    var isListening: Bool {
        speechRecognitionService.state == .listening
    }

    var isSpeaking: Bool {
        textToSpeechService.state == .speaking
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(currentIndex) / Double(items.count)
    }

    var totalItems: Int {
        items.count
    }

    var completedItems: Int {
        currentIndex
    }

    var sessionDurationSeconds: Int {
        Int(Date().timeIntervalSince(sessionStartTime))
    }

    var averageScore: Double {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total)
    }

    // MARK: - Initialization

    init(
        speechRecognitionService: SpeechRecognitionServiceProtocol,
        textToSpeechService: TextToSpeechServiceProtocol,
        scoringService: PronunciationScoringServiceProtocol = PronunciationScoringService.shared,
        modelContext: ModelContext
    ) {
        self.speechRecognitionService = speechRecognitionService
        self.textToSpeechService = textToSpeechService
        self.scoringService = scoringService
        self.modelContext = modelContext
    }

    // MARK: - Setup

    /// レッスンのアイテムで練習を開始
    func startPractice(with lesson: Lesson) {
        items = lesson.items.sorted { $0.sortOrder < $1.sortOrder }
        currentIndex = 0
        correctCount = 0
        incorrectCount = 0
        sessionStartTime = Date()
        state = .ready

        if let first = items.first {
            currentItem = first
        }
    }

    /// 復習対象アイテムで練習を開始
    func startReview(with items: [LearningItem]) {
        self.items = items
        currentIndex = 0
        correctCount = 0
        incorrectCount = 0
        sessionStartTime = Date()
        state = .ready

        if let first = items.first {
            currentItem = first
        }
    }

    // MARK: - Actions

    /// 模範発音を再生
    func playModelPronunciation() {
        guard let item = currentItem else { return }
        textToSpeechService.speak(item.englishText)
    }

    /// 例文を再生
    func playExampleSentence() {
        guard let item = currentItem, let example = item.exampleSentence else { return }
        textToSpeechService.speak(example)
    }

    /// 再生を停止
    func stopPlayback() {
        textToSpeechService.stop()
    }

    /// 音声認識を開始
    func startListening() async {
        state = .listening
        speechRecognitionService.reset()

        do {
            try await speechRecognitionService.startRecognition()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// 音声認識を停止して評価
    func stopListeningAndEvaluate() {
        speechRecognitionService.stopRecognition()
        state = .processing

        guard let item = currentItem else {
            state = .error("学習アイテムが見つかりません")
            return
        }

        let recognizedText = speechRecognitionService.finalText.isEmpty
            ? speechRecognitionService.recognizedText
            : speechRecognitionService.finalText

        // スコアリング
        let result = scoringService.calculateScore(
            recognized: recognizedText,
            target: item.englishText
        )

        lastResult = result

        // 進捗を更新
        updateProgress(for: item, with: result)

        state = .showingResult(result)
    }

    /// 次のアイテムへ進む
    func nextItem() {
        currentIndex += 1

        if currentIndex < items.count {
            currentItem = items[currentIndex]
            state = .ready
            lastResult = nil
            speechRecognitionService.reset()
        } else {
            state = .completed
        }
    }

    /// 現在のアイテムをやり直す
    func retryCurrentItem() {
        state = .ready
        lastResult = nil
        speechRecognitionService.reset()
    }

    /// セッションをリセット
    func resetSession() {
        currentIndex = 0
        correctCount = 0
        incorrectCount = 0
        sessionStartTime = Date()
        state = .ready
        lastResult = nil
        speechRecognitionService.reset()

        if let first = items.first {
            currentItem = first
        }
    }

    // MARK: - Private Methods

    private func updateProgress(for item: LearningItem, with result: PronunciationResult) {
        // 進捗がなければ作成
        if item.progress == nil {
            let progress = LearningProgress()
            item.progress = progress
        }

        // 結果を記録
        if result.countsAsCorrect {
            item.progress?.recordCorrect(pronunciationScore: result.score)
            correctCount += 1
        } else {
            item.progress?.recordIncorrect(pronunciationScore: result.score)
            incorrectCount += 1
        }

        // 保存
        try? modelContext.save()
    }
}
