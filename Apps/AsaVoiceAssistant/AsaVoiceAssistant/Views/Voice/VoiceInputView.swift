//
//  VoiceInputView.swift
//  AsaVoiceAssistant
//
//  音声入力メイン画面
//

import SwiftUI
import AsaUIKit

/// 音声入力メイン画面
///
/// マイクボタン、認識テキスト、状態表示を統合したメイン画面です。
struct VoiceInputView: View {
    // MARK: - Properties

    @Bindable var viewModel: VoiceAssistantViewModel

    @State private var showingConfirmation = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            AsaColors.softCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                headerSection

                Spacer()

                // メインコンテンツ
                VStack(spacing: 40) {
                    // 認識テキスト
                    RecognizedTextView(
                        text: viewModel.recognizedText,
                        isListening: viewModel.isListening
                    )
                    .padding(.horizontal, 20)

                    // マイクボタン
                    MicButtonView(
                        isListening: viewModel.isListening,
                        audioLevel: viewModel.audioLevel,
                        showWaveform: viewModel.settings.showWaveformAnimation,
                        onTap: handleMicTap
                    )

                    // 状態メッセージ
                    statusMessage
                }

                Spacer()

                // 今日のタスクサマリー
                if !viewModel.todayTasks.isEmpty {
                    todaySummary
                }
            }

            // コマンド確認オーバーレイ
            if case .confirming(let command) = viewModel.state {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.cancelCommand()
                    }

                CommandConfirmationView(
                    command: command,
                    onConfirm: {
                        viewModel.confirmAndExecute()
                    },
                    onCancel: {
                        viewModel.cancelCommand()
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.state)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("AsaVoiceAssistant")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.darkSlate)

            Text("声でタスクを管理")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
        }
        .padding(.top, 20)
    }

    private var statusMessage: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Text("マイクをタップして話しかけてください")
                    .font(.callout)
                    .foregroundColor(AsaColors.mutedSage)

            case .listening:
                Text("聞いています...")
                    .font(.callout)
                    .foregroundColor(.red)

            case .processing:
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("コマンドを解析中...")
                        .font(.callout)
                        .foregroundColor(AsaColors.coffeeBrown)
                }

            case .confirming:
                EmptyView()

            case .executing:
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("実行中...")
                        .font(.callout)
                        .foregroundColor(AsaColors.coffeeBrown)
                }

            case .success(let message):
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(message)
                        .font(.callout)
                        .foregroundColor(.green)
                }

            case .error(let message):
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(message)
                        .font(.callout)
                        .foregroundColor(.red)
                }
            }
        }
        .frame(height: 30)
    }

    private var todaySummary: some View {
        VStack(spacing: 8) {
            Divider()

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AsaColors.coffeeBrown)

                Text("今日のタスク")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text("\(viewModel.todayTasks.count)件")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.coffeeBrown)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }

    // MARK: - Actions

    private func handleMicTap() {
        if viewModel.isListening {
            viewModel.stopListeningAndProcess()
        } else {
            Task {
                await viewModel.startListening()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let dataService = DataService(inMemory: true)
    let viewModel = VoiceAssistantViewModel(dataService: dataService)

    return VoiceInputView(viewModel: viewModel)
}
