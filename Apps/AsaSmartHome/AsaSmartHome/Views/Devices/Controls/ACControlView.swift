import SwiftUI

// MARK: - ACControlView

/// エアコンコントロールビュー
struct ACControlView: View {
    // MARK: - Properties

    @Bindable var viewModel: DeviceControlViewModel

    @State private var targetTemperature: Int
    @State private var selectedMode: ACMode
    @State private var selectedFanSpeed: FanSpeed

    // MARK: - Initialization

    init(viewModel: DeviceControlViewModel) {
        self.viewModel = viewModel
        self._targetTemperature = State(initialValue: viewModel.device.targetTemperature)
        self._selectedMode = State(initialValue: viewModel.device.acMode)
        self._selectedFanSpeed = State(initialValue: viewModel.device.fanSpeed)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // 電源と温度コントロール
            HStack(alignment: .top) {
                PowerToggleView(
                    isOn: Binding(
                        get: { viewModel.device.isActive },
                        set: { _ in }
                    ),
                    onToggle: {
                        await viewModel.togglePower()
                    },
                    isLoading: viewModel.isLoading,
                    size: 56
                )

                Spacer()

                // 温度コントロール
                TemperatureControl(
                    temperature: $targetTemperature
                ) { value in
                    await viewModel.setTargetTemperature(value)
                }
                .disabled(!viewModel.device.isActive)
            }

            // モード選択
            modeSelector
                .disabled(!viewModel.device.isActive)

            // 風量選択
            fanSpeedSelector
                .disabled(!viewModel.device.isActive)
        }
    }

    // MARK: - Mode Selector

    @ViewBuilder
    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("運転モード")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 8) {
                ForEach(ACMode.allCases, id: \.self) { mode in
                    ModeButton(
                        title: mode.displayName,
                        icon: mode.iconName,
                        isSelected: selectedMode == mode
                    ) {
                        selectedMode = mode
                        await viewModel.setACMode(mode)
                    }
                }
            }
        }
    }

    // MARK: - Fan Speed Selector

    @ViewBuilder
    private var fanSpeedSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("風量")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 8) {
                ForEach(FanSpeed.allCases, id: \.self) { speed in
                    FanSpeedButton(
                        title: speed.displayName,
                        isSelected: selectedFanSpeed == speed
                    ) {
                        selectedFanSpeed = speed
                        await viewModel.setFanSpeed(speed)
                    }
                }
            }
        }
    }
}

// MARK: - ModeButton

private struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () async -> Void

    @State private var isLoading = false

    var body: some View {
        Button {
            guard !isSelected else { return }
            isLoading = true
            Task {
                await action()
                isLoading = false
            }
        } label: {
            VStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                }

                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.asaCoffeeBrown : Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - FanSpeedButton

private struct FanSpeedButton: View {
    let title: String
    let isSelected: Bool
    let action: () async -> Void

    @State private var isLoading = false

    var body: some View {
        Button {
            guard !isSelected else { return }
            isLoading = true
            Task {
                await action()
                isLoading = false
            }
        } label: {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
        }
        .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.asaCoffeeBrown : Color.white.opacity(0.08))
        )
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview("AC Control") {
    VStack {
        Text("AC Control Preview")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.asaDarkSlate)
}
