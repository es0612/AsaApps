import SwiftUI

// MARK: - DeviceDetailView

/// デバイス詳細画面
struct DeviceDetailView: View {
    // MARK: - Properties

    let device: SmartDevice
    @Bindable var viewModel: SmartHomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var controlViewModel: DeviceControlViewModel?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // デバイスヘッダー
                    deviceHeader

                    // デバイスタイプ別コントロール
                    if let controlVM = controlViewModel {
                        deviceControls(viewModel: controlVM)
                    }
                }
                .padding()
            }
            .background(Color.asaDarkSlate)
            .navigationTitle(device.name)
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.toggleFavorite(device)
                        }
                    } label: {
                        Image(systemName: device.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(device.isFavorite ? Color.asaCoffeeBrown : .white.opacity(0.6))
                    }
                }
            }
            .task {
                // DeviceControlViewModelを作成
                if let service = getService() {
                    controlViewModel = DeviceControlViewModel(device: device, service: service)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var deviceHeader: some View {
        VStack(spacing: 16) {
            // デバイスアイコン
            DeviceIconView(
                deviceType: device.deviceType,
                isActive: device.isActive,
                size: 48
            )

            // デバイス情報
            VStack(spacing: 4) {
                Text(device.deviceType.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)

                if let roomId = device.roomId,
                   let room = viewModel.room(for: roomId) {
                    Text(room.name)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                // 接続状態
                HStack(spacing: 6) {
                    Circle()
                        .fill(device.isOnline ? Color.deviceOnline : Color.deviceOffline)
                        .frame(width: 8, height: 8)

                    Text(device.connectionStatus.displayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
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
    private func deviceControls(viewModel: DeviceControlViewModel) -> some View {
        switch device.deviceType {
        case .light:
            LightControlView(viewModel: viewModel)

        case .airConditioner:
            ACControlView(viewModel: viewModel)

        case .television:
            TVControlView(viewModel: viewModel)

        case .speaker:
            SpeakerControlView(viewModel: viewModel)

        case .smartLock:
            LockControlView(viewModel: viewModel)

        case .securityCamera:
            CameraControlView(viewModel: viewModel)

        case .thermostat:
            ThermostatControlView(viewModel: viewModel)

        case .curtain:
            CurtainControlView(viewModel: viewModel)
        }
    }

    // MARK: - Private Methods

    private func getService() -> SmartHomeServiceProtocol? {
        // ViewModelから直接サービスを取得する方法がないため、
        // 実際のアプリではDependency Injectionを使用します
        // ここではプレースホルダーとしてnilを返す
        nil
    }
}

// MARK: - ThermostatControlView

/// サーモスタットコントロールビュー
struct ThermostatControlView: View {
    @Bindable var viewModel: DeviceControlViewModel

    @State private var targetTemperature: Int

    init(viewModel: DeviceControlViewModel) {
        self.viewModel = viewModel
        self._targetTemperature = State(initialValue: viewModel.device.targetTemperature)
    }

    var body: some View {
        VStack(spacing: 24) {
            // 現在の環境
            environmentCard

            // 温度コントロール
            VStack(spacing: 12) {
                Text("設定温度")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))

                TemperatureControl(temperature: $targetTemperature) { value in
                    await viewModel.setTargetTemperature(value)
                }
                .disabled(!viewModel.device.isActive)
            }

            // 電源トグル
            HStack {
                Text("電源")
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Spacer()

                PowerToggleView(
                    isOn: Binding(
                        get: { viewModel.device.isActive },
                        set: { _ in }
                    ),
                    onToggle: {
                        await viewModel.togglePower()
                    },
                    isLoading: viewModel.isLoading,
                    size: 48
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }

    @ViewBuilder
    private var environmentCard: some View {
        HStack(spacing: 24) {
            // 現在の温度
            VStack(spacing: 4) {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.asaCoffeeBrown)

                Text(String(format: "%.1f°C", viewModel.device.currentTemperature))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                Text("現在の温度")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)

            Divider()
                .background(Color.white.opacity(0.2))

            // 湿度
            VStack(spacing: 4) {
                Image(systemName: "humidity.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.deviceActive)

                Text("\(viewModel.device.humidity)%")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                Text("湿度")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - CurtainControlView

/// カーテンコントロールビュー
struct CurtainControlView: View {
    @Bindable var viewModel: DeviceControlViewModel

    @State private var openPercentage: Double

    init(viewModel: DeviceControlViewModel) {
        self.viewModel = viewModel
        self._openPercentage = State(initialValue: Double(viewModel.device.openPercentage))
    }

    var body: some View {
        VStack(spacing: 24) {
            // 開度表示
            openStatusCard

            // 開度スライダー
            CurtainSlider(value: $openPercentage) { value in
                await viewModel.setOpenPercentage(value)
            }

            // プリセットボタン
            presetsSection
        }
    }

    @ViewBuilder
    private var openStatusCard: some View {
        VStack(spacing: 16) {
            // アイコン
            ZStack {
                Circle()
                    .fill(Color.asaCoffeeBrown.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: openPercentage > 50 ? "blinds.vertical.open" : "blinds.vertical.closed")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.asaCoffeeBrown)
            }

            Text(statusText)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    @ViewBuilder
    private var presetsSection: some View {
        HStack(spacing: 12) {
            PresetCurtainButton(title: "全閉", icon: "blinds.vertical.closed") {
                openPercentage = 0
                await viewModel.setOpenPercentage(0)
            }

            PresetCurtainButton(title: "半開", icon: "blinds.vertical.open") {
                openPercentage = 50
                await viewModel.setOpenPercentage(50)
            }

            PresetCurtainButton(title: "全開", icon: "sun.max.fill") {
                openPercentage = 100
                await viewModel.setOpenPercentage(100)
            }
        }
    }

    private var statusText: String {
        if openPercentage == 0 {
            return "完全に閉じています"
        } else if openPercentage == 100 {
            return "完全に開いています"
        } else {
            return "\(Int(openPercentage))% 開いています"
        }
    }
}

// MARK: - PresetCurtainButton

private struct PresetCurtainButton: View {
    let title: String
    let icon: String
    let action: () async -> Void

    @State private var isLoading = false

    var body: some View {
        Button {
            isLoading = true
            Task {
                await action()
                isLoading = false
            }
        } label: {
            VStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.asaCoffeeBrown)
                }

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview("Device Detail") {
    Text("Device Detail Preview")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.asaDarkSlate)
}
