//
//  LobbyView.swift
//  AsaMultiplayerGame
//
//  ロビー画面（ゲーム開始前の待機画面）
//

import SwiftUI
import AsaUIKit

struct LobbyView: View {
    // MARK: - Properties

    @Bindable var viewModel: GameViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                AsaColors.softCream
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // ルームコード
                    roomCodeSection

                    // プレイヤーリスト
                    playerListSection

                    Spacer()

                    // 設定（ホストのみ）
                    if viewModel.localPlayer?.isHost == true {
                        settingsSection
                    }

                    // アクションボタン
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("ロビー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("退出") {
                        viewModel.leaveRoom()
                    }
                }
            }
        }
    }

    // MARK: - Room Code Section

    private var roomCodeSection: some View {
        VStack(spacing: 12) {
            Text("ルームコード")
                .font(.headline)
                .foregroundColor(AsaColors.mutedSage)

            HStack(spacing: 8) {
                ForEach(Array(viewModel.roomCode ?? "------"), id: \.self) { char in
                    Text(String(char))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .frame(width: 44, height: 56)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                }
            }

            // コピーボタン
            Button {
                if let code = viewModel.roomCode {
                    UIPasteboard.general.string = code
                }
            } label: {
                Label("コードをコピー", systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(AsaColors.coffeeBrown)
            }
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
    }

    // MARK: - Player List Section

    private var playerListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("プレイヤー")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text("\(viewModel.players.count)/2")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
            }

            VStack(spacing: 8) {
                ForEach(viewModel.players) { player in
                    playerRow(player)
                }

                // 空きスロット
                if viewModel.players.count < 2 {
                    emptyPlayerSlot
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private func playerRow(_ player: Player) -> some View {
        HStack {
            // アバター
            Text(player.avatarEmoji)
                .font(.title)
                .frame(width: 44, height: 44)
                .background(AsaColors.softCream)
                .clipShape(Circle())

            // 名前
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(player.name)
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    if player.isHost {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }

                    if player.id == viewModel.localPlayer?.id {
                        Text("(あなた)")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                Text(player.isReady ? "準備完了" : "待機中")
                    .font(.caption)
                    .foregroundColor(player.isReady ? .green : AsaColors.mutedSage)
            }

            Spacer()

            // Ready状態インジケータ
            Image(systemName: player.isReady ? "checkmark.circle.fill" : "circle")
                .foregroundColor(player.isReady ? .green : AsaColors.mutedSage)
                .font(.title2)
        }
        .padding(12)
        .background(AsaColors.softCream.opacity(0.5))
        .cornerRadius(12)
    }

    private var emptyPlayerSlot: some View {
        HStack {
            // 空のアバター
            Image(systemName: "person.fill.questionmark")
                .font(.title2)
                .foregroundColor(AsaColors.mutedSage)
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())

            Text("参加者を待っています...")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(AsaColors.mutedSage.opacity(0.5))
        )
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ゲーム設定")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            VStack(spacing: 8) {
                // ラウンド数
                HStack {
                    Text("ラウンド数")
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    Picker("ラウンド数", selection: $viewModel.settings.roundCount) {
                        ForEach([3, 5, 7, 10], id: \.self) { count in
                            Text("\(count)ラウンド").tag(count)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Divider()

                // 制限時間
                HStack {
                    Text("制限時間")
                        .foregroundColor(AsaColors.darkSlate)
                    Spacer()
                    Picker("制限時間", selection: $viewModel.settings.roundTimeLimit) {
                        ForEach([20, 30, 45, 60], id: \.self) { seconds in
                            Text("\(seconds)秒").tag(seconds)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Ready/開始ボタン
            if viewModel.localPlayer?.isHost == true {
                // ホストの場合：ゲーム開始ボタン
                Button {
                    Task {
                        await viewModel.startGame()
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("ゲームを開始")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.canStartGame ? AsaColors.coffeeBrown : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canStartGame)

                if !viewModel.canStartGame {
                    Text("全員の準備完了を待っています")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            } else {
                // ゲストの場合：Readyボタン
                Button {
                    Task {
                        await viewModel.toggleReady()
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.localPlayer?.isReady == true ? "checkmark.circle.fill" : "circle")
                        Text(viewModel.localPlayer?.isReady == true ? "準備完了" : "準備する")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.localPlayer?.isReady == true ? .green : AsaColors.darkSlate)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
}

#Preview {
    let viewModel = GameViewModel()
    viewModel.roomCode = "ABC123"
    viewModel.localPlayer = Player(name: "テストプレイヤー", isReady: true, isHost: true)
    viewModel.players = [
        Player(name: "テストプレイヤー", avatarEmoji: "🎨", isReady: true, isHost: true),
        Player(name: "AIプレイヤー", avatarEmoji: "🤖", isReady: false, isHost: false)
    ]
    return LobbyView(viewModel: viewModel)
}
