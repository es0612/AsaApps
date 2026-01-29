//
//  SettingsViewModel.swift
//  AsaVoiceAssistant
//
//  設定画面用ViewModel
//

import Foundation

/// 設定画面用ViewModel
///
/// 音声認識、音声合成、UI、タスクの各種設定を管理します。
@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Dependencies

    private let dataService: DataService
    private weak var mainViewModel: VoiceAssistantViewModel?

    // MARK: - State

    /// 設定オブジェクト
    private(set) var settings: VoiceSettings

    /// 変更が保存されていないか
    private(set) var hasUnsavedChanges = false

    /// 保存中フラグ
    private(set) var isSaving = false

    // MARK: - Binding Properties

    /// 無音タイムアウト（秒）
    var silenceTimeout: Double {
        get { settings.silenceTimeout }
        set {
            settings.silenceTimeout = newValue
            hasUnsavedChanges = true
        }
    }

    /// 最大録音時間（秒）
    var maxRecordingDuration: Double {
        get { settings.maxRecordingDuration }
        set {
            settings.maxRecordingDuration = newValue
            hasUnsavedChanges = true
        }
    }

    /// 音声フィードバック有効
    var enableVoiceFeedback: Bool {
        get { settings.enableVoiceFeedback }
        set {
            settings.enableVoiceFeedback = newValue
            hasUnsavedChanges = true
        }
    }

    /// 読み上げ速度
    var speechRate: Double {
        get { settings.speechRate }
        set {
            settings.speechRate = newValue
            hasUnsavedChanges = true
        }
    }

    /// 読み上げピッチ
    var speechPitch: Double {
        get { settings.speechPitch }
        set {
            settings.speechPitch = newValue
            hasUnsavedChanges = true
        }
    }

    /// 読み上げ音量
    var speechVolume: Double {
        get { settings.speechVolume }
        set {
            settings.speechVolume = newValue
            hasUnsavedChanges = true
        }
    }

    /// コマンド確認ダイアログ表示
    var showCommandConfirmation: Bool {
        get { settings.showCommandConfirmation }
        set {
            settings.showCommandConfirmation = newValue
            hasUnsavedChanges = true
        }
    }

    /// 波形アニメーション表示
    var showWaveformAnimation: Bool {
        get { settings.showWaveformAnimation }
        set {
            settings.showWaveformAnimation = newValue
            hasUnsavedChanges = true
        }
    }

    /// デフォルト優先度
    var defaultPriority: PriorityLevel {
        get { settings.defaultPriority }
        set {
            settings.defaultPriority = newValue
            hasUnsavedChanges = true
        }
    }

    /// デフォルトカテゴリ
    var defaultCategory: TaskCategory {
        get { settings.defaultCategory }
        set {
            settings.defaultCategory = newValue
            hasUnsavedChanges = true
        }
    }

    // MARK: - Initialization

    init(dataService: DataService, mainViewModel: VoiceAssistantViewModel? = nil) {
        self.dataService = dataService
        self.mainViewModel = mainViewModel
        self.settings = dataService.getSettings()
    }

    // MARK: - Public Methods

    /// 設定を保存
    func saveSettings() {
        isSaving = true

        settings.update()
        dataService.updateSettings(settings)

        // メインViewModelに設定変更を通知
        mainViewModel?.updateSettings()

        hasUnsavedChanges = false
        isSaving = false
    }

    /// 設定をリセット
    func resetToDefaults() {
        settings.resetToDefaults()
        dataService.updateSettings(settings)

        // メインViewModelに設定変更を通知
        mainViewModel?.resetSettings()

        hasUnsavedChanges = false
    }

    /// 変更を破棄して元に戻す
    func discardChanges() {
        settings = dataService.getSettings()
        hasUnsavedChanges = false
    }

    /// 読み上げテスト
    func testSpeech() {
        // メインViewModelのTextToSpeechServiceを使用
        mainViewModel?.textToSpeechService.configure(
            rate: Float(speechRate),
            pitch: Float(speechPitch),
            volume: Float(speechVolume)
        )
        mainViewModel?.textToSpeechService.speak("これはテスト音声です。設定が正しく反映されています。")
    }
}
