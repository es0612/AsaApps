import SwiftUI

// MARK: - DeviceIconView

/// デバイスアイコン表示ビュー
struct DeviceIconView: View {
    // MARK: - Properties

    let deviceType: DeviceType
    let isActive: Bool
    let size: CGFloat

    // MARK: - Initialization

    init(deviceType: DeviceType, isActive: Bool = false, size: CGFloat = 32) {
        self.deviceType = deviceType
        self.isActive = isActive
        self.size = size
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size * 1.5, height: size * 1.5)

            Image(systemName: isActive ? deviceType.iconName : deviceType.offIconName)
                .font(.system(size: size * 0.6, weight: .medium))
                .foregroundStyle(iconColor)
        }
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        if isActive {
            return Color.asaCoffeeBrown.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }

    private var iconColor: Color {
        if isActive {
            return Color.asaCoffeeBrown
        } else {
            return Color.white.opacity(0.6)
        }
    }
}

// MARK: - Preview

#Preview("Device Icons") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            ForEach(DeviceType.allCases.prefix(4), id: \.self) { type in
                VStack {
                    DeviceIconView(deviceType: type, isActive: true)
                    Text(type.displayName)
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
        }

        HStack(spacing: 20) {
            ForEach(DeviceType.allCases.suffix(4), id: \.self) { type in
                VStack {
                    DeviceIconView(deviceType: type, isActive: false)
                    Text(type.displayName)
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
        }
    }
    .padding()
    .background(Color.asaDarkSlate)
}
