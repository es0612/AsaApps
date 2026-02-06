import AsaSmartReminderKit
import AsaUIKit
import SwiftUI

// MARK: - 権限ステータス表示

struct PermissionStatusView: View {
    let permissionService: PermissionService

    var body: some View {
        VStack(spacing: 8) {
            statusRow(
                title: "位置情報",
                icon: "location.fill",
                isGranted: permissionService.permissionStatus.isLocationAuthorized,
                detail: locationDetail
            )
            statusRow(
                title: "通知",
                icon: "bell.fill",
                isGranted: permissionService.permissionStatus.isNotificationAuthorized,
                detail: notificationDetail
            )
        }
    }

    // MARK: - ステータス行

    private func statusRow(
        title: String,
        icon: String,
        isGranted: Bool,
        detail: String
    ) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isGranted ? .green : .red)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 詳細テキスト

    private var locationDetail: String {
        let status = permissionService.permissionStatus
        if status.isLocationAlways {
            return "常に許可"
        } else if status.isLocationAuthorized {
            return "使用中のみ"
        } else {
            return "未許可"
        }
    }

    private var notificationDetail: String {
        permissionService.permissionStatus.isNotificationAuthorized ? "許可済み" : "未許可"
    }
}
