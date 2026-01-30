import SwiftUI
import AsaUIKit

// MARK: - ActivityFeedView

struct ActivityFeedView: View {
    // MARK: - Properties

    let activities: [Activity]

    // MARK: - Body

    var body: some View {
        ZStack {
            if activities.isEmpty {
                emptyStateView
            } else {
                activityList
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundStyle(AsaColors.coffeeBrown.opacity(0.3))

            Text("アクティビティはまだありません")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            Text("イベントでの活動がここに表示されます")
                .font(.subheadline)
                .foregroundStyle(AsaColors.mutedSage)
        }
    }

    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                    ActivityRow(
                        activity: activity,
                        isFirst: index == 0,
                        isLast: index == activities.count - 1
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - ActivityRow

struct ActivityRow: View {
    let activity: Activity
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // タイムライン
            VStack(spacing: 0) {
                // 上の線
                Rectangle()
                    .fill(isFirst ? Color.clear : AsaColors.mutedSage.opacity(0.3))
                    .frame(width: 2)
                    .frame(height: 16)

                // アイコン
                Circle()
                    .fill(activityColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: activity.type.icon)
                            .font(.caption)
                            .foregroundStyle(activityColor)
                    }

                // 下の線
                Rectangle()
                    .fill(isLast ? Color.clear : AsaColors.mutedSage.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }

            // コンテンツ
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    // ユーザーアバター
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 24, height: 24)
                        .overlay {
                            Text(activity.userName.prefix(1))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }

                    Text(activity.formattedMessage)
                        .font(.subheadline)
                        .foregroundStyle(AsaColors.darkSlate)

                    Spacer()

                    Text(activity.timeAgo)
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                }

                // マイルストーンの場合は追加メッセージ
                if activity.type == .milestone && !activity.message.isEmpty {
                    Text(activity.message)
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                        .padding(8)
                        .background(AsaColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var activityColor: Color {
        switch activity.type {
        case .joined: return .green
        case .left: return .gray
        case .posted: return .blue
        case .liked: return .pink
        case .commented: return .orange
        case .milestone: return .purple
        case .photoAdded: return .cyan
        case .settingChanged: return AsaColors.mutedSage
        }
    }

    private var avatarColor: Color {
        let colors: [Color] = [
            AsaColors.coffeeBrown,
            AsaColors.mocha,
            AsaColors.mutedSage,
            .purple,
            .orange,
            .cyan
        ]
        let index = abs(activity.userId.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Preview

#Preview {
    ActivityFeedView(activities: Activity.sampleActivities)
}
