import SwiftUI

// MARK: - DashboardView

/// ダッシュボード画面
struct DashboardView: View {
    // MARK: - Properties

    @Bindable var viewModel: SmartHomeViewModel
    @State private var selectedDevice: SmartDevice?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ステータスサマリー
                    StatusSummaryView(
                        totalDevices: viewModel.devices.count,
                        onlineDevices: viewModel.onlineDeviceCount,
                        activeDevices: viewModel.activeDeviceCount,
                        isConnected: viewModel.isConnected
                    )

                    // クイックアクション（シーン）
                    if !viewModel.scenes.isEmpty {
                        QuickControlGrid(scenes: Array(viewModel.scenes.prefix(4))) { scene in
                            await viewModel.executeSmartScene(scene)
                        }
                    }

                    // お気に入りデバイス
                    if !viewModel.favoriteDevices.isEmpty {
                        favoritesSection
                    }

                    // 全デバイス
                    allDevicesSection
                }
                .padding()
            }
            .background(Color.asaDarkSlate)
            .navigationTitle("スマートホーム")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.asaDarkSlate, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedDevice) { device in
                DeviceDetailView(
                    device: device,
                    viewModel: viewModel
                )
            }
            .refreshable {
                await viewModel.refreshDevices()
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.asaCoffeeBrown)
                Text("お気に入り")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.favoriteDevices) { device in
                    DeviceCardView(
                        device: device,
                        roomName: viewModel.room(for: device.roomId ?? UUID())?.name,
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
    }

    @ViewBuilder
    private var allDevicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("すべてのデバイス")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.devices) { device in
                    DeviceCardView(
                        device: device,
                        roomName: viewModel.room(for: device.roomId ?? UUID())?.name,
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
    }
}

// MARK: - Preview

#Preview("Dashboard") {
    // プレビュー用のモックViewModel
    Text("Dashboard Preview")
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.asaDarkSlate)
}
