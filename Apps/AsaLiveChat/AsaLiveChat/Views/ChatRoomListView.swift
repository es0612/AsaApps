//
//  ChatRoomListView.swift
//  AsaLiveChat
//
//  チャットルーム一覧画面
//

import SwiftUI
import SwiftData
import AsaUIKit

/// チャットルーム一覧を表示する画面
struct ChatRoomListView: View {
    @Bindable var viewModel: ChatRoomListViewModel
    @Bindable var settingsViewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.rooms.isEmpty {
                    emptyStateView
                } else {
                    roomListView
                }
            }
            .navigationTitle("チャット")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingCreateRoom = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }

                ToolbarItem(placement: .navigation) {
                    Button {
                        viewModel.showingJoinRoom = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateRoom) {
                CreateRoomSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingJoinRoom) {
                JoinRoomSheet(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadRooms()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(AsaColors.softCream)

            VStack(spacing: 8) {
                Text("チャットルームがありません")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                Text("新しいルームを作成するか、\n既存のルームに参加してください")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                AsaButton(title: "ルーム作成") {
                    viewModel.showingCreateRoom = true
                }

                AsaButton(title: "参加", action: {
                    viewModel.showingJoinRoom = true
                }, color: AsaColors.mocha)
            }
        }
        .padding(32)
    }

    // MARK: - Room List

    private var roomListView: some View {
        List {
            ForEach(viewModel.rooms) { room in
                NavigationLink {
                    ChatView(
                        viewModel: ChatViewModel(
                            room: room,
                            dataService: viewModel.dataService,
                            userSettings: settingsViewModel.settings
                        )
                    )
                } label: {
                    RoomRow(room: room)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteRoom(room)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Room Row

struct RoomRow: View {
    let room: ChatRoom

    var body: some View {
        HStack(spacing: 12) {
            // ルームアイコン
            ZStack {
                Circle()
                    .fill(AsaColors.coffeeBrown.opacity(0.1))
                    .frame(width: 50, height: 50)

                Text(room.displayEmoji)
                    .font(.title2)
            }

            // ルーム情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(room.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    if let lastMessage = room.lastMessageAt {
                        Text(formatDate(lastMessage))
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                HStack {
                    if let preview = room.lastMessagePreview {
                        Text(preview)
                            .font(.subheadline)
                            .foregroundColor(AsaColors.mutedSage)
                            .lineLimit(1)
                    } else {
                        Text("メッセージはありません")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.mutedSage.opacity(0.6))
                            .italic()
                    }

                    Spacer()

                    if room.unreadCount > 0 {
                        Text("\(room.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AsaColors.coffeeBrown)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
        } else {
            formatter.dateFormat = "M/d"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Create Room Sheet

struct CreateRoomSheet: View {
    @Bindable var viewModel: ChatRoomListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var roomName = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("💬")
                    .font(.system(size: 64))
                    .padding(.top, 32)

                Text("新しいチャットルーム")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.darkSlate)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ルーム名")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)

                    TextField("例: 家族チャット", text: $roomName)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                }
                .padding(.horizontal, 24)

                Spacer()

                AsaButton(
                    title: "作成",
                    action: {
                        viewModel.newRoomName = roomName
                        if viewModel.createRoom() != nil {
                            dismiss()
                        }
                    },
                    isEnabled: !roomName.trimmingCharacters(in: .whitespaces).isEmpty
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Join Room Sheet

struct JoinRoomSheet: View {
    @Bindable var viewModel: ChatRoomListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var roomCode = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("🔗")
                    .font(.system(size: 64))
                    .padding(.top, 32)

                Text("ルームに参加")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.darkSlate)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ルームコード")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)

                    TextField("例: ABC123", text: $roomCode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .focused($isFocused)
                        .onChange(of: roomCode) { _, newValue in
                            roomCode = newValue.uppercased()
                        }
                }
                .padding(.horizontal, 24)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                }

                Spacer()

                AsaButton(
                    title: viewModel.isLoading ? "参加中..." : "参加",
                    action: {
                        viewModel.joinRoomCode = roomCode
                        if viewModel.joinRoom() != nil {
                            dismiss()
                        }
                    },
                    isEnabled: roomCode.count >= 6 && !viewModel.isLoading
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
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

    return ChatRoomListView(
        viewModel: ChatRoomListViewModel(dataService: dataService),
        settingsViewModel: SettingsViewModel(dataService: dataService)
    )
}
