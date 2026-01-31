import SwiftUI

// MARK: - TVControlView

/// テレビコントロールビュー
struct TVControlView: View {
    // MARK: - Properties

    @Bindable var viewModel: DeviceControlViewModel

    @State private var volume: Double
    @State private var channel: Int
    @State private var selectedInput: TVInput

    // MARK: - Initialization

    init(viewModel: DeviceControlViewModel) {
        self.viewModel = viewModel
        self._volume = State(initialValue: Double(viewModel.device.volume))
        self._channel = State(initialValue: viewModel.device.currentChannel)
        self._selectedInput = State(initialValue: viewModel.device.tvInput)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // 電源状態
            powerSection

            // 音量コントロール
            VolumeSlider(value: $volume) { value in
                await viewModel.setVolume(value)
            }
            .disabled(!viewModel.device.isActive)

            // チャンネルコントロール
            if selectedInput == .antenna {
                ChannelControl(channel: $channel) { value in
                    await viewModel.setChannel(value)
                }
                .disabled(!viewModel.device.isActive)
            }

            // 入力選択
            inputSelector
                .disabled(!viewModel.device.isActive)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var powerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.device.isActive ? "視聴中" : "電源オフ")
                    .font(.headline)
                    .foregroundStyle(.white)

                if viewModel.device.isActive {
                    Text("\(selectedInput.displayName) • 音量 \(viewModel.device.volume)%")
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
    private var inputSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("入力切替")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(TVInput.allCases, id: \.self) { input in
                    InputButton(
                        title: input.displayName,
                        isSelected: selectedInput == input
                    ) {
                        selectedInput = input
                        await viewModel.setTVInput(input)
                    }
                }
            }
        }
    }
}

// MARK: - InputButton

private struct InputButton: View {
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
                    .font(.subheadline)
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

#Preview("TV Control") {
    VStack {
        Text("TV Control Preview")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.asaDarkSlate)
}
