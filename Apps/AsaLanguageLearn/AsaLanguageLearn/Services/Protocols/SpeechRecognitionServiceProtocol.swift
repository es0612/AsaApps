//
//  SpeechRecognitionServiceProtocol.swift
//  AsaLanguageLearn
//
//  音声認識サービスのプロトコル定義
//

import Foundation

/// 音声認識の状態
enum RecognitionState: Sendable, Equatable {
    case idle
    case listening
    case processing
    case finished
    case error(String)

    var isActive: Bool {
        switch self {
        case .listening, .processing: return true
        default: return false
        }
    }
}

/// 音声認識サービスのプロトコル
/// iOS 26のSpeechAnalyzer APIへの移行を見据えた抽象化
@MainActor
protocol SpeechRecognitionServiceProtocol: AnyObject {
    // MARK: - State

    /// 現在の認識状態
    var state: RecognitionState { get }

    /// リアルタイム認識テキスト（部分結果）
    var recognizedText: String { get }

    /// 確定テキスト（最終結果）
    var finalText: String { get }

    /// 音声レベル（0.0〜1.0）波形表示用
    var audioLevel: Float { get }

    // MARK: - Configuration

    /// 認識言語（デフォルト: en-US）
    var recognitionLocale: Locale { get set }

    /// 無音タイムアウト（秒）
    var silenceTimeout: TimeInterval { get set }

    /// 最大録音時間（秒）
    var maxDuration: TimeInterval { get set }

    // MARK: - Permissions

    /// マイク権限の状態を確認
    func checkMicrophonePermission() async -> Bool

    /// 音声認識権限の状態を確認
    func checkSpeechRecognitionPermission() async -> Bool

    /// 両方の権限をリクエスト
    func requestPermissions() async -> Bool

    // MARK: - Recognition

    /// 音声認識を開始
    func startRecognition() async throws

    /// 音声認識を停止
    func stopRecognition()

    /// 認識結果をリセット
    func reset()
}

/// 音声認識サービスのエラー
enum SpeechRecognitionError: Error, LocalizedError, Sendable {
    case microphonePermissionDenied
    case speechRecognitionPermissionDenied
    case recognizerNotAvailable
    case audioEngineError(String)
    case recognitionFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "マイクへのアクセスが許可されていません。設定アプリから許可してください。"
        case .speechRecognitionPermissionDenied:
            return "音声認識へのアクセスが許可されていません。設定アプリから許可してください。"
        case .recognizerNotAvailable:
            return "音声認識が利用できません。言語設定を確認してください。"
        case .audioEngineError(let message):
            return "音声入力エラー: \(message)"
        case .recognitionFailed(let message):
            return "音声認識エラー: \(message)"
        case .timeout:
            return "音声認識がタイムアウトしました。"
        }
    }
}
