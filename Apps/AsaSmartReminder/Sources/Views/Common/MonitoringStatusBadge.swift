import AsaSmartReminderKit
import AsaUIKit
import SwiftUI

// MARK: - 監視ステータスバッジ

struct MonitoringStatusBadge: View {
    let state: MonitoringState

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(state.displayText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch state {
        case .idle: .gray
        case .starting: .orange
        case .monitoring: .green
        case .error: .red
        }
    }
}
