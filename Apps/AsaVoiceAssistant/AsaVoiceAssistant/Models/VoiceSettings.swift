//
//  VoiceSettings.swift
//  AsaVoiceAssistant
//
//  音声アシスタント設定モデル
//

import Foundation
import SwiftData

/// 音声アシスタントの設定
///
/// Swift Dataを使用して永続化されるユーザー設定モデルです。
/// 音声認識、音声合成、UI表示に関する設定を管理します。
@Model
final class VoiceSettings {
    // MARK: - Properties

    /// 一意識別子
    @Attribute(.unique) var id: UUID

    // MARK: - 音声認識設定

    /// 音声認識言語（ja-JP固定）
    var speechRecognitionLocale: String

    /// 自動的に音声認識を停止するまでの無音時間（秒）
    var silenceTimeout: Double

    /// 音声認識の最大時間（秒）
    var maxRecordingDuration: Double

    // MARK: - 音声合成設定

    /// 音声フィードバックを有効にする
    var enableVoiceFeedback: Bool

    /// 読み上げ速度（0.0〜1.0、デフォルト0.5）
    var speechRate: Double

    /// 読み上げピッチ（0.5〜2.0、デフォルト1.0）
    var speechPitch: Double

    /// 読み上げ音量（0.0〜1.0、デフォルト1.0）
    var speechVolume: Double

    // MARK: - UI設定

    /// コマンド確認ダイアログを表示する
    var showCommandConfirmation: Bool

    /// 波形アニメーションを表示する
    var showWaveformAnimation: Bool

    /// ダークモード設定（nil=システム設定に従う）
    var appearanceMode: String?

    // MARK: - タスク設定

    /// デフォルトの優先度
    var defaultPriorityRawValue: String

    /// デフォルトのカテゴリ
    var defaultCategoryRawValue: String

    // MARK: - メタデータ

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    // MARK: - Computed Properties

    /// デフォルト優先度（enum）
    var defaultPriority: PriorityLevel {
        get { PriorityLevel(rawValue: defaultPriorityRawValue) ?? .medium }
        set { defaultPriorityRawValue = newValue.rawValue }
    }

    /// デフォルトカテゴリ（enum）
    var defaultCategory: TaskCategory {
        get { TaskCategory(rawValue: defaultCategoryRawValue) ?? .other }
        set { defaultCategoryRawValue = newValue.rawValue }
    }

    // MARK: - Initializer

    init() {
        self.id = UUID()

        // 音声認識設定のデフォルト値
        self.speechRecognitionLocale = "ja-JP"
        self.silenceTimeout = 2.0
        self.maxRecordingDuration = 30.0

        // 音声合成設定のデフォルト値
        self.enableVoiceFeedback = true
        self.speechRate = 0.5
        self.speechPitch = 1.0
        self.speechVolume = 1.0

        // UI設定のデフォルト値
        self.showCommandConfirmation = true
        self.showWaveformAnimation = true
        self.appearanceMode = nil

        // タスク設定のデフォルト値
        self.defaultPriorityRawValue = PriorityLevel.medium.rawValue
        self.defaultCategoryRawValue = TaskCategory.other.rawValue

        // メタデータ
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// 設定を更新
    func update() {
        self.updatedAt = Date()
    }

    /// デフォルト設定にリセット
    func resetToDefaults() {
        self.silenceTimeout = 2.0
        self.maxRecordingDuration = 30.0
        self.enableVoiceFeedback = true
        self.speechRate = 0.5
        self.speechPitch = 1.0
        self.speechVolume = 1.0
        self.showCommandConfirmation = true
        self.showWaveformAnimation = true
        self.appearanceMode = nil
        self.defaultPriorityRawValue = PriorityLevel.medium.rawValue
        self.defaultCategoryRawValue = TaskCategory.other.rawValue
        self.updatedAt = Date()
    }
}
