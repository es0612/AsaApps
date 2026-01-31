import SwiftUI

// MARK: - DeviceCardView

/// デバイスカード表示ビュー
struct DeviceCardView: View {
    // MARK: - Properties

    let device: SmartDevice
    let roomName: String?
    let onTap: () -> Void
    let onToggle: () async -> Void

    @State private var isToggling = false

    // MARK: - Initialization

    init(
        device: SmartDevice,
        roomName: String? = nil,
        onTap: @escaping () -> Void,
        onToggle: @escaping () async -> Void
    ) {
        self.device = device
        self.roomName = roomName
        self.onTap = onTap
        self.onToggle = onToggle
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    DeviceIconView(
                        deviceType: device.deviceType,
                        isActive: device.isActive,
                        size: 28
                    )

                    Spacer()

                    // 電源トグル
                    PowerToggleView(
                        isOn: Binding(
                            get: { device.powerState.isActive },
                            set: { _ in }
                        ),
                        onToggle: {
                            isToggling = true
                            await onToggle()
                            isToggling = false
                        },
                        isLoading: isToggling,
                        size: 36
                    )
                }

                Spacer()

                // デバイス情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        statusIndicator
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding()
            .frame(height: 140)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Properties

    private var cardBackground: some ShapeStyle {
        if device.isActive {
            return AnyShapeStyle(LinearGradient.activeDeviceGradient)
        } else {
            return AnyShapeStyle(Color.white.opacity(0.05))
        }
    }

    private var borderColor: Color {
        if device.isActive {
            return Color.asaCoffeeBrown.opacity(0.3)
        } else {
            return Color.white.opacity(0.1)
        }
    }

    private var statusText: String {
        if !device.isOnline {
            return device.connectionStatus.displayName
        }

        switch device.deviceType {
        case .light:
            if device.isActive {
                return "明るさ \(device.brightness)%"
            } else {
                return "オフ"
            }
        case .airConditioner:
            if device.isActive {
                return "\(device.targetTemperature)°C • \(device.acMode.displayName)"
            } else {
                return "オフ"
            }
        case .television:
            if device.isActive {
                return "Ch.\(device.currentChannel) • 音量\(device.volume)"
            } else {
                return "オフ"
            }
        case .speaker:
            if device.isActive {
                return "音量 \(device.volume)%"
            } else {
                return "オフ"
            }
        case .smartLock:
            return device.lockState.displayName
        case .securityCamera:
            if device.isRecording {
                return "録画中"
            } else {
                return device.isActive ? "監視中" : "オフ"
            }
        case .thermostat:
            return "\(String(format: "%.1f", device.currentTemperature))°C • 湿度\(device.humidity)%"
        case .curtain:
            if device.openPercentage == 0 {
                return "閉じています"
            } else if device.openPercentage == 100 {
                return "全開"
            } else {
                return "\(device.openPercentage)% 開"
            }
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 6, height: 6)
    }

    private var statusColor: Color {
        if !device.isOnline {
            return .deviceOffline
        } else if device.isActive {
            return .deviceOnline
        } else {
            return .white.opacity(0.4)
        }
    }
}

// MARK: - CompactDeviceCardView

/// コンパクトなデバイスカード（ダッシュボード用）
struct CompactDeviceCardView: View {
    let device: SmartDevice
    let onToggle: () async -> Void

    @State private var isToggling = false

    var body: some View {
        HStack(spacing: 12) {
            DeviceIconView(
                deviceType: device.deviceType,
                isActive: device.isActive,
                size: 24
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(device.deviceType.displayName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            PowerToggleView(
                isOn: Binding(
                    get: { device.powerState.isActive },
                    set: { _ in }
                ),
                onToggle: {
                    isToggling = true
                    await onToggle()
                    isToggling = false
                },
                isLoading: isToggling,
                size: 40
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview("Device Cards") {
    let sampleDevice = SmartDevice(
        name: "リビング照明",
        deviceType: .light,
        powerState: .on,
        connectionStatus: .online
    )

    VStack(spacing: 16) {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            DeviceCardView(
                device: sampleDevice,
                roomName: "リビング",
                onTap: {},
                onToggle: {}
            )

            DeviceCardView(
                device: SmartDevice(
                    name: "エアコン",
                    deviceType: .airConditioner,
                    powerState: .off
                ),
                onTap: {},
                onToggle: {}
            )
        }

        CompactDeviceCardView(device: sampleDevice, onToggle: {})
    }
    .padding()
    .background(Color.asaDarkSlate)
}
