//
//  SpeechRecognitionService.swift
//  AsaLanguageLearn
//
//  音声認識サービスの実装
//

import AVFoundation
import Foundation
import Speech

/// 音声認識サービス
/// SFSpeechRecognizerを使用したリアルタイム音声認識
@MainActor
@Observable
final class SpeechRecognitionService: NSObject, SpeechRecognitionServiceProtocol {
    // MARK: - Properties

    private(set) var state: RecognitionState = .idle
    private(set) var recognizedText: String = ""
    private(set) var finalText: String = ""
    private(set) var audioLevel: Float = 0.0

    var recognitionLocale: Locale = Locale(identifier: "en-US")
    var silenceTimeout: TimeInterval = 2.0
    var maxDuration: TimeInterval = 30.0

    // MARK: - Private Properties

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private var maxDurationTimer: Timer?

    // MARK: - Initialization

    override init() {
        super.init()
        setupRecognizer()
    }

    private func setupRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: recognitionLocale)
        speechRecognizer?.delegate = self
    }

    // MARK: - Permission Methods

    func checkMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return AVAudioSession.sharedInstance().recordPermission == .granted
        }
    }

    func checkSpeechRecognitionPermission() async -> Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    func requestPermissions() async -> Bool {
        // マイク権限
        let micGranted = await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        guard micGranted else { return false }

        // 音声認識権限
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        return speechGranted
    }

    // MARK: - Recognition Methods

    func startRecognition() async throws {
        // 権限チェック
        guard await checkMicrophonePermission() else {
            throw SpeechRecognitionError.microphonePermissionDenied
        }

        guard await checkSpeechRecognitionPermission() else {
            throw SpeechRecognitionError.speechRecognitionPermissionDenied
        }

        // 言語が変更されていたら再設定
        if speechRecognizer?.locale != recognitionLocale {
            setupRecognizer()
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerNotAvailable
        }

        // 既存の認識をキャンセル
        stopRecognition()

        // オーディオセッションの設定
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechRecognitionError.audioEngineError(error.localizedDescription)
        }

        // 認識リクエストの作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.recognitionFailed("リクエストの作成に失敗しました")
        }

        recognitionRequest.shouldReportPartialResults = true

        // オフライン認識を優先（可能な場合）
        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
        }

        // オーディオ入力の設定
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            Task { @MainActor [weak self] in
                self?.updateAudioLevel(buffer: buffer)
            }
        }

        // オーディオエンジンの開始
        do {
            try audioEngine.start()
        } catch {
            throw SpeechRecognitionError.audioEngineError(error.localizedDescription)
        }

        state = .listening
        recognizedText = ""
        finalText = ""

        // 認識タスクの開始
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                self?.handleRecognitionResult(result: result, error: error)
            }
        }

        // タイマーの設定
        startTimers()
    }

    func stopRecognition() {
        cancelTimers()

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        if state == .listening || state == .processing {
            state = .finished
            finalText = recognizedText
        }

        audioLevel = 0.0
    }

    func reset() {
        stopRecognition()
        state = .idle
        recognizedText = ""
        finalText = ""
        audioLevel = 0.0
    }

    // MARK: - Private Methods

    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            state = .error(error.localizedDescription)
            stopRecognition()
            return
        }

        guard let result = result else { return }

        recognizedText = result.bestTranscription.formattedString

        // 無音タイマーをリセット
        resetSilenceTimer()

        if result.isFinal {
            finalText = recognizedText
            state = .finished
            stopRecognition()
        }
    }

    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0

        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }

        let rms = sqrt(sum / Float(frameLength))
        // 0〜1の範囲に正規化（適切なスケーリング）
        let normalizedLevel = min(1.0, rms * 10)

        audioLevel = normalizedLevel
    }

    // MARK: - Timer Management

    private func startTimers() {
        // 無音タイマー
        silenceTimer = Timer.scheduledTimer(
            withTimeInterval: silenceTimeout,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSilenceTimeout()
            }
        }

        // 最大時間タイマー
        maxDurationTimer = Timer.scheduledTimer(
            withTimeInterval: maxDuration,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMaxDurationTimeout()
            }
        }
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(
            withTimeInterval: silenceTimeout,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSilenceTimeout()
            }
        }
    }

    private func cancelTimers() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        maxDurationTimer?.invalidate()
        maxDurationTimer = nil
    }

    private func handleSilenceTimeout() {
        if state == .listening && !recognizedText.isEmpty {
            state = .processing
            stopRecognition()
        }
    }

    private func handleMaxDurationTimeout() {
        if state == .listening {
            stopRecognition()
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognitionService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(
        _ speechRecognizer: SFSpeechRecognizer,
        availabilityDidChange available: Bool
    ) {
        Task { @MainActor in
            if !available {
                self.state = .error("音声認識が利用できません")
            }
        }
    }
}
