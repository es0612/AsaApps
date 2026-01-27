//
//  ConnectionStatusView.swift
//  AsaLiveChat
//
//  接続状態表示コンポーネント
//

import SwiftUI
import AsaUIKit

/// WebSocket接続状態を表示するバナー
struct ConnectionStatusView: View {
    let state: ConnectionState
    let onRetry: (() -> Void)?

    init(state: ConnectionState, onRetry: (() -> Void)? = nil) {
        self.state = state
        self.onRetry = onRetry
    }

    var body: some View {
        if !state.isConnected {
            HStack(spacing: 8) {
                // アイコン
                if isAnimating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(foregroundColor)
                } else {
                    Image(systemName: state.iconName)
                        .font(.caption)
                        .foregroundColor(foregroundColor)
                }

                // テキスト
                Text(state.displayText)
                    .font(.caption)
                    .foregroundColor(foregroundColor)

                Spacer()

                // 再試行ボタン
                if showRetryButton, let onRetry = onRetry {
                    Button("再接続") {
                        onRetry()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(foregroundColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(foregroundColor.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private var backgroundColor: Color {
        switch state {
        case .disconnected:
            return AsaColors.mutedSage.opacity(0.2)
        case .connecting, .reconnecting:
            return AsaColors.coffeeBrown.opacity(0.2)
        case .connected:
            return Color.clear
        case .failed:
            return Color.red.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .disconnected:
            return AsaColors.mutedSage
        case .connecting, .reconnecting:
            return AsaColors.coffeeBrown
        case .connected:
            return AsaColors.coffeeBrown
        case .failed:
            return .red
        }
    }

    private var isAnimating: Bool {
        switch state {
        case .connecting, .reconnecting:
            return true
        default:
            return false
        }
    }

    private var showRetryButton: Bool {
        switch state {
        case .disconnected, .failed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Connection Status Badge

/// 接続状態を示すバッジ（コンパクト版）
struct ConnectionStatusBadge: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)

            if state.isConnected {
                Text("接続中")
                    .font(.caption2)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
    }

    private var badgeColor: Color {
        switch state {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected, .failed:
            return .red
        }
    }
}

// MARK: - Preview

#Preview("ConnectionStatusView") {
    VStack(spacing: 0) {
        ConnectionStatusView(state: .disconnected) {
            print("Retry tapped")
        }

        ConnectionStatusView(state: .connecting)

        ConnectionStatusView(state: .reconnecting(attempt: 2))

        ConnectionStatusView(state: .failed("サーバーに接続できません")) {
            print("Retry tapped")
        }

        Divider()
            .padding(.vertical)

        HStack(spacing: 16) {
            ConnectionStatusBadge(state: .connected)
            ConnectionStatusBadge(state: .connecting)
            ConnectionStatusBadge(state: .disconnected)
        }
    }
}
