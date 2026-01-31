import SwiftUI

// MARK: - CameraControlView

/// セキュリティカメラコントロールビュー
struct CameraControlView: View {
    // MARK: - Properties

    @Bindable var viewModel: DeviceControlViewModel

    @State private var isRecording: Bool

    // MARK: - Initialization

    init(viewModel: DeviceControlViewModel) {
        self.viewModel = viewModel
        self._isRecording = State(initialValue: viewModel.device.isRecording)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // カメラビュー（プレースホルダー）
            cameraPreviewPlaceholder

            // コントロール
            controlsSection

            // ステータス
            statusSection
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var cameraPreviewPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .aspectRatio(16/9, contentMode: .fit)

            if viewModel.device.isActive {
                VStack(spacing: 12) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("ライブプレビュー")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))

                    if isRecording {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)

                            Text("REC")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.red)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("カメラオフ")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var controlsSection: some View {
        HStack(spacing: 16) {
            // 電源
            VStack(spacing: 8) {
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

                Text("電源")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // 録画
            VStack(spacing: 8) {
                Button {
                    Task {
                        isRecording.toggle()
                        await viewModel.setRecording(isRecording)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.white.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: isRecording ? "stop.fill" : "record.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.device.isActive)

                Text(isRecording ? "録画停止" : "録画開始")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // スクリーンショット（プレースホルダー）
            VStack(spacing: 8) {
                Button {
                    // スクリーンショット機能（未実装）
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.device.isActive)

                Text("撮影")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ステータス")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 8) {
                StatusRow(
                    label: "接続状態",
                    value: viewModel.device.connectionStatus.displayName,
                    icon: viewModel.device.connectionStatus.iconName,
                    color: viewModel.device.isOnline ? .deviceOnline : .deviceOffline
                )

                StatusRow(
                    label: "動体検知",
                    value: viewModel.device.motionDetected ? "検知中" : "待機中",
                    icon: viewModel.device.motionDetected ? "figure.walk.motion" : "figure.stand",
                    color: viewModel.device.motionDetected ? .orange : .white.opacity(0.6)
                )

                StatusRow(
                    label: "録画",
                    value: isRecording ? "録画中" : "停止",
                    icon: isRecording ? "record.circle" : "stop.circle",
                    color: isRecording ? .red : .white.opacity(0.6)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - StatusRow

private struct StatusRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(color)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview("Camera Control") {
    VStack {
        Text("Camera Control Preview")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.asaDarkSlate)
}
