//
//  ContentView.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = MultiTimerViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    @State private var selectedTab: Int = 0
    @State private var showingErrorAlert: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // タイマー一覧タブ
            TimerListView(viewModel: viewModel)
                .tabItem {
                    Label("タイマー", systemImage: "timer")
                }
                .tag(0)
                .badge(viewModel.multiTimer.sessions.count)
            
            // 実行中タイマータブ
            ActiveTimersView(viewModel: viewModel)
                .tabItem {
                    Label("実行中", systemImage: "play.circle")
                }
                .tag(1)
                .badge(viewModel.activeTimerCount)
            
            // 新規作成タブ
            TimerCreationView(viewModel: viewModel)
                .tabItem {
                    Label("新規作成", systemImage: "plus.circle")
                }
                .tag(2)
        }
        .tint(Color("AsaCoffeeBrown"))
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onAppear {
            setupInitialState()
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "予期しないエラーが発生しました")
        }
        .onChange(of: viewModel.showErrorAlert) { oldValue, newValue in
            if newValue {
                showingErrorAlert = true
                // ViewModelのアラート状態をリセット
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.showErrorAlert = false
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        // アプリ起動時の初期設定
        if viewModel.activeTimers.isEmpty && !viewModel.multiTimer.pendingTimers.isEmpty {
            // 実行中タイマーがない場合は最初のタブを表示
            selectedTab = 0
        } else if !viewModel.activeTimers.isEmpty {
            // 実行中タイマーがある場合は実行中タブを表示
            selectedTab = 1
        }
        
        // 通知権限の確認（バックグラウンドで実行）
        Task {
            let notificationService = TimerNotificationService.shared
            let status = await notificationService.getNotificationAuthorizationStatus()
            
            if status == .denied {
                print("通知権限が拒否されています。設定アプリで許可してください。")
            }
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // バックグラウンドに移行時の処理
            print("アプリがバックグラウンドに移行しました")
            // 必要に応じて通知をスケジュール
            scheduleActiveTimerNotifications()
            
        case .inactive:
            // 非アクティブ時の処理
            print("アプリが非アクティブになりました")
            
        case .active:
            // フォアグラウンドに復帰時の処理
            print("アプリがアクティブになりました")
            // 実行中タイマーがある場合は実行中タブに切り替え
            if !viewModel.activeTimers.isEmpty && selectedTab == 2 {
                selectedTab = 1
            }
            
        @unknown default:
            print("不明なScenePhaseです: \(newPhase)")
        }
    }
    
    private func scheduleActiveTimerNotifications() {
        // アクティブなタイマーの通知をスケジュール
        let notificationService = TimerNotificationService.shared
        
        Task {
            for timer in viewModel.activeTimers {
                await notificationService.scheduleTimerNotification(for: timer)
            }
        }
    }
}

#Preview {
    ContentView()
}
