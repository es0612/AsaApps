//
//  SpeechRecognitionService.swift
//  AsaVoiceAssistant
//
//  音声認識サービス（Speech Framework使用）
//

import Foundation
import Speech
import AVFoundation

/// 音声認識の状態を表すenum
enum RecognitionState: Sendable, Equatable {
    case idle           // 待機中
    case listening      // 音声入力中
    case processing     // 処理中
    case finished       // 完了
    case error(String)  // エラー
}

/// 音声認識サービス
///
/// Apple Speech Frameworkを使用したリアルタイム日本語音声認識を提供します。
/// `AVAudioEngine`でマイク入力をキャプチャし、`SFSpeechRecognizer`で
/// テキストに変換します。
@MainActor
@Observable
final class SpeechRecognitionService: NSObject {
    // MARK: - Properties

    /// 認識状態
    private(set) var state: RecognitionState = .idle

    /// 認識中のテキスト（リアルタイム更新）
    private(set) var recognizedText: String = ""

    /// 認識が確定したテキスト
    private(set) var finalText: String = ""

    /// 音声レベル（波形表示用、0.0〜1.0）
    private(set) var audioLevel: Float = 0.0

    /// エラーメッセージ
    private(set) var errorMessage: String?

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var silenceTimer: Timer?
    private var maxDurationTimer: Timer?

    // 設定
    private var silenceTimeout: Double = 2.0
    private var maxRecordingDuration: Double = 30.0

    // MARK: - Initialization

    override init() {
        // 日本語の音声認識器を初期化
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
        super.init()
        speechRecognizer?.delegate = self
    }

    // MARK: - Public Methods

    /// 設定を更新
    func configure(silenceTimeout: Double, maxDuration: Double) {
        self.silenceTimeout = silenceTimeout
        self.maxRecordingDuration = maxDuration
    }

    /// 音声認識を開始
    func startRecognition() async throws {
        // 既に認識中の場合は停止
        if state == .listening {
            stopRecognition()
            return
        }

        // 音声認識器の可用性チェック
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            state = .error("音声認識が利用できません")
            errorMessage = "音声認識が利用できません。インターネット接続を確認してください。"
            throw NSError(domain: "SpeechRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "音声認識が利用できません"])
        }

        // 状態をリセット
        recognizedText = ""
        finalText = ""
        errorMessage = nil

        // オーディオセッションを設定
        try await setupAudioSession()

        // オーディオエンジンを設定
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "SpeechRecognition", code: -2, userInfo: [NSLocalizedDescriptionKey: "オーディオエンジンの初期化に失敗"])
        }

        // 認識リクエストを作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            throw NSError(domain: "SpeechRecognition", code: -3, userInfo: [NSLocalizedDescriptionKey: "認識リクエストの作成に失敗"])
        }

        // リアルタイム認識を有効化
        request.shouldReportPartialResults = true

        // オンデバイス認識を試行（iOS 17+、オフライン対応）
        if #available(iOS 17.0, *) {
            request.requiresOnDeviceRecognition = false  // オフラインでも動作するが、オンラインの方が精度が高い
        }

        // 入力ノードを取得
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // 音声データをリクエストに渡す
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // 音声レベルを更新
            Task { @MainActor in
                self?.updateAudioLevel(buffer: buffer)
            }
        }

        // 認識タスクを開始
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result: result, error: error)
            }
        }

        // オーディオエンジンを開始
        audioEngine.prepare()
        try audioEngine.start()

        state = .listening

        // 最大録音時間タイマーを開始
        startMaxDurationTimer()

        // 無音検出タイマーを開始
        resetSilenceTimer()
    }

    /// 音声認識を停止
    func stopRecognition() {
        // タイマーを停止
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil

        // オーディオエンジンを停止
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        // 認識リクエストを終了
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // 認識タスクをキャンセル
        recognitionTask?.cancel()
        recognitionTask = nil

        audioEngine = nil
        audioLevel = 0.0

        // 最終テキストを確定
        if !recognizedText.isEmpty {
            finalText = recognizedText
            state = .finished
        } else {
            state = .idle
        }
    }

    /// 認識をキャンセル
    func cancelRecognition() {
        stopRecognition()
        recognizedText = ""
        finalText = ""
        state = .idle
    }

    // MARK: - Private Methods

    /// オーディオセッションを設定
    private func setupAudioSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// 認識結果を処理
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            // エラー処理
            let nsError = error as NSError

            // キャンセルは正常終了として扱う
            if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                // "認識がキャンセルされました"
                return
            }

            state = .error(error.localizedDescription)
            errorMessage = "音声認識エラー: \(error.localizedDescription)"
            stopRecognition()
            return
        }

        guard let result = result else { return }

        // 認識テキストを更新
        recognizedText = result.bestTranscription.formattedString

        // 無音タイマーをリセット
        resetSilenceTimer()

        // 認識が確定した場合
        if result.isFinal {
            finalText = recognizedText
            state = .finished
            stopRecognition()
        }
    }

    /// 音声レベルを更新
    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))

        // dBを0-1の範囲に正規化
        let avgPower = 20 * log10(rms)
        let normalizedLevel = max(0.0, min(1.0, (avgPower + 50) / 50))

        audioLevel = normalizedLevel
    }

    /// 無音検出タイマーをリセット
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopRecognition()
            }
        }
    }

    /// 最大録音時間タイマーを開始
    private func startMaxDurationTimer() {
        maxDurationTimer?.invalidate()
        maxDurationTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopRecognition()
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                self.state = .error("音声認識が利用できなくなりました")
                self.errorMessage = "音声認識が利用できなくなりました"
                self.stopRecognition()
            }
        }
    }
}
