//
//  ContentView.swift
//  AsaVoiceAssistant
//
//  メインContentView - タブビュー構成
//

import SwiftUI
import AsaUIKit

/// メインContentView
///
/// アプリのルートビューとして、タブビューで各画面を統合します。
/// - 音声入力画面
/// - タスク一覧画面
/// - 設定画面
struct ContentView: View {
    // MARK: - Properties

    @State private var viewModel: VoiceAssistantViewModel
    @State private var selectedTab: Tab = .voice

    // MARK: - Initialization

    init(dataService: DataService) {
        self._viewModel = State(initialValue: VoiceAssistantViewModel(dataService: dataService))
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // 音声入力タブ
            VoiceInputView(viewModel: viewModel)
                .tabItem {
                    Label("音声", systemImage: "mic.fill")
                }
                .tag(Tab.voice)

            // タスク一覧タブ
            TaskListView(viewModel: viewModel)
                .tabItem {
                    Label("タスク", systemImage: "checklist")
                }
                .tag(Tab.tasks)
                .badge(viewModel.activeTasks.count)

            // 設定タブ
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .tint(AsaColors.coffeeBrown)
        .task {
            await viewModel.initialize()
        }
        .overlay {
            // 権限が必要な場合のオーバーレイ
            if !viewModel.permissionService.isFullyAuthorized && !viewModel.isLoading {
                permissionRequiredOverlay
            }
        }
    }

    // MARK: - Subviews

    private var permissionRequiredOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                VStack(spacing: 8) {
                    Text("権限が必要です")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("音声アシスタントを使用するには\nマイクと音声認識の権限が必要です")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    // 権限リクエストボタン
                    Button(action: {
                        Task {
                            await viewModel.permissionService.requestAllPermissions()
                        }
                    }) {
                        Text("権限を許可")
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                            )
                    }

                    // 設定を開くボタン
                    Button(action: {
                        viewModel.permissionService.openSettings()
                    }) {
                        Text("設定を開く")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(40)
        }
    }

    // MARK: - Tab Enum

    private enum Tab {
        case voice
        case tasks
        case settings
    }
}

// MARK: - Preview

#Preview {
    ContentView(dataService: DataService(inMemory: true))
}
