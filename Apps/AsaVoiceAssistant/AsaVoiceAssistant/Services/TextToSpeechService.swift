//
//  TextToSpeechService.swift
//  AsaVoiceAssistant
//
//  音声合成サービス（AVSpeechSynthesizer使用）
//

import Foundation
import AVFoundation

/// 音声合成の状態
enum SpeechState: Sendable {
    case idle       // 待機中
    case speaking   // 読み上げ中
    case paused     // 一時停止中
}

/// 音声合成サービス
///
/// AVSpeechSynthesizerを使用した日本語テキスト読み上げ機能を提供します。
/// タスク一覧の読み上げや、コマンド実行結果のフィードバックに使用されます。
@MainActor
@Observable
final class TextToSpeechService: NSObject {
    // MARK: - Properties

    /// 読み上げ状態
    private(set) var state: SpeechState = .idle

    /// 読み上げ中のテキスト
    private(set) var currentText: String = ""

    /// 読み上げ進捗（0.0〜1.0）
    private(set) var progress: Double = 0.0

    // MARK: - Settings

    /// 読み上げ速度（0.0〜1.0、デフォルト0.5）
    var speechRate: Float = 0.5

    /// 読み上げピッチ（0.5〜2.0、デフォルト1.0）
    var speechPitch: Float = 1.0

    /// 読み上げ音量（0.0〜1.0、デフォルト1.0）
    var speechVolume: Float = 1.0

    // MARK: - Private Properties

    private let synthesizer = AVSpeechSynthesizer()
    private let japaneseVoice: AVSpeechSynthesisVoice?
    private var totalCharacters: Int = 0
    private var spokenCharacters: Int = 0

    // MARK: - Initialization

    override init() {
        // 日本語音声を取得（Siri音声を優先）
        self.japaneseVoice = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("ja") }
            .sorted { ($0.quality.rawValue, $0.identifier) > ($1.quality.rawValue, $1.identifier) }
            .first ?? AVSpeechSynthesisVoice(language: "ja-JP")

        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public Methods

    /// 設定を更新
    func configure(rate: Float, pitch: Float, volume: Float) {
        speechRate = rate
        speechPitch = pitch
        speechVolume = volume
    }

    /// テキストを読み上げ
    /// - Parameter text: 読み上げるテキスト
    func speak(_ text: String) {
        // 既に読み上げ中の場合は停止
        if state == .speaking {
            stop()
        }

        guard !text.isEmpty else { return }

        currentText = text
        totalCharacters = text.count
        spokenCharacters = 0
        progress = 0.0

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = japaneseVoice
        utterance.rate = speechRate * AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume

        // 読み上げ開始前に少し間を置く
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        state = .speaking
        synthesizer.speak(utterance)
    }

    /// 複数のテキストを連続で読み上げ
    /// - Parameter texts: 読み上げるテキストの配列
    func speakMultiple(_ texts: [String]) {
        let combinedText = texts.joined(separator: "、")
        speak(combinedText)
    }

    /// タスクリストを読み上げ
    /// - Parameter tasks: 読み上げるタスクの配列
    func speakTasks(_ tasks: [VoiceTask]) {
        if tasks.isEmpty {
            speak("タスクはありません")
            return
        }

        var speechText = "タスクが\(tasks.count)件あります。"

        for (index, task) in tasks.prefix(5).enumerated() {
            speechText += "\(index + 1)番、\(task.toSpeechText())。"
        }

        if tasks.count > 5 {
            speechText += "他に\(tasks.count - 5)件のタスクがあります。"
        }

        speak(speechText)
    }

    /// コマンド実行結果を読み上げ
    /// - Parameters:
    ///   - command: 実行されたコマンド
    ///   - success: 成功したかどうか
    func speakCommandResult(_ command: VoiceCommand, success: Bool) {
        var text: String

        if success {
            switch command.intent {
            case .createTask:
                text = "タスク「\(command.taskTitle ?? "")」を作成しました"
            case .completeTask:
                text = "タスクを完了しました"
            case .deleteTask:
                text = "タスクを削除しました"
            case .listTasks:
                text = "タスク一覧を表示しました"
            case .readTasks:
                // readTasksは別途タスクリストを読み上げるので、ここでは何も言わない
                return
            case .unknown:
                text = "コマンドを認識できませんでした"
            }
        } else {
            text = "処理に失敗しました。もう一度お試しください"
        }

        speak(text)
    }

    /// 読み上げを一時停止
    func pause() {
        guard state == .speaking else { return }
        synthesizer.pauseSpeaking(at: .word)
        state = .paused
    }

    /// 読み上げを再開
    func resume() {
        guard state == .paused else { return }
        synthesizer.continueSpeaking()
        state = .speaking
    }

    /// 読み上げを停止
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        state = .idle
        currentText = ""
        progress = 0.0
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .speaking
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.spokenCharacters = characterRange.location + characterRange.length
            if self.totalCharacters > 0 {
                self.progress = Double(self.spokenCharacters) / Double(self.totalCharacters)
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .idle
            self.progress = 1.0
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .idle
            self.progress = 0.0
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .paused
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .speaking
        }
    }
}
