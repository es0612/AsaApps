//
//  ConnectionStatusView.swift
//  AsaMultiplayerGame
//
//  接続状態表示コンポーネント
//

import SwiftUI

struct ConnectionStatusView: View {
    let connectionState: ConnectionState

    var body: some View {
        HStack(spacing: 6) {
            // 接続状態アイコン
            Image(systemName: connectionState.iconName)
                .foregroundColor(iconColor)
                .font(.caption)

            // 接続状態テキスト
            Text(connectionState.displayText)
                .font(.caption2)
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .cornerRadius(12)
    }

    private var iconColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected, .failed:
            return .red
        }
    }

    private var textColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected, .failed:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch connectionState {
        case .connected:
            return .green.opacity(0.1)
        case .connecting, .reconnecting:
            return .orange.opacity(0.1)
        case .disconnected, .failed:
            return .red.opacity(0.1)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConnectionStatusView(connectionState: .connected)
        ConnectionStatusView(connectionState: .connecting)
        ConnectionStatusView(connectionState: .reconnecting(attempt: 2))
        ConnectionStatusView(connectionState: .disconnected)
        ConnectionStatusView(connectionState: .failed("タイムアウト"))
    }
    .padding()
}
