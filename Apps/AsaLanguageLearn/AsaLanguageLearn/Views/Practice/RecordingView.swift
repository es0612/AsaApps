//
//  RecordingView.swift
//  AsaLanguageLearn
//
//  録音画面（発音練習のメイン画面）
//

import SwiftData
import SwiftUI

struct RecordingView: View {
    @Bindable var viewModel: PracticeViewModel

    @State private var currentSpeedPreset: SpeechRatePreset = .normal
    @State private var showingSpeedPicker = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // ターゲットフレーズ
            targetPhraseSection

            // 発音ヒント
            if let tip = viewModel.currentItem?.pronunciationTip {
                pronunciationTipSection(tip: tip)
            }

            // 認識テキスト表示
            recognizedTextSection

            Spacer()

            // 波形表示
            WaveformView(
                audioLevel: viewModel.audioLevel,
                isActive: viewModel.isListening
            )
            .padding(.horizontal, 40)

            // コントロールボタン
            controlButtons

            Spacer()
        }
        .padding()
    }

    // MARK: - Target Phrase Section

    private var targetPhraseSection: some View {
        VStack(spacing: 12) {
            // 日本語訳
            Text(viewModel.currentItem?.japaneseText ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // 英語フレーズ
            Text(viewModel.currentItem?.englishText ?? "")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color("AsaDarkSlate"))
                .multilineTextAlignment(.center)

            // 発音記号
            if let pronunciation = viewModel.currentItem?.pronunciation {
                Text(pronunciation)
                    .font(.subheadline)
                    .foregroundColor(Color("AsaMocha"))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Pronunciation Tip Section

    private func pronunciationTipSection(tip: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)

            Text(tip)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recognized Text Section

    private var recognizedTextSection: some View {
        VStack(spacing: 8) {
            Text("認識中のテキスト")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(viewModel.recognizedText.isEmpty ? "..." : viewModel.recognizedText)
                .font(.title3)
                .foregroundColor(viewModel.recognizedText.isEmpty ? .secondary : Color("AsaDarkSlate"))
                .multilineTextAlignment(.center)
                .frame(minHeight: 30)
                .animation(.easeOut(duration: 0.2), value: viewModel.recognizedText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 30) {
            // 再生ボタン
            VStack(spacing: 4) {
                PlaybackButton(
                    isPlaying: viewModel.isSpeaking,
                    progress: viewModel.textToSpeechService.progress
                ) {
                    if viewModel.isSpeaking {
                        viewModel.stopPlayback()
                    } else {
                        viewModel.playModelPronunciation()
                    }
                }

                Text("お手本")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // マイクボタン
            VStack(spacing: 4) {
                MicButtonView(
                    isRecording: viewModel.isListening,
                    audioLevel: viewModel.audioLevel
                ) {
                    if viewModel.isListening {
                        viewModel.stopListeningAndEvaluate()
                    } else {
                        Task {
                            await viewModel.startListening()
                        }
                    }
                }

                Text(viewModel.isListening ? "タップで終了" : "タップで録音")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // 速度設定
            VStack(spacing: 4) {
                SpeedButton(currentPreset: currentSpeedPreset) {
                    showingSpeedPicker = true
                }
                .frame(width: 50, height: 50)

                Text("速度")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 20)
        .sheet(isPresented: $showingSpeedPicker) {
            speedPickerSheet
        }
    }

    // MARK: - Speed Picker Sheet

    private var speedPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(SpeechRatePreset.allCases, id: \.displayMultiplier) { preset in
                    Button {
                        currentSpeedPreset = preset
                        viewModel.textToSpeechService.speechRate = preset.rate
                        showingSpeedPicker = false
                    } label: {
                        HStack {
                            Image(systemName: preset.icon)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                                .frame(width: 24)

                            VStack(alignment: .leading) {
                                Text(preset.displayName)
                                    .foregroundColor(.primary)
                                Text(preset.displayMultiplier)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if currentSpeedPreset == preset {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("再生速度")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        showingSpeedPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: LearningItem.self, LearningProgress.self, configurations: config)

    let viewModel = PracticeViewModel(
        speechRecognitionService: MockSpeechRecognitionService(),
        textToSpeechService: MockTextToSpeechService(),
        modelContext: container.mainContext
    )

    RecordingView(viewModel: viewModel)
}
