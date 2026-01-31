import SwiftUI

// MARK: - RoomListView

/// 部屋一覧画面
struct RoomListView: View {
    // MARK: - Properties

    @Bindable var viewModel: SmartHomeViewModel
    @State private var selectedRoom: Room?
    @State private var showAddRoom = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.rooms) { room in
                        RoomCardView(
                            room: room,
                            deviceCount: viewModel.devices(in: room).count,
                            activeCount: viewModel.devices(in: room).filter { $0.isActive }.count
                        ) {
                            selectedRoom = room
                        }
                    }

                    // 未割り当てデバイス
                    if !viewModel.unassignedDevices.isEmpty {
                        UnassignedDevicesCard(
                            deviceCount: viewModel.unassignedDevices.count
                        )
                    }
                }
                .padding()
            }
            .background(Color.asaDarkSlate)
            .navigationTitle("部屋")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.asaDarkSlate, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddRoom = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.asaCoffeeBrown)
                    }
                }
            }
            .sheet(item: $selectedRoom) { room in
                RoomDetailView(room: room, viewModel: viewModel)
            }
            .sheet(isPresented: $showAddRoom) {
                AddRoomView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - RoomCardView

/// 部屋カード
struct RoomCardView: View {
    let room: Room
    let deviceCount: Int
    let activeCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(Color.asaCoffeeBrown.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: room.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(Color.asaCoffeeBrown)
                }

                // 部屋情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("\(deviceCount)台のデバイス • \(activeCount)台が動作中")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - UnassignedDevicesCard

private struct UnassignedDevicesCard: View {
    let deviceCount: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 56, height: 56)

                Image(systemName: "questionmark.folder.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("未割り当て")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(deviceCount)台のデバイス")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(Color.white.opacity(0.1))
                )
        )
    }
}

// MARK: - RoomDetailView

/// 部屋詳細画面
struct RoomDetailView: View {
    let room: Room
    @Bindable var viewModel: SmartHomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDevice: SmartDevice?

    var devices: [SmartDevice] {
        viewModel.devices(in: room)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 部屋ヘッダー
                    roomHeader

                    // デバイス一覧
                    if devices.isEmpty {
                        emptyState
                    } else {
                        deviceGrid
                    }
                }
                .padding()
            }
            .background(Color.asaDarkSlate)
            .navigationTitle(room.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.asaDarkSlate, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundStyle(Color.asaCoffeeBrown)
                }
            }
            .sheet(item: $selectedDevice) { device in
                DeviceDetailView(device: device, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private var roomHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.asaCoffeeBrown.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: room.iconName)
                    .font(.system(size: 36))
                    .foregroundStyle(Color.asaCoffeeBrown)
            }

            VStack(spacing: 4) {
                Text(room.roomType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))

                Text("\(devices.count)台のデバイス")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    @ViewBuilder
    private var deviceGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(devices) { device in
                DeviceCardView(
                    device: device,
                    onTap: {
                        selectedDevice = device
                    },
                    onToggle: {
                        await viewModel.toggleDevice(device)
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))

            Text("この部屋にはデバイスがありません")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - AddRoomView

/// 部屋追加画面
struct AddRoomView: View {
    @Bindable var viewModel: SmartHomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var roomName = ""
    @State private var selectedType: RoomType = .other
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("部屋名") {
                    TextField("例: リビング", text: $roomName)
                }

                Section("部屋タイプ") {
                    ForEach(RoomType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundStyle(Color.asaCoffeeBrown)
                                    .frame(width: 24)

                                Text(type.displayName)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.asaCoffeeBrown)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("部屋を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        addRoom()
                    }
                    .disabled(roomName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
        }
    }

    private func addRoom() {
        isLoading = true
        let room = Room(
            name: roomName.trimmingCharacters(in: .whitespaces),
            roomType: selectedType,
            sortOrder: viewModel.rooms.count
        )

        Task {
            do {
                try await viewModel.addRoom(room)
                dismiss()
            } catch {
                print("Failed to add room: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview("Room List") {
    Text("Room List Preview")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.asaDarkSlate)
}
