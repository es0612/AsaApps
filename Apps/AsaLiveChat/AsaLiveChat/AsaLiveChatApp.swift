//
//  AsaLiveChatApp.swift
//  AsaLiveChat
//
//  リアルタイムチャットアプリ - WebSocket通信
//  AsaApps #77
//

import SwiftUI
import SwiftData

@main
struct AsaLiveChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ChatRoom.self, Message.self, UserSettings.self])
    }
}

// MARK: - ContentView（メインタブビュー）

struct ContentView: View {
    @State private var chatDataService: ChatDataService?
    @State private var settingsViewModel: SettingsViewModel?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if let dataService = chatDataService,
               let settings = settingsViewModel {
                MainTabView(
                    dataService: dataService,
                    settingsViewModel: settings
                )
            } else {
                ProgressView("読み込み中...")
                    .onAppear {
                        setupServices()
                    }
            }
        }
    }

    private func setupServices() {
        let dataService = ChatDataService(modelContext: modelContext)
        self.chatDataService = dataService
        self.settingsViewModel = SettingsViewModel(dataService: dataService)
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    let dataService: ChatDataService
    @Bindable var settingsViewModel: SettingsViewModel

    var body: some View {
        TabView {
            ChatRoomListView(
                viewModel: ChatRoomListViewModel(dataService: dataService),
                settingsViewModel: settingsViewModel
            )
            .tabItem {
                Label("チャット", systemImage: "bubble.left.and.bubble.right")
            }

            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .tint(AsaColors.coffeeBrown)
    }
}

// MARK: - AsaColors Extension（AsaUIKitから）

import AsaUIKit

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [ChatRoom.self, Message.self, UserSettings.self], inMemory: true)
}
