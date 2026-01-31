import SwiftUI

// MARK: - SpeakerControlView

/// スピーカーコントロールビュー
struct SpeakerControlView: View {
    // MARK: - Properties

    @Bindable var viewModel: DeviceControlViewModel

    @State private var volume: Double
    @State private var playbackState: PlaybackState

    // MARK: - Initialization

    init(viewModel: DeviceControlViewModel) {
        self.viewModel = viewModel
        self._volume = State(initialValue: Double(viewModel.device.volume))
        self._playbackState = State(initialValue: viewModel.device.playbackState)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // 再生コントロール
            playbackControlCard

            // 音量スライダー
            VolumeSlider(value: $volume) { value in
                await viewModel.setVolume(value)
            }
            .disabled(!viewModel.device.isActive)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var playbackControlCard: some View {
        VStack(spacing: 20) {
            // 電源
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.device.isActive ? "電源オン" : "電源オフ")
                        .font(.headline)
                        .foregroundStyle(.white)

                    if viewModel.device.isActive {
                        Text(playbackStateText)
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

            // 再生ボタン
            HStack(spacing: 24) {
                // 停止
                PlaybackButton(icon: "stop.fill", isActive: playbackState == .stopped) {
                    playbackState = .stopped
                    await viewModel.setPlaybackState(.stopped)
                }
                .disabled(!viewModel.device.isActive)

                // 再生/一時停止
                PlaybackButton(
                    icon: playbackState == .playing ? "pause.fill" : "play.fill",
                    isActive: playbackState == .playing || playbackState == .paused,
                    size: 64
                ) {
                    if playbackState == .playing {
                        playbackState = .paused
                        await viewModel.setPlaybackState(.paused)
                    } else {
                        playbackState = .playing
                        await viewModel.setPlaybackState(.playing)
                    }
                }
                .disabled(!viewModel.device.isActive)

                // ミュート（仮）
                PlaybackButton(icon: volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill", isActive: false) {
                    if volume == 0 {
                        volume = 50
                        await viewModel.setVolume(50)
                    } else {
                        volume = 0
                        await viewModel.setVolume(0)
                    }
                }
                .disabled(!viewModel.device.isActive)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Computed Properties

    private var playbackStateText: String {
        switch playbackState {
        case .playing: return "再生中"
        case .paused: return "一時停止"
        case .stopped: return "停止"
        }
    }
}

// MARK: - PlaybackButton

private struct PlaybackButton: View {
    let icon: String
    let isActive: Bool
    var size: CGFloat = 48
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
            ZStack {
                Circle()
                    .fill(isActive ? Color.asaCoffeeBrown : Color.white.opacity(0.1))
                    .frame(width: size, height: size)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview("Speaker Control") {
    VStack {
        Text("Speaker Control Preview")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.asaDarkSlate)
}
