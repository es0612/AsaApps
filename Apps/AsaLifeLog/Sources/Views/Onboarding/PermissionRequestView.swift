import SwiftUI

// MARK: - PermissionRequestView

/// 権限リクエストビュー
struct PermissionRequestView: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let onRequest: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("許可する", action: onRequest)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
