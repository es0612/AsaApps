import SwiftUI

// MARK: - LightControlView

/// 照明コントロールビュー
struct LightControlView: View {
    // MARK: - Properties

    @Bindable var viewModel: DeviceControlViewModel

    @State private var brightness: Double
    @State private var colorTemperature: Double

    // MARK: - Initialization

    init(viewModel: DeviceControlViewModel) {
        self.viewModel = viewModel
        self._brightness = State(initialValue: Double(viewModel.device.brightness))
        self._colorTemperature = State(initialValue: Double(viewModel.device.colorTemperature))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // 電源状態表示
            powerStatusCard

            // 明るさスライダー
            BrightnessSlider(value: $brightness) { value in
                await viewModel.setBrightness(value)
            }
            .disabled(!viewModel.device.isActive)

            // 色温度スライダー
            ColorTemperatureSlider(value: $colorTemperature) { value in
                await viewModel.setColorTemperature(value)
            }
            .disabled(!viewModel.device.isActive)

            // プリセットボタン
            presetsSection
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var powerStatusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.device.isActive ? "点灯中" : "消灯")
                    .font(.headline)
                    .foregroundStyle(.white)

                if viewModel.device.isActive {
                    Text("明るさ \(viewModel.device.brightness)% • \(viewModel.device.colorTemperature)K")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

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
                size: 56
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    @ViewBuilder
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プリセット")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 12) {
                PresetButton(title: "リラックス", icon: "moon.fill") {
                    await applyPreset(brightness: 30, colorTemp: 2700)
                }

                PresetButton(title: "通常", icon: "sun.max.fill") {
                    await applyPreset(brightness: 80, colorTemp: 4000)
                }

                PresetButton(title: "集中", icon: "lightbulb.max.fill") {
                    await applyPreset(brightness: 100, colorTemp: 5500)
                }
            }
        }
        .disabled(!viewModel.device.isActive)
    }

    // MARK: - Private Methods

    private func applyPreset(brightness: Int, colorTemp: Int) async {
        withAnimation {
            self.brightness = Double(brightness)
            self.colorTemperature = Double(colorTemp)
        }
        await viewModel.setBrightness(brightness)
        await viewModel.setColorTemperature(colorTemp)
    }
}

// MARK: - PresetButton

private struct PresetButton: View {
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

#Preview("Light Control") {
    let device = SmartDevice(name: "リビング照明", deviceType: .light, powerState: .on)
    VStack {
        // プレビュー用モック
        Text("Light Control Preview")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.asaDarkSlate)
}
