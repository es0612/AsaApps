//
//  ContentView.swift
//  AsaSmartTodo
//
//  メインビュー（タブビュー）
//  タスク管理、AI分析、設定の3タブ
//

import SwiftUI
import AsaUIKit

struct ContentView: View {
    @State private var viewModel: SmartTodoViewModel
    @State private var selectedTab = 0

    init() {
        let dataService = DataService()
        _viewModel = State(initialValue: SmartTodoViewModel(dataService: dataService))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // タスク管理タブ
            TaskListView(viewModel: viewModel)
                .tabItem {
                    Label("タスク", systemImage: "checklist")
                }
                .tag(0)

            // AI分析タブ（簡易版）
            AIPlaceholderView()
                .tabItem {
                    Label("AI分析", systemImage: "brain.head.profile")
                }
                .tag(1)

            // 設定タブ（簡易版）
            SettingsPlaceholderView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(AsaColors.coffeeBrown)
        .onAppear {
            viewModel.loadTasks()
        }
    }
}

// MARK: - Placeholder Views

/// AI分析プレースホルダー（Phase 2で実装予定）
struct AIPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(AsaColors.coffeeBrown)

            Text("AI分析ダッシュボード")
                .font(.title)
                .fontWeight(.bold)

            Text("Phase 2で実装予定")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("• AI予測精度トラッキング")
                Text("• 時間帯別パフォーマンス分析")
                Text("• 朝活生産性スコア")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

/// 設定プレースホルダー
struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(AsaColors.coffeeBrown)

            Text("設定")
                .font(.title)
                .fontWeight(.bold)

            Text("Phase 3で実装予定")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("• AI予測の重み設定")
                Text("• 通知設定")
                Text("• カテゴリカスタマイズ")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}
