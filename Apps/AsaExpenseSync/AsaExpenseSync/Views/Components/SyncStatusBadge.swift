import SwiftUI
import AsaUIKit

// MARK: - SyncStatusBadge

struct SyncStatusBadge: View {
    let status: SyncStatus

    var body: some View {
        HStack(spacing: 6) {
            statusIcon

            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .foregroundColor(statusColor)
        .cornerRadius(16)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .synced:
            Image(systemName: status.iconName)

        case .syncing:
            ProgressView()
                .scaleEffect(0.7)
                .tint(statusColor)

        default:
            Image(systemName: status.iconName)
        }
    }

    private var statusColor: Color {
        switch status {
        case .synced:
            return .green
        case .syncing:
            return AsaColors.coffeeBrown
        case .pendingUpload, .pendingDownload:
            return .orange
        case .conflict, .error:
            return .red
        case .offline:
            return AsaColors.mutedSage
        }
    }
}

// MARK: - OfflineIndicator

struct OfflineIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption)

            Text("オフラインモード")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AsaColors.mutedSage.opacity(0.2))
        .foregroundColor(AsaColors.mutedSage)
        .cornerRadius(20)
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SyncStatusBadge(status: .synced)
        SyncStatusBadge(status: .syncing)
        SyncStatusBadge(status: .pendingUpload)
        SyncStatusBadge(status: .conflict)
        SyncStatusBadge(status: .offline)
        SyncStatusBadge(status: .error)

        Divider()

        OfflineIndicator()
    }
    .padding()
}
