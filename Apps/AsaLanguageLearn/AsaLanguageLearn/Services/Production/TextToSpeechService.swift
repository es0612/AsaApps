//
//  TextToSpeechService.swift
//  AsaLanguageLearn
//
//  音声合成サービスの実装
//

import AVFoundation
import Foundation

/// 音声合成サービス
/// AVSpeechSynthesizerを使用した音声読み上げ
@MainActor
@Observable
final class TextToSpeechService: NSObject, TextToSpeechServiceProtocol {
    // MARK: - Properties

    private(set) var state: SpeechState = .idle
    private(set) var progress: Double = 0.0
    private(set) var currentWordRange: Range<String.Index>?

    var speechRate: Float = 0.5
    var speechPitch: Float = 1.0
    var speechVolume: Float = 1.0
    var speechLocale: Locale = Locale(identifier: "en-US")

    // MARK: - Private Properties

    private let synthesizer = AVSpeechSynthesizer()
    private var currentText: String = ""
    private var selectedVoice: AVSpeechSynthesisVoice?

    // MARK: - Initialization

    override init() {
        super.init()
        synthesizer.delegate = self
        updateVoice()
    }

    // MARK: - Public Methods

    func speak(_ text: String) {
        // 既存の音声を停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        // オーディオセッションの設定
        configureAudioSession()

        // 音声の更新
        updateVoice()

        currentText = text
        progress = 0.0
        currentWordRange = nil

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume

        // 自然な間を入れる
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        synthesizer.speak(utterance)
        state = .speaking
    }

    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            state = .paused
        }
    }

    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            state = .speaking
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        state = .idle
        progress = 0.0
        currentWordRange = nil
        currentText = ""
    }

    func availableVoices() -> [VoiceInfo] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(speechLocale.language.languageCode?.identifier ?? "en") }
            .map { voice in
                VoiceInfo(
                    id: voice.identifier,
                    name: voice.name,
                    language: voice.language,
                    quality: mapQuality(voice.quality)
                )
            }
            .sorted { $0.quality > $1.quality }
    }

    // MARK: - Private Methods

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("オーディオセッションの設定に失敗: \(error)")
        }
    }

    private func updateVoice() {
        let languagePrefix = speechLocale.language.languageCode?.identifier ?? "en"

        // 最も高品質な音声を選択
        selectedVoice = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(languagePrefix) }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
            .first ?? AVSpeechSynthesisVoice(language: speechLocale.identifier)
    }

    private func mapQuality(_ quality: AVSpeechSynthesisVoiceQuality) -> VoiceQuality {
        switch quality {
        case .enhanced:
            return .enhanced
        case .premium:
            return .premium
        default:
            return .default
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.state = .speaking
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.state = .idle
            self.progress = 1.0
            self.currentWordRange = nil
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.state = .paused
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.state = .speaking
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            let text = utterance.speechString
            guard let range = Range(characterRange, in: text) else { return }

            self.currentWordRange = range

            // 進捗の更新
            let totalLength = text.count
            if totalLength > 0 {
                let endPosition = text.distance(from: text.startIndex, to: range.upperBound)
                self.progress = Double(endPosition) / Double(totalLength)
            }
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.state = .idle
            self.progress = 0.0
            self.currentWordRange = nil
        }
    }
}
