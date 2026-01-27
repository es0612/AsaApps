//
//  SettingsView.swift
//  AsaLiveChat
//
//  設定画面
//

import SwiftUI
import SwiftData
import AsaUIKit

/// ユーザー設定を管理する画面
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            List {
                // プロフィールセクション
                profileSection

                // 通知設定セクション
                notificationSection

                // プライバシー設定セクション
                privacySection

                // サーバー設定セクション
                serverSection

                // アプリ情報セクション
                aboutSection
            }
            .navigationTitle("設定")
            .sheet(isPresented: $viewModel.showingAvatarPicker) {
                AvatarPickerSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingServerEditor) {
                ServerEditorSheet(viewModel: viewModel)
            }
            .overlay {
                // 成功メッセージ
                if let message = viewModel.successMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(AsaColors.coffeeBrown)
                            )
                            .padding(.bottom, 32)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.successMessage)
                }
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            // アバター
            HStack {
                Text("アバター")
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Button {
                    viewModel.showingAvatarPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Text(viewModel.avatarEmoji)
                            .font(.title)
                            .frame(width: 44, height: 44)
                            .background(AsaColors.softCream)
                            .clipShape(Circle())

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }

            // ユーザー名
            HStack {
                Text("ユーザー名")
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                TextField("ユーザー名", text: Binding(
                    get: { viewModel.userName },
                    set: { viewModel.userName = $0 }
                ))
                .multilineTextAlignment(.trailing)
                .foregroundColor(AsaColors.coffeeBrown)
            }

            // ユーザーID
            HStack {
                Text("ユーザーID")
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Text(String(viewModel.userId.prefix(8)) + "...")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        } header: {
            Text("プロフィール")
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { viewModel.notificationsEnabled },
                set: { viewModel.notificationsEnabled = $0 }
            )) {
                Text("通知")
                    .foregroundColor(AsaColors.darkSlate)
            }
            .tint(AsaColors.coffeeBrown)

            if viewModel.notificationsEnabled {
                Toggle(isOn: Binding(
                    get: { viewModel.soundEnabled },
                    set: { viewModel.soundEnabled = $0 }
                )) {
                    Text("サウンド")
                        .foregroundColor(AsaColors.darkSlate)
                }
                .tint(AsaColors.coffeeBrown)

                Toggle(isOn: Binding(
                    get: { viewModel.vibrationEnabled },
                    set: { viewModel.vibrationEnabled = $0 }
                )) {
                    Text("バイブレーション")
                        .foregroundColor(AsaColors.darkSlate)
                }
                .tint(AsaColors.coffeeBrown)
            }
        } header: {
            Text("通知")
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { viewModel.sendTypingIndicator },
                set: { viewModel.sendTypingIndicator = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("入力中を表示")
                        .foregroundColor(AsaColors.darkSlate)
                    Text("入力中であることを相手に知らせます")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .tint(AsaColors.coffeeBrown)

            Toggle(isOn: Binding(
                get: { viewModel.sendReadReceipts },
                set: { viewModel.sendReadReceipts = $0 }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("既読を送信")
                        .foregroundColor(AsaColors.darkSlate)
                    Text("メッセージを読んだことを相手に知らせます")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .tint(AsaColors.coffeeBrown)
        } header: {
            Text("プライバシー")
        }
    }

    // MARK: - Server Section

    private var serverSection: some View {
        Section {
            ForEach(UserSettings.availableServers, id: \.url) { server in
                Button {
                    viewModel.selectServer(server)
                } label: {
                    HStack {
                        Text(server.name)
                            .foregroundColor(AsaColors.darkSlate)

                        Spacer()

                        if viewModel.serverURL == server.url ||
                           (server.url.isEmpty && !UserSettings.availableServers.contains { $0.url == viewModel.serverURL && !$0.url.isEmpty }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(AsaColors.coffeeBrown)
                        }
                    }
                }
            }

            if !UserSettings.availableServers.contains(where: { $0.url == viewModel.serverURL }) {
                HStack {
                    Text("カスタム")
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    Text(viewModel.serverURL)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                        .lineLimit(1)

                    Image(systemName: "checkmark")
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        } header: {
            Text("サーバー")
        } footer: {
            Text("接続先のWebSocketサーバーを選択します。開発時はEcho Serverを使用してください。")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("バージョン")
                    .foregroundColor(AsaColors.darkSlate)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(AsaColors.mutedSage)
            }

            HStack {
                Text("アプリ")
                    .foregroundColor(AsaColors.darkSlate)
                Spacer()
                Text("AsaLiveChat #77")
                    .foregroundColor(AsaColors.mutedSage)
            }

            Button {
                viewModel.resetSettings()
            } label: {
                Text("設定をリセット")
                    .foregroundColor(.red)
            }
        } header: {
            Text("アプリ情報")
        }
    }
}

// MARK: - Avatar Picker Sheet

struct AvatarPickerSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    private let avatars = [
        "😊", "😎", "🥳", "😇", "🤩",
        "👨", "👩", "👦", "👧", "👶",
        "🐱", "🐶", "🦊", "🐰", "🐻",
        "🌸", "🌻", "🍀", "⭐️", "🌙",
        "🎨", "🎵", "📚", "💻", "☕️"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 現在のアバター
                Text(viewModel.avatarEmoji)
                    .font(.system(size: 80))
                    .frame(width: 120, height: 120)
                    .background(AsaColors.softCream)
                    .clipShape(Circle())
                    .padding(.top, 24)

                Text("アバターを選択")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                // アバター一覧
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(avatars, id: \.self) { emoji in
                        Button {
                            viewModel.selectAvatar(emoji)
                        } label: {
                            Text(emoji)
                                .font(.title)
                                .frame(width: 50, height: 50)
                                .background(
                                    viewModel.avatarEmoji == emoji
                                        ? AsaColors.coffeeBrown.opacity(0.2)
                                        : AsaColors.softCream.opacity(0.3)
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            viewModel.avatarEmoji == emoji
                                                ? AsaColors.coffeeBrown
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationTitle("アバター選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Server Editor Sheet

struct ServerEditorSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("サーバーURL")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)

                    TextField("wss://example.com/ws", text: $viewModel.customServerURL)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                }

                Text("WebSocketサーバーのURLを入力してください。\nws:// または wss:// で始まる必要があります。")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                AsaButton(title: "保存") {
                    viewModel.saveCustomServerURL()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("カスタムサーバー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewModel.clearMessages()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: ChatRoom.self, Message.self, UserSettings.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let dataService = ChatDataService(modelContext: container.mainContext)

    return SettingsView(
        viewModel: SettingsViewModel(dataService: dataService)
    )
}
