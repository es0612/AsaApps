//
//  MockServices.swift
//  AsaLanguageLearn
//
//  テスト・プレビュー用のモックサービス
//

import Foundation

// MARK: - Mock Speech Recognition Service

@MainActor
@Observable
final class MockSpeechRecognitionService: SpeechRecognitionServiceProtocol {
    private(set) var state: RecognitionState = .idle
    private(set) var recognizedText: String = ""
    private(set) var finalText: String = ""
    private(set) var audioLevel: Float = 0.0

    var recognitionLocale: Locale = Locale(identifier: "en-US")
    var silenceTimeout: TimeInterval = 2.0
    var maxDuration: TimeInterval = 30.0

    // テスト用のシミュレーション設定
    var simulatedText: String = "Good morning"
    var simulateError: SpeechRecognitionError?
    var recognitionDelay: TimeInterval = 1.0

    func checkMicrophonePermission() async -> Bool {
        true
    }

    func checkSpeechRecognitionPermission() async -> Bool {
        true
    }

    func requestPermissions() async -> Bool {
        true
    }

    func startRecognition() async throws {
        if let error = simulateError {
            throw error
        }

        state = .listening
        recognizedText = ""
        finalText = ""

        // 音声レベルのシミュレーション
        simulateAudioLevels()

        // 認識のシミュレーション
        try await Task.sleep(for: .seconds(recognitionDelay))

        // 部分結果のシミュレーション
        let words = simulatedText.split(separator: " ")
        for (index, _) in words.enumerated() {
            recognizedText = words[0...index].joined(separator: " ")
            try await Task.sleep(for: .milliseconds(300))
        }

        finalText = simulatedText
        state = .finished
    }

    func stopRecognition() {
        state = .finished
        finalText = recognizedText
        audioLevel = 0.0
    }

    func reset() {
        state = .idle
        recognizedText = ""
        finalText = ""
        audioLevel = 0.0
    }

    private func simulateAudioLevels() {
        Task {
            while state == .listening {
                audioLevel = Float.random(in: 0.2...0.8)
                try? await Task.sleep(for: .milliseconds(100))
            }
            audioLevel = 0.0
        }
    }
}

// MARK: - Mock Text to Speech Service

@MainActor
@Observable
final class MockTextToSpeechService: TextToSpeechServiceProtocol {
    private(set) var state: SpeechState = .idle
    private(set) var progress: Double = 0.0
    private(set) var currentWordRange: Range<String.Index>?

    var speechRate: Float = 0.5
    var speechPitch: Float = 1.0
    var speechVolume: Float = 1.0
    var speechLocale: Locale = Locale(identifier: "en-US")

    // テスト用
    var speakDuration: TimeInterval = 2.0

    func speak(_ text: String) {
        state = .speaking
        progress = 0.0

        Task {
            let words = text.split(separator: " ")
            let wordCount = words.count

            for (index, _) in words.enumerated() {
                guard state == .speaking else { break }

                progress = Double(index + 1) / Double(wordCount)
                try? await Task.sleep(for: .seconds(speakDuration / Double(wordCount)))
            }

            if state == .speaking {
                state = .idle
                progress = 1.0
            }
        }
    }

    func pause() {
        state = .paused
    }

    func resume() {
        state = .speaking
    }

    func stop() {
        state = .idle
        progress = 0.0
        currentWordRange = nil
    }

    func availableVoices() -> [VoiceInfo] {
        [
            VoiceInfo(id: "mock-en-us", name: "Samantha", language: "en-US", quality: .enhanced),
            VoiceInfo(id: "mock-en-gb", name: "Daniel", language: "en-GB", quality: .enhanced),
        ]
    }
}

// MARK: - Mock Pronunciation Scoring Service

final class MockPronunciationScoringService: PronunciationScoringServiceProtocol, Sendable {
    // シミュレーション用のスコア
    let simulatedScore: Double

    init(simulatedScore: Double = 0.85) {
        self.simulatedScore = simulatedScore
    }

    func calculateScore(recognized: String, target: String) -> PronunciationResult {
        let normalizedRecognized = recognized.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTarget = target.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let score = normalizedRecognized == normalizedTarget ? 1.0 : simulatedScore

        let targetWords = normalizedTarget.split(separator: " ").map(String.init)
        let wordMatches = targetWords.map { word in
            WordMatch(
                targetWord: word,
                recognizedWord: word,
                isMatch: score >= 0.7
            )
        }

        return PronunciationResult(
            score: score,
            accuracy: PronunciationAccuracy.from(score: score),
            normalizedRecognized: normalizedRecognized,
            normalizedTarget: normalizedTarget,
            wordMatches: wordMatches
        )
    }
}
