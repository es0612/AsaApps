//
//  ContentView.swift
//  AsaMultiplayerGame
//
//  メインコンテンツビュー - ゲーム状態に応じた画面切り替え
//

import SwiftUI

struct ContentView: View {
    @State private var gameViewModel = GameViewModel()

    var body: some View {
        Group {
            switch gameViewModel.currentScreen {
            case .mainMenu:
                MainMenuView(viewModel: gameViewModel)

            case .lobby:
                LobbyView(viewModel: gameViewModel)

            case .playing:
                GameView(viewModel: gameViewModel)

            case .result:
                ResultView(viewModel: gameViewModel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameViewModel.currentScreen)
    }
}

#Preview {
    ContentView()
}
