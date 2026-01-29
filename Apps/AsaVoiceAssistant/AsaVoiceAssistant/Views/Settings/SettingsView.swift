//
//  SettingsView.swift
//  AsaVoiceAssistant
//
//  設定画面
//

import SwiftUI
import AsaUIKit

/// 設定画面
///
/// 音声認識、音声合成、UI、タスクの各種設定を管理する画面です。
struct SettingsView: View {
    // MARK: - Properties

    @Bindable var viewModel: VoiceAssistantViewModel
    @State private var settingsViewModel: SettingsViewModel

    @State private var showingResetConfirmation = false

    // MARK: - Initialization

    init(viewModel: VoiceAssistantViewModel) {
        self.viewModel = viewModel
        self._settingsViewModel = State(initialValue: SettingsViewModel(
            dataService: DataService(inMemory: false),
            mainViewModel: viewModel
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 音声認識設定
                speechRecognitionSection

                // 音声合成設定
                speechSynthesisSection

                // UI設定
                uiSection

                // タスク設定
                taskSection

                // 権限設定
                permissionSection

                // リセット
                resetSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if settingsViewModel.hasUnsavedChanges {
                        Button("保存") {
                            settingsViewModel.saveSettings()
                        }
                    }
                }
            }
            .alert("設定をリセット", isPresented: $showingResetConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) {
                    settingsViewModel.resetToDefaults()
                }
            } message: {
                Text("すべての設定をデフォルト値に戻しますか？")
            }
        }
    }

    // MARK: - Sections

    private var speechRecognitionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("無音タイムアウト")
                    Spacer()
                    Text("\(Int(settingsViewModel.silenceTimeout))秒")
                        .foregroundColor(AsaColors.mutedSage)
                }

                Slider(value: $settingsViewModel.silenceTimeout, in: 1...5, step: 0.5)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("最大録音時間")
                    Spacer()
                    Text("\(Int(settingsViewModel.maxRecordingDuration))秒")
                        .foregroundColor(AsaColors.mutedSage)
                }

                Slider(value: $settingsViewModel.maxRecordingDuration, in: 10...60, step: 5)
            }
        } header: {
            Label("音声認識", systemImage: "mic.fill")
        } footer: {
            Text("無音タイムアウト: 話し終わってから自動停止するまでの時間")
        }
    }

    private var speechSynthesisSection: some View {
        Section {
            Toggle("音声フィードバック", isOn: $settingsViewModel.enableVoiceFeedback)

            if settingsViewModel.enableVoiceFeedback {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("読み上げ速度")
                        Spacer()
                        Text(speedLabel)
                            .foregroundColor(AsaColors.mutedSage)
                    }

                    Slider(value: $settingsViewModel.speechRate, in: 0.25...0.75, step: 0.05)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("読み上げピッチ")
                        Spacer()
                        Text(pitchLabel)
                            .foregroundColor(AsaColors.mutedSage)
                    }

                    Slider(value: $settingsViewModel.speechPitch, in: 0.75...1.25, step: 0.05)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("読み上げ音量")
                        Spacer()
                        Text("\(Int(settingsViewModel.speechVolume * 100))%")
                            .foregroundColor(AsaColors.mutedSage)
                    }

                    Slider(value: $settingsViewModel.speechVolume, in: 0.5...1.0, step: 0.1)
                }

                Button(action: settingsViewModel.testSpeech) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("テスト再生")
                    }
                }
            }
        } header: {
            Label("音声合成", systemImage: "speaker.wave.2.fill")
        } footer: {
            Text("コマンド実行後に結果を音声で読み上げます")
        }
    }

    private var uiSection: some View {
        Section {
            Toggle("コマンド確認ダイアログ", isOn: $settingsViewModel.showCommandConfirmation)

            Toggle("波形アニメーション", isOn: $settingsViewModel.showWaveformAnimation)
        } header: {
            Label("表示", systemImage: "paintbrush.fill")
        } footer: {
            Text("確認ダイアログをオフにすると、認識されたコマンドは即座に実行されます")
        }
    }

    private var taskSection: some View {
        Section {
            Picker("デフォルト優先度", selection: $settingsViewModel.defaultPriority) {
                ForEach(PriorityLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }

            Picker("デフォルトカテゴリ", selection: $settingsViewModel.defaultCategory) {
                ForEach(TaskCategory.allCases) { cat in
                    Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                }
            }
        } header: {
            Label("タスク", systemImage: "checklist")
        } footer: {
            Text("音声で作成したタスクのデフォルト値")
        }
    }

    private var permissionSection: some View {
        Section {
            HStack {
                Text("マイク")
                Spacer()
                permissionStatusView(viewModel.permissionService.microphoneStatus)
            }

            HStack {
                Text("音声認識")
                Spacer()
                permissionStatusView(viewModel.permissionService.speechRecognitionStatus)
            }

            if !viewModel.permissionService.isFullyAuthorized {
                Button(action: viewModel.permissionService.openSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("設定を開く")
                    }
                }
            }
        } header: {
            Label("権限", systemImage: "lock.shield.fill")
        }
    }

    private var resetSection: some View {
        Section {
            Button(action: { showingResetConfirmation = true }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("設定をリセット")
                }
                .foregroundColor(.red)
            }
        }
    }

    // MARK: - Helper Views

    private func permissionStatusView(_ status: PermissionStatus) -> some View {
        HStack(spacing: 4) {
            switch status {
            case .authorized:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("許可済み")
                    .foregroundColor(.green)
            case .denied:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("拒否")
                    .foregroundColor(.red)
            case .restricted:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                Text("制限")
                    .foregroundColor(.orange)
            case .notDetermined:
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(AsaColors.mutedSage)
                Text("未確認")
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
        .font(.caption)
    }

    // MARK: - Helper

    private var speedLabel: String {
        let rate = settingsViewModel.speechRate
        if rate < 0.4 {
            return "遅い"
        } else if rate > 0.6 {
            return "速い"
        } else {
            return "普通"
        }
    }

    private var pitchLabel: String {
        let pitch = settingsViewModel.speechPitch
        if pitch < 0.9 {
            return "低い"
        } else if pitch > 1.1 {
            return "高い"
        } else {
            return "普通"
        }
    }
}

// MARK: - Preview

#Preview {
    let dataService = DataService(inMemory: true)
    let viewModel = VoiceAssistantViewModel(dataService: dataService)

    return SettingsView(viewModel: viewModel)
}
