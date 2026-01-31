//
//  TextToSpeechServiceProtocol.swift
//  AsaLanguageLearn
//
//  音声合成サービスのプロトコル定義
//

import Foundation

/// 音声合成の状態
enum SpeechState: Sendable, Equatable {
    case idle
    case speaking
    case paused
}

/// 音声合成サービスのプロトコル
@MainActor
protocol TextToSpeechServiceProtocol: AnyObject {
    // MARK: - State

    /// 現在の状態
    var state: SpeechState { get }

    /// 読み上げ進捗（0.0〜1.0）
    var progress: Double { get }

    /// 現在読み上げ中の単語の範囲
    var currentWordRange: Range<String.Index>? { get }

    // MARK: - Configuration

    /// 音声速度（0.0〜1.0、デフォルト: 0.5）
    /// アプリ内では 0.3x〜1.3x の5段階で表示
    var speechRate: Float { get set }

    /// 音声ピッチ（0.5〜2.0、デフォルト: 1.0）
    var speechPitch: Float { get set }

    /// 音声ボリューム（0.0〜1.0、デフォルト: 1.0）
    var speechVolume: Float { get set }

    /// 音声言語（デフォルト: en-US）
    var speechLocale: Locale { get set }

    // MARK: - Playback

    /// テキストを読み上げる
    func speak(_ text: String)

    /// 一時停止
    func pause()

    /// 再開
    func resume()

    /// 停止
    func stop()

    // MARK: - Utility

    /// 利用可能な音声を取得
    func availableVoices() -> [VoiceInfo]
}

/// 音声情報
struct VoiceInfo: Identifiable, Sendable {
    let id: String
    let name: String
    let language: String
    let quality: VoiceQuality
}

/// 音声品質
enum VoiceQuality: Int, Comparable, Sendable {
    case `default` = 0
    case enhanced = 1
    case premium = 2

    static func < (lhs: VoiceQuality, rhs: VoiceQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .default: return "標準"
        case .enhanced: return "高品質"
        case .premium: return "プレミアム"
        }
    }
}

/// 音声速度のプリセット
enum SpeechRatePreset: CaseIterable, Sendable {
    case verySlow   // 0.3x
    case slow       // 0.5x
    case normal     // 0.8x
    case fast       // 1.0x
    case veryFast   // 1.3x

    var rate: Float {
        switch self {
        case .verySlow: return 0.3
        case .slow: return 0.4
        case .normal: return 0.5
        case .fast: return 0.55
        case .veryFast: return 0.65
        }
    }

    var displayMultiplier: String {
        switch self {
        case .verySlow: return "0.3x"
        case .slow: return "0.5x"
        case .normal: return "0.8x"
        case .fast: return "1.0x"
        case .veryFast: return "1.3x"
        }
    }

    var displayName: String {
        switch self {
        case .verySlow: return "とてもゆっくり"
        case .slow: return "ゆっくり"
        case .normal: return "普通"
        case .fast: return "速い"
        case .veryFast: return "とても速い"
        }
    }

    var icon: String {
        switch self {
        case .verySlow: return "tortoise.fill"
        case .slow: return "gauge.with.dots.needle.0percent"
        case .normal: return "gauge.with.dots.needle.50percent"
        case .fast: return "gauge.with.dots.needle.67percent"
        case .veryFast: return "hare.fill"
        }
    }
}
