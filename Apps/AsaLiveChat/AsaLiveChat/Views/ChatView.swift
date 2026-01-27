//
//  ChatView.swift
//  AsaLiveChat
//
//  チャット画面
//

import SwiftUI
import SwiftData
import AsaUIKit

/// チャットメッセージを表示・送信する画面
struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 接続状態バナー
            ConnectionStatusView(state: viewModel.connectionState) {
                Task {
                    await viewModel.reconnect()
                }
            }

            // メッセージリスト
            messageListView

            // タイピングインジケータ
            if !viewModel.typingUsers.isEmpty {
                TypingIndicator(text: viewModel.typingDisplayText)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // 入力欄
            messageInputView
        }
        .navigationTitle(viewModel.room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.room.name)
                        .font(.headline)
                    ConnectionStatusBadge(state: viewModel.connectionState)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.showingRoomInfo = true
                    } label: {
                        Label("ルーム情報", systemImage: "info.circle")
                    }

                    Button {
                        viewModel.showingParticipants = true
                    } label: {
                        Label("参加者", systemImage: "person.2")
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.showingLeaveConfirm = true
                    } label: {
                        Label("退出", systemImage: "arrow.right.square")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingRoomInfo) {
            RoomInfoSheet(room: viewModel.room)
        }
        .sheet(isPresented: $viewModel.showingParticipants) {
            ParticipantsSheet(users: viewModel.onlineUsers)
        }
        .alert("ルームを退出", isPresented: $viewModel.showingLeaveConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("退出", role: .destructive) {
                viewModel.disconnect()
                dismiss()
            }
        } message: {
            Text("このチャットルームから退出しますか？")
        }
        .task {
            await viewModel.connect()
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }

    // MARK: - Message List

    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            showSenderName: viewModel.shouldShowSenderName(for: message)
                        )
                        .id(message.id)
                    }
                }
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastMessage = viewModel.messages.last else { return }

        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }

    // MARK: - Message Input

    private var messageInputView: some View {
        HStack(spacing: 12) {
            // テキスト入力
            TextField("メッセージを入力...", text: $viewModel.messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AsaColors.softCream.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isInputFocused)
                .lineLimit(1...5)
                .onChange(of: viewModel.messageText) { _, _ in
                    viewModel.sendTypingIndicator()
                }

            // 送信ボタン
            Button {
                Task {
                    await viewModel.sendMessage()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(viewModel.canSendMessage
                                  ? AsaColors.coffeeBrown
                                  : AsaColors.mutedSage)
                    )
            }
            .disabled(!viewModel.canSendMessage)
            .animation(.easeInOut(duration: 0.2), value: viewModel.canSendMessage)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(AsaColors.softCream)
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Room Info Sheet

struct RoomInfoSheet: View {
    let room: ChatRoom
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("ルーム名")
                            .foregroundColor(AsaColors.mutedSage)
                        Spacer()
                        Text(room.name)
                    }

                    HStack {
                        Text("ルームコード")
                            .foregroundColor(AsaColors.mutedSage)
                        Spacer()
                        Text(room.roomCode)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)

                        Button {
                            UIPasteboard.general.string = room.roomCode
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(AsaColors.coffeeBrown)
                        }
                    }

                    HStack {
                        Text("作成日")
                            .foregroundColor(AsaColors.mutedSage)
                        Spacer()
                        Text(room.createdAt, style: .date)
                    }

                    HStack {
                        Text("メッセージ数")
                            .foregroundColor(AsaColors.mutedSage)
                        Spacer()
                        Text("\(room.messageCount)件")
                    }
                }

                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Text("ルームコードを共有")
                            .font(.headline)

                        Text(room.roomCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(AsaColors.coffeeBrown)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AsaColors.softCream.opacity(0.3))
                            )

                        Text("このコードを友達や家族に共有して\nルームに参加してもらいましょう")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("ルーム情報")
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

// MARK: - Participants Sheet

struct ParticipantsSheet: View {
    let users: [ChatUser]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(users) { user in
                        UserRow(user: user)
                    }
                } header: {
                    Text("オンライン (\(users.filter { $0.isOnline }.count))")
                }
            }
            .navigationTitle("参加者")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if users.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(AsaColors.mutedSage)

                        Text("参加者がいません")
                            .foregroundColor(AsaColors.mutedSage)
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
    let userSettings = dataService.getOrCreateUserSettings()
    let room = dataService.createRoom(name: "テストルーム")

    return NavigationStack {
        ChatView(
            viewModel: ChatViewModel(
                room: room,
                dataService: dataService,
                userSettings: userSettings
            )
        )
    }
}
