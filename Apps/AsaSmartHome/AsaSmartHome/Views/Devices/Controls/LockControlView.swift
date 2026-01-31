import SwiftUI

// MARK: - LockControlView

/// スマートロックコントロールビュー
struct LockControlView: View {
    // MARK: - Properties

    @Bindable var viewModel: DeviceControlViewModel

    @State private var lockState: LockState
    @State private var autoLockEnabled: Bool
    @State private var showConfirmation = false

    // MARK: - Initialization

    init(viewModel: DeviceControlViewModel) {
        self.viewModel = viewModel
        self._lockState = State(initialValue: viewModel.device.lockState)
        self._autoLockEnabled = State(initialValue: viewModel.device.autoLockEnabled)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // ロック状態カード
            lockStatusCard

            // 自動ロック設定
            autoLockToggle

            // 操作履歴（プレースホルダー）
            historySection
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var lockStatusCard: some View {
        VStack(spacing: 20) {
            // ロックアイコン
            ZStack {
                Circle()
                    .fill(lockState.isSecure ? Color.deviceOnline.opacity(0.2) : Color.deviceOffline.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: lockState.iconName)
                    .font(.system(size: 44))
                    .foregroundStyle(lockState.isSecure ? Color.deviceOnline : Color.deviceOffline)
            }

            Text(lockState.displayName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            // ロック/解錠ボタン
            HStack(spacing: 16) {
                LockActionButton(
                    title: "解錠",
                    icon: "lock.open.fill",
                    isActive: !lockState.isSecure,
                    color: .deviceOffline
                ) {
                    showConfirmation = true
                }

                LockActionButton(
                    title: "施錠",
                    icon: "lock.fill",
                    isActive: lockState.isSecure,
                    color: .deviceOnline
                ) {
                    lockState = .locked
                    await viewModel.setLockState(.locked)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .confirmationDialog(
            "解錠しますか？",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("解錠する", role: .destructive) {
                Task {
                    lockState = .unlocked
                    await viewModel.setLockState(.unlocked)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("セキュリティのため、解錠操作には確認が必要です。")
        }
    }

    @ViewBuilder
    private var autoLockToggle: some View {
        Toggle(isOn: $autoLockEnabled) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Color.asaCoffeeBrown)

                VStack(alignment: .leading, spacing: 2) {
                    Text("自動ロック")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)

                    Text("解錠後、30秒で自動施錠")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .tint(Color.asaCoffeeBrown)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .onChange(of: autoLockEnabled) { _, newValue in
            Task {
                await viewModel.setAutoLock(newValue)
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近の操作")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 8) {
                HistoryRow(action: "施錠", time: "今日 8:30", icon: "lock.fill")
                HistoryRow(action: "解錠", time: "今日 8:25", icon: "lock.open.fill")
                HistoryRow(action: "施錠", time: "昨日 22:00", icon: "lock.fill")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - LockActionButton

private struct LockActionButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let color: Color
    let action: () async -> Void

    @State private var isLoading = false

    var body: some View {
        Button {
            guard !isActive else { return }
            isLoading = true
            Task {
                await action()
                isLoading = false
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                    Text(title)
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? color : Color.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isActive)
    }
}

// MARK: - HistoryRow

private struct HistoryRow: View {
    let action: String
    let time: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.asaCoffeeBrown)
                .frame(width: 24)

            Text(action)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()

            Text(time)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("Lock Control") {
    VStack {
        Text("Lock Control Preview")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.asaDarkSlate)
}
