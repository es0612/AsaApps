//
//  MainMenuView.swift
//  AsaMultiplayerGame
//
//  メインメニュー画面
//

import SwiftUI
import AsaUIKit

struct MainMenuView: View {
    // MARK: - Properties

    @Bindable var viewModel: GameViewModel

    @State private var playerName: String = ""
    @State private var roomCodeInput: String = ""
    @State private var selectedEmoji: String = "🎨"
    @State private var showCreateRoom = false
    @State private var showJoinRoom = false

    private let avatarEmojis = ["🎨", "🖌️", "✏️", "🖍️", "🎭", "🎪", "🌟", "🔥"]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [Color("AsaSoftCream"), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    // ヘッダー
                    headerSection

                    Spacer()

                    // メインメニュー
                    menuSection

                    Spacer()

                    // フッター
                    footerSection
                }
                .padding()
            }
            .sheet(isPresented: $showCreateRoom) {
                createRoomSheet
            }
            .sheet(isPresented: $showJoinRoom) {
                joinRoomSheet
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // アプリアイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("AsaCoffeeBrown"), Color("AsaMocha")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

                Text("🎨")
                    .font(.system(size: 60))
            }

            // タイトル
            VStack(spacing: 4) {
                Text("お絵かきバトル")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaDarkSlate"))

                Text("友達とリアルタイムで対戦しよう！")
                    .font(.subheadline)
                    .foregroundColor(Color("AsaMutedSage"))
            }
        }
        .padding(.top, 40)
    }

    // MARK: - Menu Section

    private var menuSection: some View {
        VStack(spacing: 16) {
            // ルーム作成ボタン
            Button {
                showCreateRoom = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("ルームを作成")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("AsaCoffeeBrown"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // ルーム参加ボタン
            Button {
                showJoinRoom = true
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                    Text("ルームに参加")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("AsaDarkSlate"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("遊び方")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaDarkSlate"))

            Text("交互に絵を描いて当て合おう！")
                .font(.caption2)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .padding(.bottom, 20)
    }

    // MARK: - Create Room Sheet

    private var createRoomSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 名前入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("プレイヤー名")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))

                    TextField("名前を入力", text: $playerName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }

                // アバター選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("アバター")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(avatarEmojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.largeTitle)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(selectedEmoji == emoji ? Color("AsaSoftCream") : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedEmoji == emoji ? Color("AsaCoffeeBrown") : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }

                Spacer()

                // 作成ボタン
                Button {
                    Task {
                        await viewModel.createRoom(playerName: playerName, avatarEmoji: selectedEmoji)
                        showCreateRoom = false
                    }
                } label: {
                    Text("ルームを作成")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(playerName.isEmpty ? Color.gray : Color("AsaCoffeeBrown"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(playerName.isEmpty)
            }
            .padding(24)
            .navigationTitle("ルーム作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showCreateRoom = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Join Room Sheet

    private var joinRoomSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 名前入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("プレイヤー名")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))

                    TextField("名前を入力", text: $playerName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }

                // ルームコード入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("ルームコード")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))

                    TextField("6桁のコードを入力", text: $roomCodeInput)
                        .textFieldStyle(.roundedBorder)
                        .textCase(.uppercase)
                        .autocorrectionDisabled()
                        .onChange(of: roomCodeInput) { _, newValue in
                            roomCodeInput = String(newValue.uppercased().prefix(6))
                        }
                }

                // アバター選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("アバター")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(avatarEmojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.largeTitle)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(selectedEmoji == emoji ? Color("AsaSoftCream") : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedEmoji == emoji ? Color("AsaCoffeeBrown") : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }

                Spacer()

                // 参加ボタン
                Button {
                    Task {
                        await viewModel.joinRoom(roomCode: roomCodeInput, playerName: playerName, avatarEmoji: selectedEmoji)
                        showJoinRoom = false
                    }
                } label: {
                    Text("ルームに参加")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canJoin ? Color("AsaDarkSlate") : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!canJoin)
            }
            .padding(24)
            .navigationTitle("ルーム参加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showJoinRoom = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var canJoin: Bool {
        !playerName.isEmpty && roomCodeInput.count == 6
    }
}

#Preview {
    MainMenuView(viewModel: GameViewModel())
}
